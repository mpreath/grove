# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "date"
require "fileutils"

class GeneratorTest < Minitest::Test
  # ---------------------------------------------------------------------------
  # slugify
  # ---------------------------------------------------------------------------

  def test_slugify_lowercases_input
    assert_equal "hello", Grove::Generator.slugify("Hello")
    assert_equal "ruby",  Grove::Generator.slugify("RUBY")
  end

  def test_slugify_replaces_spaces_with_hyphens
    assert_equal "hello-world",    Grove::Generator.slugify("Hello World")
    assert_equal "my-great-post",  Grove::Generator.slugify("My Great Post")
  end

  def test_slugify_collapses_multiple_spaces
    assert_equal "hello-world", Grove::Generator.slugify("hello   world")
  end

  def test_slugify_strips_leading_and_trailing_whitespace
    assert_equal "hello", Grove::Generator.slugify("  hello  ")
  end

  def test_slugify_removes_special_characters
    assert_equal "whats-new",   Grove::Generator.slugify("What's New")
    assert_equal "hello-world", Grove::Generator.slugify("Hello, World!")
    assert_equal "c",           Grove::Generator.slugify("C++")
  end

  def test_slugify_preserves_hyphens
    assert_equal "already-a-slug", Grove::Generator.slugify("already-a-slug")
  end

  def test_slugify_preserves_numbers
    assert_equal "ruby-32-released", Grove::Generator.slugify("Ruby 3.2 Released")
    assert_equal "top-10-tips",      Grove::Generator.slugify("Top 10 Tips")
  end

  def test_slugify_handles_empty_string
    assert_equal "", Grove::Generator.slugify("")
  end

  # ---------------------------------------------------------------------------
  # run — post creation
  # ---------------------------------------------------------------------------

  def test_run_creates_post_file_with_correct_name
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      Grove::Generator.run("post", "My First Post", dir)

      today    = Date.today.to_s
      expected = File.join(dir, "content", "posts", "#{today}-my-first-post.md")
      assert File.exist?(expected), "Expected post file to exist at #{expected}"
    end
  end

  def test_run_post_front_matter_contains_title
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      Grove::Generator.run("post", "Hello World", dir)

      today   = Date.today.to_s
      path    = File.join(dir, "content", "posts", "#{today}-hello-world.md")
      content = File.read(path)
      assert_includes content, 'title = "Hello World"'
    end
  end

  def test_run_post_front_matter_contains_todays_date
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      Grove::Generator.run("post", "Dated Post", dir)

      today   = Date.today.to_s
      path    = File.join(dir, "content", "posts", "#{today}-dated-post.md")
      content = File.read(path)
      assert_includes content, "date  = #{today}"
    end
  end

  def test_run_post_front_matter_sets_draft_true
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      Grove::Generator.run("post", "Draft Post", dir)

      today   = Date.today.to_s
      path    = File.join(dir, "content", "posts", "#{today}-draft-post.md")
      content = File.read(path)
      assert_includes content, "draft = true"
    end
  end

  def test_run_post_front_matter_contains_empty_tags_array
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      Grove::Generator.run("post", "Tagged Post", dir)

      today   = Date.today.to_s
      path    = File.join(dir, "content", "posts", "#{today}-tagged-post.md")
      content = File.read(path)
      assert_includes content, "tags  = []"
    end
  end

  def test_run_post_front_matter_is_fenced_with_plus_plus_plus
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      Grove::Generator.run("post", "Fenced Post", dir)

      today   = Date.today.to_s
      path    = File.join(dir, "content", "posts", "#{today}-fenced-post.md")
      content = File.read(path)
      assert_match(/\A\+\+\+\n/, content, "File should start with +++ fence")
      assert_match(/\+\+\+\n/, content)
    end
  end

  # ---------------------------------------------------------------------------
  # run — page creation
  # ---------------------------------------------------------------------------

  def test_run_creates_page_file_with_correct_name
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "pages"))
      Grove::Generator.run("page", "About Me", dir)

      expected = File.join(dir, "content", "pages", "about-me.md")
      assert File.exist?(expected), "Expected page file to exist at #{expected}"
    end
  end

  def test_run_page_file_has_no_date_prefix
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "pages"))
      Grove::Generator.run("page", "Links", dir)

      today  = Date.today.to_s
      # The filename must NOT start with a date prefix
      paged_name    = "links.md"
      dated_name    = "#{today}-links.md"
      pages_dir     = File.join(dir, "content", "pages")

      assert     File.exist?(File.join(pages_dir, paged_name)),  "Expected #{paged_name}"
      refute     File.exist?(File.join(pages_dir, dated_name)),  "Did not expect #{dated_name}"
    end
  end

  def test_run_page_front_matter_contains_title
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "pages"))
      Grove::Generator.run("page", "Contact", dir)

      path    = File.join(dir, "content", "pages", "contact.md")
      content = File.read(path)
      assert_includes content, 'title = "Contact"'
    end
  end

  def test_run_page_has_no_draft_key
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "pages"))
      Grove::Generator.run("page", "Projects", dir)

      path    = File.join(dir, "content", "pages", "projects.md")
      content = File.read(path)
      refute_includes content, "draft"
    end
  end

  # ---------------------------------------------------------------------------
  # run — collision guard
  # ---------------------------------------------------------------------------

  def test_run_aborts_when_post_already_exists
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      today    = Date.today.to_s
      existing = File.join(dir, "content", "posts", "#{today}-existing-post.md")
      File.write(existing, "already here")

      assert_raises(SystemExit) do
        Grove::Generator.run("post", "Existing Post", dir)
      end
    end
  end

  def test_run_aborts_when_page_already_exists
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "pages"))
      existing = File.join(dir, "content", "pages", "about.md")
      File.write(existing, "already here")

      assert_raises(SystemExit) do
        Grove::Generator.run("page", "About", dir)
      end
    end
  end

  def test_run_does_not_overwrite_existing_post_on_abort
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "content", "posts"))
      today    = Date.today.to_s
      existing = File.join(dir, "content", "posts", "#{today}-my-post.md")
      original = "original content"
      File.write(existing, original)

      assert_raises(SystemExit) { Grove::Generator.run("post", "My Post", dir) }
      assert_equal original, File.read(existing)
    end
  end
end
