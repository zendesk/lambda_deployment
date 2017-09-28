require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bump/tasks'

RuboCop::RakeTask.new
RSpec::Core::RakeTask.new
task default: %i[rubocop spec]
