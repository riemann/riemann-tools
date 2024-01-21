# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in riemann-tools.gemspec
gemspec

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
  # XXX: Needed for Ruby 2.6 compatibility
  #
  # With Ruby 2.6 an older version of rakup is installed that cause other gems
  # to be installed with a legacy version.
  #
  # Because rakup is only needed when using rack 3, we can just ignore this
  # with Ruby 2.6.
  gem 'rackup'
end
