# frozen_string_literal: true

require_relative "lib/filters_tracer/version"

Gem::Specification.new do |spec|

  spec.name = "rails_filters_tracer"
  spec.version = FiltersTracer::VERSION
  spec.authors = ["kudojp"]
  spec.email = ["heyjudejudejude1968@gmail.com"]

  spec.summary = "A performance monitoring tool to find the bottleneck in filters of a Rails controller action"
  spec.description = "With this gem, you can measure the execution times of each of filters registered to a Rails controller action. This is a supplementary tool of newrelic-ruby-agent gem."
  spec.homepage = "https://github.com/kudojp/rails_filters_tracer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "6.0.3", "<7"
  spec.add_dependency "newrelic_rpm", ">= 6.12", "<9"

  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "simplecov-cobertura"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
