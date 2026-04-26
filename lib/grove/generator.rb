# frozen_string_literal: true

require "date"

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
      end

      abort "Grove: #{path} already exists" if File.exist?(path)
      File.write(path, content)
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
