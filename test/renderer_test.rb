# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class RendererTest < Minitest::Test
  # Helpers live on the ERB binding, so exercise them through a template.
  def render(template, config: {}, locals: {}, output_path: nil)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "base.html.erb"), "<%= content %>")
      File.write(File.join(dir, "t.html.erb"), template)
      Grove::Renderer.new(config, dir).render("t.html.erb", locals, output_path: output_path)
    end
  end

  # ---------------------------------------------------------------------------
  # h
  # ---------------------------------------------------------------------------

  def test_h_escapes_html_special_characters
    assert_equal "&lt;b&gt;", render("<%= h('<b>') %>")
    assert_equal "a &amp; b", render("<%= h('a & b') %>")
    assert_equal "&quot;q&quot;", render(%(<%= h('"q"') %>))
  end

  def test_h_handles_nil_and_non_strings
    assert_equal "", render("<%= h(nil) %>")
    assert_equal "42", render("<%= h(42) %>")
  end

  def test_h_leaves_plain_text_untouched
    assert_equal "Golden hour", render("<%= h('Golden hour') %>")
  end

  # ---------------------------------------------------------------------------
  # root_relative
  # ---------------------------------------------------------------------------

  def test_root_relative_at_output_root
    assert_equal "style.css", render("<%= root_relative('style.css') %>", output_path: "index.html")
  end

  def test_root_relative_one_level_deep
    assert_equal "../style.css", render("<%= root_relative('style.css') %>", output_path: "about/index.html")
  end

  def test_root_relative_two_levels_deep
    assert_equal "../../a.jpg", render("<%= root_relative('a.jpg') %>", output_path: "galleries/art/index.html")
  end

  def test_root_relative_without_output_path
    assert_equal "style.css", render("<%= root_relative('style.css') %>")
  end

  # ---------------------------------------------------------------------------
  # site_url
  # ---------------------------------------------------------------------------

  def test_site_url_with_bare_domain
    assert_equal "/about/", render("<%= site_url('/about/') %>", config: {"base_url" => "https://example.com"})
  end

  def test_site_url_with_subpath_deployment
    config = {"base_url" => "https://user.github.io/blog"}
    assert_equal "/blog/about/", render("<%= site_url('/about/') %>", config: config)
  end

  def test_site_url_strips_trailing_slash_from_base_url
    config = {"base_url" => "https://user.github.io/blog/"}
    assert_equal "/blog/about/", render("<%= site_url('/about/') %>", config: config)
  end

  def test_site_url_with_missing_base_url
    assert_equal "/about/", render("<%= site_url('/about/') %>")
  end
end
