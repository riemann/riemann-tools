require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'find'

# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'

# Gemspec
gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riemann-tools'

  s.name = 'riemann-tools'
  s.version = '0.2.6'
  s.author = 'Kyle Kingsbury'
  s.email = 'aphyr@aphyr.com'
  s.homepage = 'https://github.com/aphyr/riemann-tools'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Utilities which submit events to Riemann.'
  s.description = 'Utilities which submit events to Riemann.'
  s.license = 'MIT'

  s.add_dependency 'riemann-client', '>= 0.2.2'
  s.add_dependency 'trollop', '>= 1.16.2'
  s.add_dependency 'json'

  s.files = FileList['lib/**/*', 'bin/*', 'LICENSE', 'README.markdown'].to_a
  s.executables |= Dir.entries('bin/')
  s.require_path = 'lib'
  s.has_rdoc = true

  s.required_ruby_version = '>= 1.8.7'
end

Gem::PackageTask.new gemspec do |p|
end

RDoc::Task.new do |rd|
  rd.main = 'Riemann Tools'
  rd.title = 'Riemann Tools'
  rd.rdoc_dir = 'doc'

  rd.rdoc_files.include('lib/**/*.rb')
end
