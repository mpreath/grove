# frozen_string_literal: true

require "erb"
require "uri"
require_relative "utils"

module Grove
  class Renderer
    def initialize(config, templates_dir)
      @config = config
      @templates_dir = templates_dir
    end

    # Render a content template and wrap it in base.html.erb.
    # locals is a Hash of variable names (Symbols) to values.
    # output_path is the relative output path (e.g. "posts/hello/index.html")
    # used to compute root-relative asset paths for filesystem browsability.
    def render(template_name, locals = {}, output_path: nil)
      root_prefix = compute_root_prefix(output_path)
      all_locals = locals.merge(config: @config, root_prefix: root_prefix)

      content_html = render_template(template_name, all_locals)
      render_template("base.html.erb", all_locals.merge(content: content_html))
    end

    def render_template(template_name, locals = {})
      path = File.join(@templates_dir, template_name)
      template_str = File.read(path, encoding: "utf-8")
      erb = ERB.new(template_str, trim_mode: "-")
      erb.result(build_binding(locals))
    end

    private

    # Returns a prefix like "" / "../" / "../../" so asset links work when
    # browsing the output folder directly from disk.
    def compute_root_prefix(output_path)
      return "" if output_path.nil?
      depth = output_path.count("/")
      (depth > 0) ? "../" * depth : ""
    end

    # Extract the path component from base_url for subpath deployments.
    # e.g. "https://mpreath.github.io/blog" => "/blog"
    #      "https://example.com"            => ""
    def compute_base_path(config)
      base_url = config["base_url"] || ""
      return "" if base_url.empty?
      uri_path = URI.parse(base_url).path.chomp("/")
      uri_path || ""
    rescue URI::InvalidURIError
      ""
    end

    def build_binding(locals)
      root_prefix = locals[:root_prefix] || ""
      base_path = compute_base_path(locals[:config] || {})

      ctx = Object.new

      # Expose helper methods into the ERB context
      ctx.define_singleton_method(:root_relative) { |path| "#{root_prefix}#{path}" }
      ctx.define_singleton_method(:tag_slug) { |tag| Grove::Utils.tag_slug(tag) }
      ctx.define_singleton_method(:site_url) { |path| "#{base_path}#{path}" }

      locals.each do |key, value|
        ctx.instance_variable_set(:"@#{key}", value)
        ctx.define_singleton_method(key) { instance_variable_get(:"@#{key}") }
      end

      ctx.instance_eval { binding }
    end
  end
end
