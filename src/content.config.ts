import { defineCollection } from "astro:content";
import { z } from "astro/zod";
import { glob } from "astro/loaders";
import config from "@/config";
import { slugifyStr } from "@/utils/slugify";

// Keep the existing files and local admin's date/excerpt front matter intact.
// _drafts is outside this collection and never shipped publicly.
export const BLOG_PATH = "_posts";

const posts = defineCollection({
  loader: glob({
    pattern: "**/[^_]*.{md,mdx}",
    base: `./${BLOG_PATH}`,
    generateId: ({ entry }) =>
      slugifyStr(
        entry.replace(/\.(md|mdx)$/, "").replace(/^\d{4}-\d{2}-\d{2}-/, "")
      ),
  }),
  schema: ({ image }) =>
    z
      .object({
        author: z.string().default(config.site.author),
        date: z.union([z.date(), z.string()]).optional(),
        pubDatetime: z.coerce.date().optional(),
        modDatetime: z.coerce.date().optional().nullable(),
        title: z.string(),
        key: z.string().optional(),
        featured: z.boolean().optional(),
        draft: z.boolean().optional(),
        tags: z
          .union([z.array(z.string()), z.string()])
          .default([])
          .transform(tags =>
            typeof tags === "string"
              ? tags.split(/[\s,]+/).filter(Boolean)
              : tags
          ),
        ogImage: image().or(z.string()).default("/og.png"),
        excerpt: z.string().optional(),
        description: z.string().optional(),
        canonicalURL: z.string().optional(),
        hideEditPost: z.boolean().optional(),
        timezone: z.string().optional(),
      })
      .transform((data, ctx) => {
        const rawDate =
          data.date instanceof Date
            ? data.date.toISOString().slice(0, 10)
            : data.date;
        const pubDatetime =
          data.pubDatetime ??
          (rawDate
            ? new Date(
                /^\d{4}-\d{2}-\d{2}$/.test(rawDate)
                  ? `${rawDate}T00:00:00+09:00`
                  : rawDate
              )
            : undefined);
        if (!pubDatetime || Number.isNaN(pubDatetime.getTime())) {
          ctx.addIssue({
            code: "custom",
            message: "A valid date or pubDatetime is required",
          });
          return z.NEVER;
        }
        return {
          ...data,
          pubDatetime,
          description: data.description ?? data.excerpt ?? data.title,
        };
      }),
});

const pages = defineCollection({
  loader: glob({ pattern: "**/[^_]*.{md,mdx}", base: "./src/content/pages" }),
  schema: z.object({
    title: z.string(),
    description: z.string().optional(),
    ogImage: z.string().optional(),
    canonicalURL: z.string().optional(),
  }),
});

export const collections = { posts, pages };
