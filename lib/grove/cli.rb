# frozen_string_literal: true

require_relative "builder"
require_relative "scaffolder"
require_relative "generator"
require_relative "server"

module Grove
  module CLI
    USAGE = <<~USAGE
      Grove — a lightweight static site generator

      Usage:
        grove create <site_name>         Scaffold a new site
        grove build [--fast]             Build the site in the current directory
        grove serve                      Build and serve locally at http://localhost:4000
        grove new post "<Title>"         Create a new draft post
        grove new page "<Title>"         Create a new page
        grove new gallery "<Title>"      Create a new image gallery
    USAGE

    def self.run(argv)
      command = argv[0]

      case command
      when "create"
        site_name = argv[1]
        abort "Usage: grove create <site_name>" if site_name.nil? || site_name.strip.empty?
        Scaffolder.run(site_name)

      when "build"
        fast = argv.include?("--fast")
        Builder.new(Dir.pwd).build(fast: fast)

      when "serve"
        builder = Builder.new(Dir.pwd)
        builder.build
        Server.start(Dir.pwd, builder: builder)

      when "new"
        kind  = argv[1]
        title = argv[2]
        abort "Usage: grove new post|page|gallery \"<Title>\"" unless %w[post page gallery].include?(kind) && title
        Generator.run(kind, title, Dir.pwd)

      else
        puts USAGE
        exit(command.nil? ? 0 : 1)
      end
    end
  end
end
