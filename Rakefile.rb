require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'find'
require 'rake'

# Don't include resource forks in tarballs on Mac OS X.
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'
ENV['COPYFILE_DISABLE'] = 'true'

# Gemspec
gemspec = Gem::Specification.new do |s|
  s.rubyforge_project = 'riemann-tools'

  s.name = 'riemann-tools'
  s.version = '0.2.14'
  s.author = 'Kyle Kingsbury'
  s.email = 'aphyr@aphyr.com'
  s.homepage = 'https://github.com/aphyr/riemann-tools'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Utilities which submit events to Riemann.'
  s.description = 'Collection of utilities which submit events to Riemann.'
  s.license = 'MIT'

  s.add_runtime_dependency 'riemann-client', '~> 1.0'
  s.add_runtime_dependency 'optimist', '~> 3.0', '>= 3.0.0'
  s.add_runtime_dependency 'json', '>= 1.8'

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

desc 'Update CHANGELOG'
task :changelog do
  begin
    require 'github_changelog_generator'
  rescue LoadError
    'Install the GitHub Changelog Generator - gem install github_changelog_generator'
  end
  sh 'github_changelog_generator -u riemann -p riemann-tools'
end

desc 'Recursively build all gems'
task :rbuild do
  Dir.glob("tools/**") do |dir|
    Dir.chdir(dir)
    sh 'rake gem'
    Dir.chdir("../..")
  end
end


