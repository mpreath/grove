# Grove
A lightweight static site generator for the small web. Write in Markdown, publish to pure HTML and CSS — no JavaScript, no external resources, no tracking.

## Install

```bash
gem install grove-cli
```

## Quick start

```bash
grove create my-site
cd my-site
grove build
grove serve
```

Open `http://localhost:4000` to preview your site. Deploy the `output/` directory to any static host.

## Commands

| Command | Description |
|---|---|
| `grove create <name>` | Scaffold a new site |
| `grove build` | Build the site into `output/` |
| `grove build --fast` | Rebuild only changed files |
| `grove serve` | Build and serve locally at port 4000 |
| `grove new post "<Title>"` | Create a new draft post |
| `grove new page "<Title>"` | Create a new page |
| `grove new gallery "<Title>"` | Create a new image gallery |

## Site structure

```text
my-site/
├── config.toml        # Site settings and navigation
├── content/
│   ├── posts/         # Blog posts (YYYY-MM-DD-slug.md)
│   ├── pages/         # Standalone pages (slug.md)
│   ├── galleries/     # Image galleries (slug.md)
│   └── assets/        # Images and static files
├── templates/         # ERB layout templates (customizable)
├── static/            # Files copied as-is to output (style.css)
└── output/            # Generated site — deploy this
```

## Content format

Posts and pages use TOML front matter:

```toml
+++
title = "Hello, World"
date  = 2026-01-15
tags  = ["general", "meta"]
draft = false
+++

Your Markdown content goes here.
```

Set `draft = true` to exclude a file from the build.

## Galleries

A gallery is a markdown file in `content/galleries/` paired with a folder of
images under `content/assets/`. Every image in the folder appears on the page,
sorted by filename — adding a photo means dropping a file in and rebuilding.

```text
content/galleries/photography.md            → /galleries/photography/
content/assets/galleries/photography/*.jpg  → /galleries/photography/*.jpg
```

```toml
+++
title  = "Photography"
date   = 2026-08-01              # optional, orders the gallery index
source = "galleries/photography" # optional, defaults to galleries/<slug>
cover  = "sunset.jpg"            # optional, defaults to the first image

[[images]]
file    = "sunset.jpg"
caption = "Golden hour, Outer Banks"
alt     = "Sun setting behind dunes"
+++

An optional Markdown intro, rendered above the grid.
```

`[[images]]` blocks are entirely optional. Files named there come first, in the
order listed; everything else follows alphabetically. Without a block, alt text
is derived from the filename. Recognized extensions are `.jpg`, `.jpeg`,
`.png`, `.gif`, `.webp`, and `.avif`.

Galleries with two or more entries also get an index page at `/galleries/`,
listing each one by its cover image. Add it to your `[[nav]]` to link it.

Clicking an image opens it full-size in a CSS-only lightbox — no JavaScript.
Grove does no image processing, so images are served at their original size;
resize them before adding them if file size matters.

## Configuration

`config.toml` controls site-wide settings:

```toml
site_title  = "Your Name"
base_url    = "https://yourname.net"
author      = "Your Name"
description = "On technology, and other things."
footer      = "© 2026 Your Name"

[[nav]]
label = "Home"
url   = "/"

[[nav]]
label = "About"
url   = "/about/"
```

## Customization

Templates live in `templates/` and use Ruby's ERB syntax. The stylesheet is `static/style.css` — edit it directly. No build tools or preprocessors required.

## Hosting

The `output/` directory is a self-contained static site. Deploy it anywhere:

- **GitHub Pages** — push `output/` to a `gh-pages` branch
- **Netlify / Cloudflare Pages** — connect your repo, set build command to `grove build` and publish directory to `output`
- **VPS with nginx** — copy `output/` to your web root
- **Neocities** — drag and drop

## License

MIT
