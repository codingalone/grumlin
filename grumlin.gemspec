# frozen_string_literal: true

require_relative "lib/grumlin/version"

Gem::Specification.new do |spec|
  spec.name          = "grumlin"
  spec.version       = Grumlin::VERSION
  spec.authors       = ["Gleb Sinyavskiy"]
  spec.email         = ["zhulik.gleb@gmail.com"]

  spec.summary       = "Gremlin graph traversal language DSL and client for Ruby."

  spec.description   = <<~DESCRIPTION
    Gremlin graph traversal language DSL and client for Ruby. Suitable and tested with gremlin-server and AWS Neptune.
  DESCRIPTION

  spec.homepage      = "https://github.com/zhulik/grumlin"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/zhulik/grumlin"
  spec.metadata["changelog_uri"] = "https://github.com/babbel/grumlin/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "async-pool", "~> 0.3"
  spec.add_dependency "async-websocket", ">= 0.19", "< 0.20"
  spec.add_dependency "oj", "~> 3.13"
  spec.add_dependency "retryable", "~> 3.0"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
