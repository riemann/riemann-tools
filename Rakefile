require 'riemann/tools/version'

require 'bundler/gem_tasks'

require 'github_changelog_generator/task'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'riemann'
  config.project = 'riemann-tools'
  config.exclude_labels = ['skip-changelog']
  config.future_release = Riemann::Tools::VERSION
end

desc 'Recursively build all gems'
task :rbuild do
  Dir.glob("tools/**") do |dir|
    Dir.chdir(dir)
    sh 'rake gem'
    Dir.chdir("../..")
  end
end
