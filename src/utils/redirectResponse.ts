import config from "@/config";

export function redirectResponse(target: string): Response {
  const escape = (value: string) =>
    value
      .replaceAll("&", "&amp;")
      .replaceAll('"', "&quot;")
      .replaceAll("<", "&lt;");
  const url = escape(target);
  const canonical = escape(new URL(target, config.site.url).href);
  return new Response(
    `<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=${url}"><link rel="canonical" href="${canonical}"><meta name="robots" content="noindex"><title>주소가 변경되었습니다</title></head><body><a href="${url}">새 주소로 이동</a></body></html>`,
    {
      headers: { "Content-Type": "text/html; charset=utf-8" },
    }
  );
}
