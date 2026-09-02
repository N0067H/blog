#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "webrick"
require "date"
require "pathname"
require "cgi"
require "thread"

ROOT = Pathname.new(__dir__).expand_path
POSTS_DIR = ROOT.join("_posts")
DRAFTS_DIR = ROOT.join("_drafts")
IDLE_TIMEOUT_SECONDS = Integer(ENV.fetch("IDLE_TIMEOUT_SECONDS", (30 * 60).to_s))
$activity_lock = Mutex.new
$last_activity_at = Time.now

def touch_activity!
  $activity_lock.synchronize do
    $last_activity_at = Time.now
  end
end

def last_activity_at
  $activity_lock.synchronize { $last_activity_at }
end

def json_response(res, status:, body:)
  res.status = status
  res["Content-Type"] = "application/json; charset=utf-8"
  res.body = JSON.pretty_generate(body)
end

def read_document(pathname)
  raw = pathname.read
  front_matter = {}
  body = raw

  if raw.start_with?("---\n")
    parts = raw.split(/^---\s*$\n?/, 3)
    if parts.length >= 3
      front_matter = YAML.safe_load(parts[1], permitted_classes: [Date, Time], aliases: true) || {}
      body = parts[2]
    end
  end

  {
    metadata: front_matter.transform_keys(&:to_s),
    content: body.sub(/\A\n/, "")
  }
end

def document_listing
  [POSTS_DIR, DRAFTS_DIR].flat_map do |dir|
    draft = dir == DRAFTS_DIR
    dir.children.select(&:file?).sort_by(&:basename).reverse.map do |path|
      doc = read_document(path)
      metadata = doc[:metadata]
      {
        path: path.relative_path_from(ROOT).to_s,
        title: metadata["title"] || path.basename(".md").to_s,
        date: metadata["date"]&.to_s,
        excerpt: metadata["excerpt"].to_s,
        tags: metadata["tags"],
        draft: draft
      }
    end
  end.sort_by { |item| [item[:date].to_s, item[:path]] }.reverse
end

def slugify(value)
  slug = value.to_s.downcase.strip
  slug = slug.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
  slug.empty? ? "untitled" : slug
end

def normalize_tags(tags)
  case tags
  when Array
    tags.map(&:to_s).map(&:strip).reject(&:empty?)
  else
    tags.to_s.split(",").map(&:strip).reject(&:empty?)
  end
end

def build_target_path(draft:, date:, slug:)
  date_string = Date.parse(date.to_s).strftime("%Y-%m-%d")
  filename = "#{date_string}-#{slug}.md"
  (draft ? DRAFTS_DIR : POSTS_DIR).join(filename)
end

def parse_request_body(req)
  JSON.parse(req.body || "{}", symbolize_names: true)
rescue JSON::ParserError
  nil
end

def sanitize_relative_path(raw_path)
  return nil if raw_path.to_s.empty?

  expanded = ROOT.join(raw_path).expand_path
  return nil unless expanded.to_s.start_with?(ROOT.to_s)

  expanded
end

class ApiServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    touch_activity!
    case req.path
    when "/api/posts"
      json_response(res, status: 200, body: { items: document_listing })
    when "/api/post"
      handle_get_post(req, res)
    when "/api/status"
      json_response(
        res,
        status: 200,
        body: {
          ok: true,
          idle_timeout_seconds: IDLE_TIMEOUT_SECONDS,
          last_activity_at: last_activity_at.iso8601
        }
      )
    else
      json_response(res, status: 404, body: { error: "Not found" })
    end
  rescue StandardError => e
    json_response(res, status: 500, body: { error: e.message })
  end

  def do_POST(req, res)
    touch_activity!
    case req.path
    when "/api/save"
      handle_save(req, res)
    when "/api/shutdown"
      json_response(res, status: 200, body: { ok: true, message: "Shutting down" })
      Thread.new { sleep 0.1; @server.shutdown }
    else
      json_response(res, status: 404, body: { error: "Not found" })
    end
  rescue ArgumentError => e
    json_response(res, status: 400, body: { error: e.message })
  rescue StandardError => e
    json_response(res, status: 500, body: { error: e.message })
  end

  def initialize(server)
    super
    @server = server
  end

  private

  def handle_save(req, res)
    payload = parse_request_body(req)
    return json_response(res, status: 400, body: { error: "Invalid JSON body" }) unless payload

    title = payload[:title].to_s.strip
    date = payload[:date].to_s.strip
    draft = payload[:draft] == true
    content = payload[:content].to_s
    excerpt = payload[:excerpt].to_s.strip
    slug = slugify(payload[:slug].to_s.strip.empty? ? title : payload[:slug])
    extra_metadata = payload[:extra_metadata].is_a?(Hash) ? payload[:extra_metadata] : {}
    tags = normalize_tags(payload[:tags])

    if title.empty? || date.empty?
      return json_response(res, status: 400, body: { error: "Title and date are required" })
    end

    target_path = build_target_path(draft: draft, date: date, slug: slug)
    original_path = sanitize_relative_path(payload[:original_path])

    if target_path.exist? && target_path != original_path
      return json_response(res, status: 409, body: { error: "A file with the same date and slug already exists" })
    end

    metadata = extra_metadata.transform_keys(&:to_s)
    metadata["title"] = title
    metadata["date"] = Date.parse(date).strftime("%Y-%m-%d")
    metadata["excerpt"] = excerpt unless excerpt.empty?
    metadata.delete("excerpt") if excerpt.empty?
    metadata["tags"] = tags.length <= 1 ? tags.first.to_s : tags
    metadata.delete("tags") if tags.empty?

    yaml = metadata.to_yaml(line_width: -1).sub(/\A---\s*\n/, "")
    target_path.write("---\n#{yaml}---\n\n#{content}")
    original_path.delete if original_path && original_path != target_path && original_path.exist?

    json_response(
      res,
      status: 200,
      body: {
        ok: true,
        path: target_path.relative_path_from(ROOT).to_s,
        draft: draft
      }
    )
  end

  def handle_get_post(req, res)
    raw_path = CGI.unescape(req.query["path"].to_s)
    pathname = sanitize_relative_path(raw_path)
    return json_response(res, status: 400, body: { error: "Invalid path" }) unless pathname&.file?

    document = read_document(pathname)
    metadata = document[:metadata]

    json_response(
      res,
      status: 200,
      body: {
        path: pathname.relative_path_from(ROOT).to_s,
        draft: pathname.to_s.start_with?(DRAFTS_DIR.to_s),
        metadata: metadata,
        content: document[:content]
      }
    )
  end
end

class TrackingFileServlet < WEBrick::HTTPServlet::FileHandler
  def do_GET(req, res)
    touch_activity!
    super
  end

  def do_HEAD(req, res)
    touch_activity!
    super
  end
end

port = Integer(ENV.fetch("PORT", "4001"))

server = WEBrick::HTTPServer.new(
  Port: port,
  DocumentRoot: ROOT.to_s,
  AccessLog: [],
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN)
)

server.mount("/api", ApiServlet)
server.mount("/api/posts", ApiServlet)
server.mount("/api/post", ApiServlet)
server.mount("/api/status", ApiServlet)
server.mount("/api/save", ApiServlet)
server.mount("/", TrackingFileServlet, ROOT.to_s)

Thread.new do
  poll_interval = [[IDLE_TIMEOUT_SECONDS / 2, 1].max, 30].min
  loop do
    sleep poll_interval
    idle_seconds = Time.now - last_activity_at
    next unless idle_seconds >= IDLE_TIMEOUT_SECONDS

    warn "Idle timeout reached after #{idle_seconds.to_i}s. Shutting down."
    server.shutdown
    break
  end
end

trap("INT") { server.shutdown }
trap("TERM") { server.shutdown }

puts "Admin panel server running at http://127.0.0.1:#{port}/admin.html"
puts "Idle timeout: #{IDLE_TIMEOUT_SECONDS}s"
server.start
