# frozen_string_literal: true

module Grove
  module Utils
    # Convert a tag string to a URL-safe slug.
    #
    #   tag_slug("Hello World")  # => "hello-world"
    #   tag_slug("C++")          # => "c"
    #   tag_slug("open-source")  # => "open-source"
    #
    def self.tag_slug(tag)
      tag.downcase
         .gsub(/[^a-z0-9]+/, "-")
         .gsub(/\A-|-\z/, "")
    end
  end
end
