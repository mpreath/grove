# frozen_string_literal: true

require "fileutils"
require "toml-rb"
require "date"
require_relative "content"
require_relative "renderer"
require_relative "utils"

module Grove
  class Builder
    def initialize(site_dir)
      @site_dir = File.expand_path(site_dir)
      @output_dir = File.join(@site_dir, "output")
      @templates_dir = File.join(@site_dir, "templates")
      @static_dir = File.join(@site_dir, "static")
      @assets_dir = File.join(@site_dir, "content", "assets")
    end

    def build(fast: false)
      load_config
      @renderer = Renderer.new(@config, @templates_dir)

      pages = Content.scan(@site_dir)
      posts = pages.select { |p| p.kind == :post }.sort_by { |p| p.date || Date.new(0) }.reverse
      standalone_pages = pages.select { |p| p.kind == :page }
      galleries = pages.select { |p| p.kind == :gallery }
        .sort_by { |g| [g.date ? 0 : 1, g.date ? -g.date.jd : 0, g.title.to_s] }

      FileUtils.mkdir_p(@output_dir)

      render_posts(posts, fast: fast)
      render_pages(standalone_pages, fast: fast)
      render_galleries(galleries)
      render_gallery_index(galleries) unless galleries.empty?
      render_homepage(posts)
      render_tag_pages(posts)
      render_404
      render_sitemap(posts + standalone_pages + galleries)
      render_rss(posts)
      copy_assets
    end

    private

    def load_config
      config_path = File.join(@site_dir, "config.toml")
      abort "Grove: config.toml not found in #{@site_dir}" unless File.exist?(config_path)
      @config = TomlRB.load_file(config_path)
    end

    def render_posts(posts, fast:)
      posts.each do |post|
        out_path = File.join(@output_dir, post.output_path)
        next if fast && up_to_date?(post.source_path, out_path)

        FileUtils.mkdir_p(File.dirname(out_path))
        html = @renderer.render("post.html.erb", {page: post, posts: posts}, output_path: post.output_path)
        File.write(out_path, html)
        puts "  built #{post.output_path}"
      end
    end

    def render_pages(pages, fast:)
      pages.each do |page|
        out_path = File.join(@output_dir, page.output_path)
        next if fast && up_to_date?(page.source_path, out_path)

        FileUtils.mkdir_p(File.dirname(out_path))
        html = @renderer.render("page.html.erb", {page: page}, output_path: page.output_path)
        File.write(out_path, html)
        puts "  built #{page.output_path}"
      end
    end

    # Galleries deliberately ignore `fast:` — up_to_date? only compares the
    # .md source, so adding an image to the source folder would be missed.
    # Galleries are few and cheap to render, so always rebuild them.
    def render_galleries(galleries)
      galleries.each do |gallery|
        out_path = File.join(@output_dir, gallery.output_path)
        FileUtils.mkdir_p(File.dirname(out_path))
        html = @renderer.render("gallery.html.erb", {page: gallery}, output_path: gallery.output_path)
        File.write(out_path, html)
        puts "  built #{gallery.output_path}"
      end
    end

    def render_gallery_index(galleries)
      output_path = "galleries/index.html"
      out_path = File.join(@output_dir, output_path)
      FileUtils.mkdir_p(File.dirname(out_path))
      html = @renderer.render("gallery_index.html.erb", {galleries: galleries}, output_path: output_path)
      File.write(out_path, html)
      puts "  built #{output_path}"
    end

    def render_homepage(posts)
      out_path = File.join(@output_dir, "index.html")
      html = @renderer.render("index.html.erb", {posts: posts}, output_path: "index.html")
      File.write(out_path, html)
      puts "  built index.html"
    end

    def render_tag_pages(posts)
      tags = posts.flat_map(&:tags).uniq
      tags.each do |tag|
        tagged = posts.select { |p| p.tags.include?(tag) }
        slug = Utils.tag_slug(tag)
        dir = File.join(@output_dir, "tags", slug)
        tag_output_path = "tags/#{slug}/index.html"
        FileUtils.mkdir_p(dir)
        html = @renderer.render("index.html.erb", {posts: tagged, tag: tag}, output_path: tag_output_path)
        File.write(File.join(dir, "index.html"), html)
        puts "  built #{tag_output_path}"
      end
    end

    def render_404
      out_path = File.join(@output_dir, "404.html")
      html = @renderer.render("404.html.erb", {}, output_path: "404.html")
      File.write(out_path, html)
      puts "  built 404.html"
    end

    def render_sitemap(all_pages)
      base_url = (@config["base_url"] || "").chomp("/")

      url_tags = []
      url_tags << sitemap_url("#{base_url}/")
      all_pages.select { |p| p.kind == :post }.each do |post|
        url_tags << sitemap_url("#{base_url}/posts/#{post.slug}/", post.date)
      end
      all_pages.select { |p| p.kind == :page }.each do |page|
        url_tags << sitemap_url("#{base_url}/#{page.slug}/")
      end
      galleries = all_pages.select { |p| p.kind == :gallery }
      unless galleries.empty?
        url_tags << sitemap_url("#{base_url}/galleries/")
        galleries.each do |gallery|
          url_tags << sitemap_url("#{base_url}/galleries/#{gallery.slug}/", gallery.date)
        end
      end

      sitemap = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        #{url_tags.join("\n")}
        </urlset>
      XML

      File.write(File.join(@output_dir, "sitemap.xml"), sitemap)
      puts "  built sitemap.xml"
    end

    def sitemap_url(loc, date = nil)
      lastmod = date ? "\n    <lastmod>#{date}</lastmod>" : ""
      "  <url>\n    <loc>#{escape_xml(loc)}</loc>#{lastmod}\n  </url>"
    end

    def render_rss(posts)
      base_url = (@config["base_url"] || "").chomp("/")
      items = posts.first(20).map do |post|
        url = "#{base_url}/posts/#{post.slug}/"
        date = post.date ? post.date.strftime("%a, %d %b %Y 00:00:00 +0000") : ""
        <<~ITEM
          <item>
            <title>#{escape_xml(post.title)}</title>
            <link>#{url}</link>
            <guid>#{url}</guid>
            <pubDate>#{date}</pubDate>
            <description>#{escape_xml(post.body_html)}</description>
          </item>
        ITEM
      end.join("\n")

      rss = <<~RSS
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>#{escape_xml(@config["site_title"] || "")}</title>
            <link>#{base_url}/</link>
            <description>#{escape_xml(@config["description"] || "")}</description>
            <language>en</language>
            #{items}
          </channel>
        </rss>
      RSS

      File.write(File.join(@output_dir, "feed.xml"), rss)
      puts "  built feed.xml"
    end

    def copy_assets
      [@static_dir, @assets_dir].each do |src|
        next unless Dir.exist?(src)
        Dir.glob(File.join(src, "**", "*")).each do |file|
          next if File.directory?(file)
          rel = file.sub("#{src}/", "")
          dest = File.join(@output_dir, rel)
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(file, dest)
        end
      end
    end

    def up_to_date?(source, output)
      File.exist?(output) && File.mtime(source) <= File.mtime(output)
    end

    def escape_xml(str)
      str.to_s
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
        .gsub('"', "&quot;")
    end
  end
end
