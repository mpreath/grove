# frozen_string_literal: true

require "kramdown"
require "toml-rb"
require "date"

module Grove
  Page = Struct.new(:slug, :title, :date, :tags, :body_html, :source_path, :output_path, :kind, :images, :cover, keyword_init: true)
  GalleryImage = Struct.new(:file, :url, :alt, :caption, keyword_init: true)

  module Content
    FRONT_MATTER_RE = /\A\+\+\+\n(.*?)\n\+\+\+\n(.*)\z/m
    GALLERY_EXTS = %w[.jpg .jpeg .png .gif .webp .avif].freeze

    def self.scan(site_dir)
      posts = scan_dir(File.join(site_dir, "content", "posts"), :post)
      pages = scan_dir(File.join(site_dir, "content", "pages"), :page)
      galleries = scan_dir(File.join(site_dir, "content", "galleries"), :gallery, site_dir: site_dir)
      posts + pages + galleries
    end

    def self.scan_dir(dir, kind, site_dir: nil)
      return [] unless Dir.exist?(dir)

      Dir.glob(File.join(dir, "*.md")).filter_map do |path|
        parse_file(path, kind, site_dir: site_dir)
      end
    end

    def self.parse_file(path, kind, site_dir: nil)
      raw = File.read(path, encoding: "utf-8")
      match = FRONT_MATTER_RE.match(raw)
      unless match
        warn "Grove: skipping #{path} (no front matter)"
        return nil
      end

      front_matter_str, body_str = match[1], match[2]

      begin
        meta = TomlRB.parse(front_matter_str)
      rescue => e
        warn "Grove: skipping #{path} (TOML parse error: #{e.message})"
        return nil
      end

      return nil if meta["draft"]

      slug = derive_slug(path, meta)
      date = parse_date(meta["date"])

      output_path = case kind
      when :post
        File.join("posts", slug, "index.html")
      when :gallery
        File.join("galleries", slug, "index.html")
      else
        File.join(slug, "index.html")
      end

      body_html = Kramdown::Document.new(body_str).to_html

      images = (kind == :gallery) ? collect_images(meta, slug, site_dir) : nil

      Page.new(
        slug:        slug,
        title:       meta["title"] || slug,
        date:        date,
        tags:        Array(meta["tags"]),
        body_html:   body_html,
        source_path: path,
        output_path: output_path,
        kind:        kind,
        images:      images,
        cover:       images && pick_cover(images, meta["cover"])
      )
    end

    # Enumerate the gallery's source folder under content/assets/, applying any
    # per-image overrides declared in [[images]] front matter. Files named in
    # the overrides come first, in the order listed; the rest follow
    # alphabetically.
    def self.collect_images(meta, slug, site_dir)
      return [] if site_dir.nil?

      source = gallery_source(meta, slug)
      dir = File.join(site_dir, "content", "assets", source)

      unless Dir.exist?(dir)
        warn "Grove: gallery '#{slug}' has no image folder at content/assets/#{source}"
        return []
      end

      files = Dir.children(dir)
        .select { |f| File.file?(File.join(dir, f)) && GALLERY_EXTS.include?(File.extname(f).downcase) }
        .sort

      overrides = {}
      Array(meta["images"]).each do |entry|
        file = entry["file"]
        next unless file
        unless files.include?(file)
          warn "Grove: gallery '#{slug}' lists missing image '#{file}'"
          next
        end
        overrides[file] = entry
      end

      ordered = overrides.keys + (files - overrides.keys)

      ordered.map do |file|
        entry = overrides[file] || {}
        GalleryImage.new(
          file:    file,
          url:     "#{source}/#{file}",
          alt:     entry["alt"] || entry["caption"] || humanize_filename(file),
          caption: entry["caption"]
        )
      end
    end

    def self.gallery_source(meta, slug)
      source = meta["source"] || "galleries/#{slug}"
      source.to_s.sub(%r{\A/+}, "").chomp("/")
    end

    def self.pick_cover(images, cover_file)
      return nil if images.empty?
      return images.first if cover_file.nil?
      images.find { |img| img.file == cover_file } || images.first
    end

    # "sunset-over-dunes.jpg" => "Sunset over dunes"
    def self.humanize_filename(file)
      base = File.basename(file, ".*").tr("_-", "  ").squeeze(" ").strip
      base.empty? ? file : base.sub(/\A./, &:upcase)
    end

    def self.derive_slug(path, meta)
      return meta["slug"] if meta["slug"]
      # Strip date prefix (YYYY-MM-DD-) and .md extension
      basename = File.basename(path, ".md")
      basename.sub(/\A\d{4}-\d{2}-\d{2}-/, "")
    end

    def self.parse_date(value)
      return nil if value.nil?
      return value if value.is_a?(Date)
      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
