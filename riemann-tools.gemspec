# frozen_string_literal: true

require_relative 'lib/riemann/tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'riemann-tools'
  spec.version       = Riemann::Tools::VERSION
  spec.authors       = ['Kyle Kingsbury']
  spec.email         = ['aphyr@aphyr.com']

  spec.summary       = 'Utilities which submit events to Riemann.'
  spec.description   = 'Collection of utilities which submit events to Riemann,'
  spec.homepage      = 'https://github.com/aphyr/riemann-tools'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) } -
      [
        'lib/riemann/tools/mdstat_parser.y',
        'lib/riemann/tools/uptime_parser.y',
      ] +
      [
        'lib/riemann/tools/mdstat_parser.tab.rb',
        'lib/riemann/tools/uptime_parser.tab.rb',
      ]
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'json', '>= 1.8'
  spec.add_runtime_dependency 'optimist', '~> 3.0', '>= 3.0.0'
  spec.add_runtime_dependency 'riemann-client', '~> 1.1'

  spec.add_development_dependency 'github_changelog_generator'
  spec.add_development_dependency 'racc'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'sinatra'
  spec.add_development_dependency 'webrick'
end
