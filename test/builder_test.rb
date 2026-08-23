# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"
require "date"

class BuilderTest < Minitest::Test
  GEM_ROOT = File.expand_path("..", __dir__)

  def setup
    @dir = Dir.mktmpdir
    setup_site(@dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # ---------------------------------------------------------------------------
  # Output directory
  # ---------------------------------------------------------------------------

  def test_build_creates_output_directory
    Grove::Builder.new(@dir).build
    assert Dir.exist?(output(""))
  end

  # ---------------------------------------------------------------------------
  # Homepage
  # ---------------------------------------------------------------------------

  def test_build_creates_index_html
    Grove::Builder.new(@dir).build
    assert_file "index.html"
  end

  def test_index_html_contains_post_title
    Grove::Builder.new(@dir).build
    assert_includes read_output("index.html"), "Hello, World"
  end

  def test_index_html_contains_site_title
    Grove::Builder.new(@dir).build
    assert_includes read_output("index.html"), "Test Site"
  end

  def test_index_html_does_not_list_draft_posts
    Grove::Builder.new(@dir).build
    refute_includes read_output("index.html"), "Draft Post"
  end

  # ---------------------------------------------------------------------------
  # Posts
  # ---------------------------------------------------------------------------

  def test_build_creates_post_directory
    Grove::Builder.new(@dir).build
    assert Dir.exist?(output("posts/hello-world"))
  end

  def test_build_creates_post_index_html
    Grove::Builder.new(@dir).build
    assert_file "posts/hello-world/index.html"
  end

  def test_post_contains_title
    Grove::Builder.new(@dir).build
    assert_includes read_output("posts/hello-world/index.html"), "Hello, World"
  end

  def test_post_contains_body_html
    Grove::Builder.new(@dir).build
    assert_includes read_output("posts/hello-world/index.html"), "This is the body"
  end

  def test_post_contains_formatted_date
    Grove::Builder.new(@dir).build
    content = read_output("posts/hello-world/index.html")
    # Date should appear in some human-readable form
    assert_match(/January|2024/, content)
  end

  def test_post_contains_tag_link
    Grove::Builder.new(@dir).build
    assert_includes read_output("posts/hello-world/index.html"), "tags/ruby"
  end

  def test_draft_post_is_not_built
    Grove::Builder.new(@dir).build
    refute File.exist?(output("posts/draft-post/index.html")),
           "Draft post should not be written to output"
  end

  # ---------------------------------------------------------------------------
  # Pages
  # ---------------------------------------------------------------------------

  def test_build_creates_page_index_html
    Grove::Builder.new(@dir).build
    assert_file "about/index.html"
  end

  def test_page_contains_title
    Grove::Builder.new(@dir).build
    assert_includes read_output("about/index.html"), "About"
  end

  def test_page_contains_body_html
    Grove::Builder.new(@dir).build
    assert_includes read_output("about/index.html"), "This is the about page"
  end

  # ---------------------------------------------------------------------------
  # Tag pages
  # ---------------------------------------------------------------------------

  def test_build_creates_tag_directory
    Grove::Builder.new(@dir).build
    assert Dir.exist?(output("tags/ruby"))
  end

  def test_build_creates_tag_index_html
    Grove::Builder.new(@dir).build
    assert_file "tags/ruby/index.html"
  end

  def test_tag_page_lists_tagged_post
    Grove::Builder.new(@dir).build
    assert_includes read_output("tags/ruby/index.html"), "Hello, World"
  end

  def test_tag_page_does_not_list_untagged_post
    Grove::Builder.new(@dir).build
    # The "meta" tag page should not include the ruby-only post
    write_post("2024-01-20-meta-only.md", "Meta Only", tags: ["meta"])
    Grove::Builder.new(@dir).build
    refute_includes read_output("tags/meta/index.html"), "Hello, World"
  end

  def test_tag_slugs_are_url_safe
    write_post("2024-01-20-special-tag.md", "Special Tag Post", tags: ["C++"])
    Grove::Builder.new(@dir).build
    # "C++" should become "c" after slugification
    assert_file "tags/c/index.html"
  end

  # ---------------------------------------------------------------------------
  # 404 page
  # ---------------------------------------------------------------------------

  def test_build_creates_404_html
    Grove::Builder.new(@dir).build
    assert_file "404.html"
  end

  def test_404_page_contains_not_found_heading
    Grove::Builder.new(@dir).build
    assert_includes read_output("404.html"), "Page Not Found"
  end

  def test_404_page_contains_home_link
    Grove::Builder.new(@dir).build
    assert_includes read_output("404.html"), "Back to home"
  end

  # ---------------------------------------------------------------------------
  # Sitemap
  # ---------------------------------------------------------------------------

  def test_build_creates_sitemap_xml
    Grove::Builder.new(@dir).build
    assert_file "sitemap.xml"
  end

  def test_sitemap_is_valid_xml
    Grove::Builder.new(@dir).build
    content = read_output("sitemap.xml")
    assert_includes content, '<?xml version="1.0"'
    assert_includes content, "<urlset"
    assert_includes content, "</urlset>"
  end

  def test_sitemap_contains_post_url
    Grove::Builder.new(@dir).build
    assert_includes read_output("sitemap.xml"), "/posts/hello-world/"
  end

  def test_sitemap_contains_page_url
    Grove::Builder.new(@dir).build
    assert_includes read_output("sitemap.xml"), "/about/"
  end

  def test_sitemap_contains_homepage_url
    Grove::Builder.new(@dir).build
    # Homepage should appear as base_url + "/"
    assert_match(%r{<loc>https://example\.com/</loc>}, read_output("sitemap.xml"))
  end

  def test_sitemap_contains_post_lastmod
    Grove::Builder.new(@dir).build
    assert_includes read_output("sitemap.xml"), "<lastmod>2024-01-15</lastmod>"
  end

  def test_sitemap_excludes_draft_posts
    Grove::Builder.new(@dir).build
    refute_includes read_output("sitemap.xml"), "draft-post"
  end

  # ---------------------------------------------------------------------------
  # RSS feed
  # ---------------------------------------------------------------------------

  def test_build_creates_feed_xml
    Grove::Builder.new(@dir).build
    assert_file "feed.xml"
  end

  def test_feed_is_valid_rss
    Grove::Builder.new(@dir).build
    content = read_output("feed.xml")
    assert_includes content, '<?xml version="1.0"'
    assert_includes content, '<rss version="2.0"'
    assert_includes content, "</rss>"
  end

  def test_feed_contains_site_title
    Grove::Builder.new(@dir).build
    assert_includes read_output("feed.xml"), "Test Site"
  end

  def test_feed_contains_post_entry
    Grove::Builder.new(@dir).build
    assert_includes read_output("feed.xml"), "Hello, World"
  end

  def test_feed_excludes_drafts
    Grove::Builder.new(@dir).build
    refute_includes read_output("feed.xml"), "Draft Post"
  end

  # ---------------------------------------------------------------------------
  # Static assets
  # ---------------------------------------------------------------------------

  def test_build_copies_static_css
    Grove::Builder.new(@dir).build
    assert_file "style.css"
  end

  def test_build_copies_content_assets
    # Place a file in content/assets/ and verify it lands in output/
    asset_src = File.join(@dir, "content", "assets", "photo.jpg")
    File.write(asset_src, "fake jpeg data")
    Grove::Builder.new(@dir).build
    assert_file "photo.jpg"
  end

  # ---------------------------------------------------------------------------
  # Fast (incremental) build
  # ---------------------------------------------------------------------------

  def test_fast_build_skips_up_to_date_post
    Grove::Builder.new(@dir).build
    post_output = output("posts/hello-world/index.html")
    mtime_before = File.mtime(post_output)

    # Ensure at least 1 second passes so an mtime change would be detectable
    sleep 1 if ENV["CI"]

    Grove::Builder.new(@dir).build(fast: true)
    assert_equal mtime_before, File.mtime(post_output),
                 "Fast build should not rewrite an up-to-date file"
  end

  def test_fast_build_rebuilds_changed_post
    Grove::Builder.new(@dir).build
    post_src    = File.join(@dir, "content", "posts", "2024-01-15-hello-world.md")
    post_output = output("posts/hello-world/index.html")

    # Rewrite source with new content and a future mtime so the fast build
    # considers it changed relative to the already-written output file.
    updated_md = <<~MD
      +++
      title = "Hello, World"
      date  = 2024-01-15
      tags  = ["ruby"]
      draft = false
      +++

      This is the UPDATED body content.
    MD
    File.write(post_src, updated_md)
    future = Time.now + 60
    File.utime(future, future, post_src)

    Grove::Builder.new(@dir).build(fast: true)

    assert_includes File.read(post_output), "UPDATED body content",
                    "Fast build should have rebuilt the changed post with new content"
  end

  # ---------------------------------------------------------------------------
  # Error handling
  # ---------------------------------------------------------------------------

  def test_build_aborts_without_config_toml
    FileUtils.rm(File.join(@dir, "config.toml"))
    assert_raises(SystemExit) { Grove::Builder.new(@dir).build }
  end

  def test_build_succeeds_with_no_posts
    FileUtils.rm_rf(File.join(@dir, "content", "posts"))
    Grove::Builder.new(@dir).build   # must not raise
    assert_file "index.html"
  end

  def test_build_succeeds_with_no_pages
    FileUtils.rm_rf(File.join(@dir, "content", "pages"))
    Grove::Builder.new(@dir).build   # must not raise
    assert_file "index.html"
  end

  # ---------------------------------------------------------------------------
  # HTML structure (base layout)
  # ---------------------------------------------------------------------------

  def test_output_pages_include_nav_links
    Grove::Builder.new(@dir).build
    assert_includes read_output("index.html"), "Home"
  end

  def test_output_pages_include_footer
    Grove::Builder.new(@dir).build
    assert_includes read_output("index.html"), "Test Footer"
  end

  def test_output_pages_link_to_stylesheet
    Grove::Builder.new(@dir).build
    assert_includes read_output("index.html"), "style.css"
  end

  def test_output_pages_link_to_rss_feed
    Grove::Builder.new(@dir).build
    assert_includes read_output("index.html"), "feed.xml"
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # Galleries
  # ---------------------------------------------------------------------------

  def test_build_renders_gallery_page
    Grove::Builder.new(@dir).build
    assert_file "galleries/photography/index.html"
  end

  def test_gallery_page_includes_images_and_lightbox_anchors
    Grove::Builder.new(@dir).build
    html = read_output("galleries/photography/index.html")
    assert_includes html, "galleries/photography/sunset.jpg"
    assert_includes html, "galleries/photography/pier.jpg"
    assert_includes html, %(href="#photography-1")
    assert_includes html, %(class="lightbox" id="photography-1")
  end

  def test_gallery_page_uses_page_title_and_renders_body
    Grove::Builder.new(@dir).build
    html = read_output("galleries/photography/index.html")
    assert_includes html, "<title>Photography — Test Site</title>"
    assert_includes html, "Photos from the coast."
  end

  def test_gallery_listed_images_come_first_with_captions
    Grove::Builder.new(@dir).build
    html = read_output("galleries/photography/index.html")
    assert_includes html, "Golden hour"
    assert_operator html.index("sunset.jpg"), :<, html.index("pier.jpg")
  end

  def test_build_copies_gallery_images_alongside_the_page
    Grove::Builder.new(@dir).build
    assert_file "galleries/photography/sunset.jpg"
    assert_file "galleries/photography/pier.jpg"
  end

  def test_build_renders_gallery_index
    Grove::Builder.new(@dir).build
    html = read_output("galleries/index.html")
    assert_includes html, "galleries/photography/"
    assert_includes html, "Photography"
  end

  def test_gallery_index_uses_first_image_as_cover
    Grove::Builder.new(@dir).build
    assert_includes read_output("galleries/index.html"), "galleries/photography/sunset.jpg"
  end

  def test_draft_gallery_is_excluded
    Grove::Builder.new(@dir).build
    refute File.exist?(output("galleries/draft-gallery/index.html"))
    refute_includes read_output("galleries/index.html"), "Draft Gallery"
    refute_includes read_output("sitemap.xml"), "draft-gallery"
  end

  def test_gallery_with_no_images_still_builds
    write_gallery("sketches", "Sketches")
    capture_io { Grove::Builder.new(@dir).build }
    html = read_output("galleries/sketches/index.html")
    assert_includes html, "No images yet"
  end

  def test_no_gallery_index_when_there_are_no_galleries
    FileUtils.rm_rf(File.join(@dir, "content", "galleries"))
    Grove::Builder.new(@dir).build
    refute File.exist?(output("galleries/index.html"))
  end

  def test_gallery_added_image_appears_on_rebuild_even_with_fast
    builder = Grove::Builder.new(@dir)
    builder.build
    refute_includes read_output("galleries/photography/index.html"), "newphoto.jpg"

    File.write(File.join(@dir, "content", "assets", "galleries", "photography", "newphoto.jpg"), "")
    builder.build(fast: true)
    assert_includes read_output("galleries/photography/index.html"), "newphoto.jpg"
  end

  def test_sitemap_includes_gallery_urls
    Grove::Builder.new(@dir).build
    sitemap = read_output("sitemap.xml")
    assert_includes sitemap, "<loc>https://example.com/galleries/</loc>"
    assert_includes sitemap, "<loc>https://example.com/galleries/photography/</loc>"
    assert_includes sitemap, "<lastmod>2024-02-01</lastmod>"
  end

  def test_rss_excludes_galleries
    Grove::Builder.new(@dir).build
    refute_includes read_output("feed.xml"), "Photography"
  end

  private

  def output(rel)
    File.join(@dir, "output", rel)
  end

  def assert_file(rel)
    assert File.exist?(output(rel)), "Expected output file to exist: #{rel}"
  end

  def read_output(rel)
    File.read(output(rel))
  end

  # Creates a gallery md plus its image folder, returning the assets dir.
  def write_gallery(slug, title, images: [], extra: nil)
    FileUtils.mkdir_p(File.join(@dir, "content", "galleries"))
    assets = File.join(@dir, "content", "assets", "galleries", slug)
    FileUtils.mkdir_p(assets)
    images.each { |name| File.write(File.join(assets, name), "") }

    File.write(File.join(@dir, "content", "galleries", "#{slug}.md"), <<~MD)
      +++
      title = "#{title}"
      #{extra}+++

    MD
    assets
  end

  def write_post(filename, title, tags: [], draft: false)
    path = File.join(@dir, "content", "posts", filename)
    File.write(path, <<~MD)
      +++
      title = "#{title}"
      date  = 2024-01-20
      tags  = #{tags.inspect}
      draft = #{draft}
      +++

      Content for #{title}.
    MD
  end

  def setup_site(dir)
    # ── Directories ──────────────────────────────────────────────────────────
    %w[content/posts content/pages content/galleries content/assets templates static output].each do |d|
      FileUtils.mkdir_p(File.join(dir, d))
    end

    # ── config.toml ──────────────────────────────────────────────────────────
    File.write(File.join(dir, "config.toml"), <<~TOML)
      site_title  = "Test Site"
      base_url    = "https://example.com"
      author      = "Tester"
      description = "A test site."
      footer      = "Test Footer"

      [[nav]]
      label = "Home"
      url   = "/"

      [[nav]]
      label = "About"
      url   = "/about/"
    TOML

    # ── Copy bundled templates and stylesheet ─────────────────────────────────
    FileUtils.cp_r(File.join(GEM_ROOT, "templates", "."), File.join(dir, "templates"))
    FileUtils.cp_r(File.join(GEM_ROOT, "static",    "."), File.join(dir, "static"))

    # ── Sample published post ─────────────────────────────────────────────────
    File.write(File.join(dir, "content", "posts", "2024-01-15-hello-world.md"), <<~MD)
      +++
      title = "Hello, World"
      date  = 2024-01-15
      tags  = ["ruby"]
      draft = false
      +++

      This is the body of the hello world post.
    MD

    # ── Sample draft post (must be excluded from all output) ─────────────────
    File.write(File.join(dir, "content", "posts", "2024-01-16-draft-post.md"), <<~MD)
      +++
      title = "Draft Post"
      date  = 2024-01-16
      tags  = ["ruby"]
      draft = true
      +++

      This draft should never appear in output.
    MD

    # ── Sample page ───────────────────────────────────────────────────────────
    File.write(File.join(dir, "content", "pages", "about.md"), <<~MD)
      +++
      title = "About"
      +++

      This is the about page content.
    MD

    # ── Sample gallery with two images ────────────────────────────────────────
    assets = File.join(dir, "content", "assets", "galleries", "photography")
    FileUtils.mkdir_p(assets)
    File.write(File.join(assets, "sunset.jpg"), "")
    File.write(File.join(assets, "pier.jpg"), "")

    File.write(File.join(dir, "content", "galleries", "photography.md"), <<~MD)
      +++
      title = "Photography"
      date  = 2024-02-01

      [[images]]
      file    = "sunset.jpg"
      caption = "Golden hour"
      +++

      Photos from the coast.
    MD

    # ── Draft gallery (must be excluded from all output) ─────────────────────
    File.write(File.join(dir, "content", "galleries", "draft-gallery.md"), <<~MD)
      +++
      title = "Draft Gallery"
      draft = true
      +++

      This draft gallery should never appear in output.
    MD
  end
end
