# frozen_string_literal: true

require "fileutils"
require "date"

module Grove
  module Scaffolder
    GEM_ROOT = File.expand_path("../../..", __FILE__)

    def self.run(site_name)
      dest = File.expand_path(site_name)
      abort "Grove: '#{site_name}' already exists" if File.exist?(dest)

      puts "Grove: creating site '#{site_name}'"

      # Directories
      %w[content/posts content/pages content/assets templates static output].each do |dir|
        FileUtils.mkdir_p(File.join(dest, dir))
      end

      # config.toml
      write_config(dest, site_name)

      # Copy bundled templates
      copy_dir(File.join(GEM_ROOT, "templates"), File.join(dest, "templates"))

      # Copy bundled static files
      copy_dir(File.join(GEM_ROOT, "static"), File.join(dest, "static"))

      # Sample content
      write_sample_post(dest)
      write_sample_page(dest)

      puts "Grove: done! cd #{site_name} && grove build"
    end

    def self.write_config(dest, site_name)
      title = File.basename(site_name).split(/[-_]/).map(&:capitalize).join(" ")
      File.write(File.join(dest, "config.toml"), <<~TOML)
        site_title  = "#{title}"
        base_url    = "https://example.com"
        author      = "Your Name"
        description = "A site built with Grove."
        footer      = "\\u00A9 #{Date.today.year} Your Name"

        [[nav]]
        label = "Home"
        url   = "/"

        [[nav]]
        label = "About"
        url   = "/about/"
      TOML
    end

    def self.write_sample_post(dest)
      date = Date.today.to_s
      path = File.join(dest, "content", "posts", "#{date}-hello-world.md")
      File.write(path, <<~MD)
        +++
        title = "Hello, World"
        date  = #{date}
        tags  = ["meta"]
        draft = false
        +++

        Welcome to your new Grove site. Edit this post or create new ones with `grove new post "Title"`.

        ## Getting started

        1. Edit `config.toml` with your site details.
        2. Write posts in `content/posts/` and pages in `content/pages/`.
        3. Run `grove build` to generate `output/`.
        4. Deploy the `output/` directory to any static host.
      MD
    end

    def self.write_sample_page(dest)
      path = File.join(dest, "content", "pages", "about.md")
      File.write(path, <<~MD)
        +++
        title = "About"
        +++

        This is the about page. Tell visitors who you are.
      MD
    end

    def self.copy_dir(src, dest)
      return unless Dir.exist?(src)
      Dir.glob(File.join(src, "**", "*")).each do |file|
        next if File.directory?(file)
        rel  = file.sub("#{src}/", "")
        target = File.join(dest, rel)
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(file, target)
      end
    end
  end
end
