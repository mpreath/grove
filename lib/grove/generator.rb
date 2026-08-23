# frozen_string_literal: true

require "date"
require "fileutils"

module Grove
  module Generator
    def self.run(kind, title, site_dir)
      slug  = slugify(title)
      today = Date.today.to_s

      case kind
      when "post"
        filename = "#{today}-#{slug}.md"
        path     = File.join(site_dir, "content", "posts", filename)
        content  = <<~MD
          +++
          title = "#{title}"
          date  = #{today}
          tags  = []
          draft = true
          +++

        MD
      when "page"
        filename = "#{slug}.md"
        path     = File.join(site_dir, "content", "pages", filename)
        content  = <<~MD
          +++
          title = "#{title}"
          +++

        MD
      when "gallery"
        filename = "#{slug}.md"
        path     = File.join(site_dir, "content", "galleries", filename)
        content  = <<~MD
          +++
          title = "#{title}"
          # source = "galleries/#{slug}"   # defaults to galleries/<slug>
          # cover  = "first.jpg"           # defaults to the first image
          +++

        MD
        assets_dir = File.join(site_dir, "content", "assets", "galleries", slug)
      end

      abort "Grove: #{path} already exists" if File.exist?(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      if assets_dir
        FileUtils.mkdir_p(assets_dir)
        puts "Grove: created #{assets_dir}/ — drop images here"
      end
      puts "Grove: created #{path}"
    end

    def self.slugify(title)
      title.downcase
           .gsub(/[^a-z0-9\s-]/, "")
           .strip
           .gsub(/\s+/, "-")
    end
  end
end
