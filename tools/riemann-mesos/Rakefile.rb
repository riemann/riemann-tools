require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'find'

# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'

# Gemspec
gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riemann-mesos'

  s.name = 'riemann-mesos'
  s.version = '0.1.0'
  s.author = 'Giulio Eulisse'
  s.email = 'giulio.eulisse@cern.ch'
  s.homepage = 'https://github.com/riemann/riemann-mesos'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Submits mesos stats to riemann.'

  s.add_dependency 'riemann-tools', '>= 0.2.7'
  s.add_dependency 'faraday', '>= 0.8.5'
  s.add_dependency 'json'

  s.files = FileList['bin/*', 'LICENSE', 'README.md'].to_a
  s.executables |= Dir.entries('bin/')
  s.has_rdoc = false

  s.required_ruby_version = '>= 1.8.7'
end

Gem::PackageTask.new gemspec do |p|
end
