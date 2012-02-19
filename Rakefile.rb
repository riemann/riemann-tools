require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'find'
 
# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'
 
# Gemspec
gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'reimann-tools'
 
  s.name = 'reimann-tools'
  s.version = '0.0.1'
  s.author = 'Kyle Kingsbury'
  s.email = 'aphyr@aphyr.com'
  s.homepage = 'https://github.com/aphyr/reimann-tools'
  s.platform = Gem::Platform::RUBY
  s.summary = 'HTTP dashboard for the distributed event system Reimann.'

  s.add_dependency 'reimann-client', '>= 0.0.4'
  s.add_dependency 'trollop', '>= 1.16.2'

  s.files = FileList['lib/**/*', 'bin/*', 'LICENSE', 'README.markdown'].to_a
  s.executables |= Dir.entries('bin/')
  s.require_path = 'lib'
  s.has_rdoc = true
 
  s.required_ruby_version = '>= 1.9.1'
end

Gem::PackageTask.new gemspec do |p|
end
 
RDoc::Task.new do |rd|
  rd.main = 'Reimann Tools'
  rd.title = 'Reimann Tools'
  rd.rdoc_dir = 'doc'
 
  rd.rdoc_files.include('lib/**/*.rb')
end
