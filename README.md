# Grove

<table border=0>
  <tr><td></td><td>A lightweight static site generator for the small web. Write in Markdown, publish to pure HTML and CSS — no JavaScript, no external resources, no tracking.
</td></tr>

## Install

```bash<img width="3712" height="5149" alt="clipart35421" src="https://github.com/user-attachments/assets/ab17dffe-732e-4fe8-92af-f1e5aca01092" />

gem install grove
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

## Site structure

```
my-site/
├── config.toml        # Site settings and navigation
├── content/
│   ├── posts/         # Blog posts (YYYY-MM-DD-slug.md)
│   ├── pages/         # Standalone pages (slug.md)
│   └── assets/        # Images and static files
├── templates/         # ERB layout templates (customizable)
├── static/            # Files copied as-is to output (style.css)
└── output/            # Generated site — deploy this
```

## Content format

Posts and pages use TOML front matter:

```
+++
title = "Hello, World"
date  = 2026-01-15
tags  = ["general", "meta"]
draft = false
+++

Your Markdown content goes here.
```

Set `draft = true` to exclude a file from the build.

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
