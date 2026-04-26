# frozen_string_literal: true

require_relative "lib/grove/version"

Gem::Specification.new do |spec|
  spec.name          = "grove"
  spec.version       = Grove::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]
  spec.summary       = "A lightweight static site generator for the small web"
  spec.description   = "Grove generates pure HTML/CSS sites from Markdown content. No JavaScript, no external resources, no tracking."
  spec.homepage      = "https://github.com/yourname/grove"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7"

  spec.files = Dir["lib/**/*", "bin/*", "templates/**/*", "static/**/*"]
  spec.executables   = ["grove"]
  spec.require_paths = ["lib"]

  spec.add_dependency "kramdown", "~> 2.0"
  spec.add_dependency "toml-rb",  "~> 2.0"
  spec.add_dependency "webrick",  "~> 1.0"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake",     "~> 13.0"
end
