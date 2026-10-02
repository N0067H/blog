import type { CollectionEntry } from "astro:content";

/** Jekyll used the filename date and preserved the title's casing in URLs. */
export function getLegacyPostUrl(post: CollectionEntry<"posts">): string {
  const filename = post.filePath?.split("/").pop() ?? "";
  const match = filename.match(/^(\d{4})-(\d{2})-(\d{2})-(.+)\.(?:md|mdx)$/);
  if (!match) throw new Error(`Expected a dated post filename: ${filename}`);
  return `/${match[1]}/${match[2]}/${match[3]}/${match[4]}.html`;
}
