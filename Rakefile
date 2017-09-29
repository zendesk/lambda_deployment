require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bump/tasks'

RuboCop::RakeTask.new

task :atomic_spec do
  sh 'bundle exec forking-test-runner spec --rspec --merge-coverage --quiet'
end

task default: %i[rubocop atomic_spec]
