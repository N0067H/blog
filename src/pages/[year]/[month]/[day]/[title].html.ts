import type { APIRoute } from "astro";
import { getCollection } from "astro:content";
import { getSortedPosts } from "@/utils/getSortedPosts";
import { getLegacyPostUrl } from "@/utils/getLegacyPostUrl";
import { getPostUrl } from "@/utils/getPostPaths";
import { redirectResponse } from "@/utils/redirectResponse";

export async function getStaticPaths() {
  return getSortedPosts(await getCollection("posts")).map(post => {
    const [, year, month, day, title] = getLegacyPostUrl(post).split("/");
    return {
      params: { year, month, day, title: title.replace(/\.html$/, "") },
      props: { target: getPostUrl(post.id, post.filePath) },
    };
  });
}

export const GET: APIRoute = ({ props }) => redirectResponse(props.target);
