require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'find'

# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'

# Gemspec
gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riemann-docker'

  s.name = 'riemann-docker'
  s.version = '0.1.0'
  s.author = 'Shani Elharrar'
  s.email = ''
  s.homepage = 'https://github.com/riemann/riemann-docker'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Submits Docker container stats to riemann.'

  s.add_dependency 'riemann-tools', '>= 0.2.7'
  s.add_dependency 'docker-api', '>= 1.22.0'

  s.files = FileList['bin/*', 'LICENSE', 'README.md'].to_a
  s.executables |= Dir.entries('bin/')
  s.has_rdoc = false

  s.required_ruby_version = '>= 1.8.7'
end

Gem::PackageTask.new gemspec do |p|
end
