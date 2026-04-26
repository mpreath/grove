# frozen_string_literal: true

require "kramdown"
require "toml-rb"
require "date"

module Grove
  Page = Struct.new(:slug, :title, :date, :tags, :body_html, :source_path, :output_path, :kind, keyword_init: true)

  module Content
    FRONT_MATTER_RE = /\A\+\+\+\n(.*?)\n\+\+\+\n(.*)\z/m

    def self.scan(site_dir)
      posts = scan_dir(File.join(site_dir, "content", "posts"), :post)
      pages = scan_dir(File.join(site_dir, "content", "pages"), :page)
      posts + pages
    end

    def self.scan_dir(dir, kind)
      return [] unless Dir.exist?(dir)

      Dir.glob(File.join(dir, "*.md")).filter_map do |path|
        parse_file(path, kind)
      end
    end

    def self.parse_file(path, kind)
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

      output_path = if kind == :post
        File.join("posts", slug, "index.html")
      else
        File.join(slug, "index.html")
      end

      body_html = Kramdown::Document.new(body_str).to_html

      Page.new(
        slug:        slug,
        title:       meta["title"] || slug,
        date:        date,
        tags:        Array(meta["tags"]),
        body_html:   body_html,
        source_path: path,
        output_path: output_path,
        kind:        kind
      )
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
