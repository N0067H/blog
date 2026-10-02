# SeungYeop Ryu의 기술 블로그

[AstroPaper v6.0.0](https://github.com/satnaing/astro-paper/releases/tag/v6.0.0) 기반의 Astro 정적 블로그입니다. 사이트는 https://blog.noobth.dev 에서 운영합니다.

템플릿 의존성의 보안 수정과 호환성을 위해 Astro 7, MDX 8, Sharp 0.35를 사용합니다. 글의 공유 미리보기는 사이트 공통 `/og.png`를 사용하며, 개별 이미지는 front matter의 `ogImage`로 지정할 수 있습니다.

## 로컬 실행

Node.js 24와 npm을 사용합니다.

```sh
npm ci
npm run dev
```

http://localhost:4321 에서 확인할 수 있습니다.

```sh
npm run build
npm run preview
```

빌드에는 타입 검사, 정적 페이지 생성, 한국어 Pagefind 검색 인덱스 생성이 포함됩니다. 개발 서버에서도 검색하려면 빌드 후 `npm run build:search`를 실행하세요. 폰트는 첫 빌드 시 Google Fonts에서 내려받아 사이트에서 제공합니다.

## 글 작성

기존 파일 구조와 front matter를 유지합니다. 공개 글은 `_posts/YYYY-MM-DD-slug.md`, 초안은 `_drafts/`에 저장합니다. `_drafts/`는 Astro 콘텐츠 컬렉션에 포함되지 않으며 배포하지 않습니다.

```yaml
---
title: "글 제목"
date: 2026-10-02
excerpt: "글을 설명하는 짧은 문장"
tags: [rust, backend]
---
```

`date`는 한국 시간 자정으로 해석합니다. `pubDatetime`, `description` 등 AstroPaper front matter도 사용할 수 있습니다. 예약 글은 빌드 시점에 발행 시간이 지난 경우에만 공개되므로 해당 시간 이후 다시 빌드해야 합니다. `draft: true`도 공개 대상에서 제외합니다.

기존 `./admin run` 명령과 http://127.0.0.1:4001/admin.html 관리자 도구를 계속 사용할 수 있습니다. 관리자 도구만 Ruby와 WEBrick이 필요합니다 (`bundle install`). 관리자에서 초안 체크를 해제하고 저장하면 `_posts/`로 이동되어 공개됩니다.

새 글 주소는 `/posts/slug`입니다. 기존 `/YYYY/MM/DD/Title.html`, `/about.html`, `/archive.html`에는 정적 리다이렉트를 제공합니다. 기존 RSS 구독을 위해 `/feed.xml`에도 RSS를 제공합니다. Disqus는 이전 글 URL과 `key` 식별자를 계속 사용합니다.

## 설정과 배포

- 사이트·작성자·연락처·테마 기능: `astro-paper.config.ts`
- 소개: `src/content/pages/about.md`
- 한국어 UI: `src/i18n/lang/ko.ts`
- Google Analytics: `src/layouts/Layout.astro`
- Disqus: `src/components/Comments.astro`
- 커스텀 도메인: `public/CNAME`

`main`에 푸시하면 GitHub Actions가 `npm ci`와 `npm run build`를 실행하고 `dist/`를 GitHub Pages에 배포합니다. GitHub 저장소 Settings → Pages의 Source는 **GitHub Actions**를 사용하세요.

AstroPaper 코드의 MIT 라이선스는 `LICENSE`에 보존했습니다. 블로그 글은 기존 CC BY-SA 4.0 라이선스를 유지합니다.
