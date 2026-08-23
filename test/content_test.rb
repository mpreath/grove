# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"
require "date"

class ContentTest < Minitest::Test
  # ---------------------------------------------------------------------------
  # scan_dir
  # ---------------------------------------------------------------------------

  def test_scan_dir_returns_empty_array_for_missing_directory
    assert_equal [], Grove::Content.scan_dir("/nonexistent/path/xyz", :post)
  end

  def test_scan_dir_returns_empty_array_for_empty_directory
    Dir.mktmpdir do |dir|
      assert_equal [], Grove::Content.scan_dir(dir, :post)
    end
  end

  def test_scan_dir_ignores_non_markdown_files
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "notes.txt"), "just a text file")
      assert_equal [], Grove::Content.scan_dir(dir, :post)
    end
  end

  def test_scan_dir_returns_parsed_pages
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "2024-01-15-hello.md"), valid_post_md("Hello"))
      results = Grove::Content.scan_dir(dir, :post)
      assert_equal 1, results.length
    end
  end

  def test_scan_dir_skips_files_without_front_matter
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "no-front-matter.md"), "Just plain content, no front matter block.")
      results = Grove::Content.scan_dir(dir, :post)
      assert_empty results
    end
  end

  # ---------------------------------------------------------------------------
  # parse_file — front matter detection
  # ---------------------------------------------------------------------------

  def test_parse_file_returns_nil_for_missing_front_matter
    Dir.mktmpdir do |dir|
      path = File.join(dir, "bare.md")
      File.write(path, "No front matter here at all.")
      assert_nil Grove::Content.parse_file(path, :post)
    end
  end

  def test_parse_file_returns_nil_for_draft
    Dir.mktmpdir do |dir|
      path = File.join(dir, "draft.md")
      File.write(path, <<~MD)
        +++
        title = "Draft Post"
        draft = true
        +++

        This should be excluded.
      MD
      assert_nil Grove::Content.parse_file(path, :post)
    end
  end

  def test_parse_file_returns_nil_for_invalid_toml
    Dir.mktmpdir do |dir|
      path = File.join(dir, "bad-toml.md")
      File.write(path, <<~MD)
        +++
        title = [unclosed bracket
        +++

        Content.
      MD
      assert_nil Grove::Content.parse_file(path, :post)
    end
  end

  # ---------------------------------------------------------------------------
  # parse_file — returned Page struct
  # ---------------------------------------------------------------------------

  def test_parse_file_returns_page_struct_for_valid_post
    Dir.mktmpdir do |dir|
      path = File.join(dir, "2024-01-15-hello-world.md")
      File.write(path, <<~MD)
        +++
        title = "Hello, World"
        date  = 2024-01-15
        tags  = ["ruby", "meta"]
        draft = false
        +++

        Body content goes here.
      MD

      page = Grove::Content.parse_file(path, :post)

      refute_nil page
      assert_equal "hello-world",              page.slug
      assert_equal "Hello, World",             page.title
      assert_equal Date.new(2024, 1, 15),      page.date
      assert_equal ["ruby", "meta"],           page.tags
      assert_equal "posts/hello-world/index.html", page.output_path
      assert_equal :post,                      page.kind
      assert_includes page.body_html, "Body content goes here."
    end
  end

  def test_parse_file_returns_page_struct_for_valid_page
    Dir.mktmpdir do |dir|
      path = File.join(dir, "about.md")
      File.write(path, <<~MD)
        +++
        title = "About"
        +++

        About page content.
      MD

      page = Grove::Content.parse_file(path, :page)

      refute_nil page
      assert_equal "about",                page.slug
      assert_equal "About",               page.title
      assert_equal "about/index.html",    page.output_path
      assert_equal :page,                 page.kind
    end
  end

  def test_parse_file_uses_slug_as_title_when_title_missing
    Dir.mktmpdir do |dir|
      path = File.join(dir, "no-title.md")
      File.write(path, "+++\n\n+++\n\nContent.")
      page = Grove::Content.parse_file(path, :page)
      refute_nil page
      assert_equal "no-title", page.title
    end
  end

  def test_parse_file_tags_default_to_empty_array
    Dir.mktmpdir do |dir|
      path = File.join(dir, "no-tags.md")
      File.write(path, <<~MD)
        +++
        title = "No Tags"
        +++

        Content.
      MD
      page = Grove::Content.parse_file(path, :post)
      refute_nil page
      assert_equal [], page.tags
    end
  end

  def test_parse_file_converts_markdown_body_to_html
    Dir.mktmpdir do |dir|
      path = File.join(dir, "formatted.md")
      File.write(path, <<~MD)
        +++
        title = "Formatted"
        +++

        ## A Heading

        Some **bold** and _italic_ text.
      MD
      page = Grove::Content.parse_file(path, :page)
      refute_nil page
      assert_includes page.body_html, "<h2"
      assert_includes page.body_html, "<strong>bold</strong>"
    end
  end

  # ---------------------------------------------------------------------------
  # derive_slug
  # ---------------------------------------------------------------------------

  def test_derive_slug_strips_date_prefix_from_filename
    assert_equal "hello-world", Grove::Content.derive_slug("2024-01-15-hello-world.md", {})
  end

  def test_derive_slug_handles_filename_without_date_prefix
    assert_equal "about", Grove::Content.derive_slug("about.md", {})
  end

  def test_derive_slug_prefers_meta_slug_over_filename
    assert_equal "custom-slug", Grove::Content.derive_slug("2024-01-15-other.md", { "slug" => "custom-slug" })
  end

  # ---------------------------------------------------------------------------
  # parse_date
  # ---------------------------------------------------------------------------

  def test_parse_date_returns_nil_for_nil_input
    assert_nil Grove::Content.parse_date(nil)
  end

  def test_parse_date_passes_through_date_object
    date = Date.new(2024, 6, 1)
    assert_equal date, Grove::Content.parse_date(date)
  end

  def test_parse_date_parses_iso8601_string
    assert_equal Date.new(2024, 6, 1), Grove::Content.parse_date("2024-06-01")
  end

  def test_parse_date_returns_nil_for_unparseable_string
    assert_nil Grove::Content.parse_date("not-a-date")
  end

  # ---------------------------------------------------------------------------
  # scan (integration)
  # ---------------------------------------------------------------------------

  def test_scan_collects_posts_and_pages
    Dir.mktmpdir do |dir|
      posts_dir = File.join(dir, "content", "posts")
      pages_dir = File.join(dir, "content", "pages")
      FileUtils.mkdir_p(posts_dir)
      FileUtils.mkdir_p(pages_dir)

      File.write(File.join(posts_dir, "2024-01-01-post-one.md"), valid_post_md("Post One"))
      File.write(File.join(pages_dir, "contact.md"),             valid_page_md("Contact"))

      results = Grove::Content.scan(dir)
      assert_equal 2, results.length

      kinds = results.map(&:kind)
      assert_includes kinds, :post
      assert_includes kinds, :page
    end
  end

  def test_scan_returns_empty_when_content_directories_missing
    Dir.mktmpdir do |dir|
      assert_equal [], Grove::Content.scan(dir)
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # Galleries
  # ---------------------------------------------------------------------------

  def test_gallery_output_path
    with_gallery_site(images: %w[a.jpg]) do |site|
      gallery = scan_gallery(site)
      assert_equal File.join("galleries", "photography", "index.html"), gallery.output_path
      assert_equal :gallery, gallery.kind
    end
  end

  def test_gallery_auto_discovers_images_alphabetically
    with_gallery_site(images: %w[zebra.jpg apple.png middle.webp]) do |site|
      gallery = scan_gallery(site)
      assert_equal %w[apple.png middle.webp zebra.jpg], gallery.images.map(&:file)
    end
  end

  def test_gallery_image_urls_are_output_root_relative
    with_gallery_site(images: %w[a.jpg]) do |site|
      gallery = scan_gallery(site)
      assert_equal "galleries/photography/a.jpg", gallery.images.first.url
    end
  end

  def test_gallery_ignores_non_image_files
    with_gallery_site(images: %w[a.jpg notes.txt archive.zip]) do |site|
      gallery = scan_gallery(site)
      assert_equal %w[a.jpg], gallery.images.map(&:file)
    end
  end

  def test_gallery_honors_explicit_source
    Dir.mktmpdir do |site|
      FileUtils.mkdir_p(File.join(site, "content", "galleries"))
      FileUtils.mkdir_p(File.join(site, "content", "assets", "art", "paintings"))
      File.write(File.join(site, "content", "assets", "art", "paintings", "oil.jpg"), "")
      File.write(File.join(site, "content", "galleries", "photography.md"), <<~MD)
        +++
        title  = "Photography"
        source = "art/paintings"
        +++

      MD
      gallery = scan_gallery(site)
      assert_equal %w[oil.jpg], gallery.images.map(&:file)
      assert_equal "art/paintings/oil.jpg", gallery.images.first.url
    end
  end

  def test_gallery_overrides_reorder_and_attach_captions
    front_matter = <<~TOML
      [[images]]
      file    = "zebra.jpg"
      caption = "A zebra"
      alt     = "Striped horse"
    TOML

    with_gallery_site(images: %w[apple.jpg zebra.jpg], extra: front_matter) do |site|
      gallery = scan_gallery(site)
      assert_equal %w[zebra.jpg apple.jpg], gallery.images.map(&:file)
      assert_equal "A zebra", gallery.images.first.caption
      assert_equal "Striped horse", gallery.images.first.alt
      assert_nil gallery.images.last.caption
    end
  end

  def test_gallery_override_for_missing_file_is_skipped
    front_matter = <<~TOML
      [[images]]
      file    = "gone.jpg"
      caption = "Nope"
    TOML

    with_gallery_site(images: %w[a.jpg], extra: front_matter) do |site|
      gallery = nil
      _out, err = capture_io { gallery = scan_gallery(site) }
      assert_equal %w[a.jpg], gallery.images.map(&:file)
      assert_includes err, "gone.jpg"
    end
  end

  def test_gallery_with_missing_source_folder_has_no_images
    Dir.mktmpdir do |site|
      FileUtils.mkdir_p(File.join(site, "content", "galleries"))
      File.write(File.join(site, "content", "galleries", "photography.md"), <<~MD)
        +++
        title = "Photography"
        +++

      MD
      gallery = nil
      _out, err = capture_io { gallery = scan_gallery(site) }
      assert_equal [], gallery.images
      assert_nil gallery.cover
      assert_includes err, "no image folder"
    end
  end

  def test_gallery_draft_is_skipped
    with_gallery_site(images: %w[a.jpg], extra: "draft = true\n") do |site|
      assert_equal [], Grove::Content.scan(site).select { |p| p.kind == :gallery }
    end
  end

  def test_gallery_cover_defaults_to_first_image
    with_gallery_site(images: %w[apple.jpg zebra.jpg]) do |site|
      assert_equal "apple.jpg", scan_gallery(site).cover.file
    end
  end

  def test_gallery_cover_honors_front_matter
    with_gallery_site(images: %w[apple.jpg zebra.jpg], extra: 'cover = "zebra.jpg"' + "\n") do |site|
      assert_equal "zebra.jpg", scan_gallery(site).cover.file
    end
  end

  def test_gallery_cover_falls_back_when_named_file_is_missing
    with_gallery_site(images: %w[apple.jpg], extra: 'cover = "gone.jpg"' + "\n") do |site|
      assert_equal "apple.jpg", scan_gallery(site).cover.file
    end
  end

  def test_gallery_alt_derives_from_filename
    with_gallery_site(images: %w[sunset-over-dunes.jpg]) do |site|
      assert_equal "Sunset over dunes", scan_gallery(site).images.first.alt
    end
  end

  def test_posts_and_pages_have_no_images
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "2024-01-15-hello.md"), valid_post_md("Hello"))
      assert_nil Grove::Content.scan_dir(dir, :post).first.images
    end
  end

  private

  def valid_post_md(title)
    <<~MD
      +++
      title = "#{title}"
      date  = 2024-01-15
      tags  = []
      draft = false
      +++

      Content for #{title}.
    MD
  end

  def valid_page_md(title)
    <<~MD
      +++
      title = "#{title}"
      +++

      Content for #{title}.
    MD
  end

  # Builds a throwaway site with one gallery at content/galleries/photography.md
  # and the given image filenames under content/assets/galleries/photography/.
  def with_gallery_site(images:, extra: nil)
    Dir.mktmpdir do |site|
      FileUtils.mkdir_p(File.join(site, "content", "galleries"))
      assets = File.join(site, "content", "assets", "galleries", "photography")
      FileUtils.mkdir_p(assets)
      images.each { |name| File.write(File.join(assets, name), "") }

      File.write(File.join(site, "content", "galleries", "photography.md"), <<~MD)
        +++
        title = "Photography"
        #{extra}+++

        Intro text.
      MD

      yield site
    end
  end

  def scan_gallery(site)
    Grove::Content.scan(site).find { |p| p.kind == :gallery }
  end
end
