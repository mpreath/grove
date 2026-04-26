# frozen_string_literal: true

require_relative "test_helper"

class UtilsTest < Minitest::Test
  def test_lowercases_input
    assert_equal "hello", Grove::Utils.tag_slug("Hello")
    assert_equal "ruby", Grove::Utils.tag_slug("RUBY")
  end

  def test_replaces_spaces_with_hyphens
    assert_equal "hello-world", Grove::Utils.tag_slug("hello world")
    assert_equal "open-source", Grove::Utils.tag_slug("open source")
  end

  def test_collapses_multiple_spaces
    assert_equal "hello-world", Grove::Utils.tag_slug("hello   world")
  end

  def test_removes_special_characters
    assert_equal "c", Grove::Utils.tag_slug("C++")
    assert_equal "net", Grove::Utils.tag_slug(".NET")
  end

  def test_collapses_consecutive_non_alphanumeric_into_single_hyphen
    assert_equal "hello-world", Grove::Utils.tag_slug("hello, world!")
    assert_equal "a-b", Grove::Utils.tag_slug("a---b")
  end

  def test_strips_leading_and_trailing_hyphens
    assert_equal "hello", Grove::Utils.tag_slug("-hello-")
    assert_equal "hello", Grove::Utils.tag_slug("---hello---")
  end

  def test_handles_already_valid_slug
    assert_equal "open-source", Grove::Utils.tag_slug("open-source")
  end

  def test_handles_numbers
    assert_equal "ruby-3", Grove::Utils.tag_slug("Ruby 3")
    assert_equal "web2", Grove::Utils.tag_slug("web2")
  end

  def test_returns_empty_string_for_all_special_chars
    assert_equal "", Grove::Utils.tag_slug("!@#$%")
  end
end
