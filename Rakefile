require "bundler/gem_tasks"

require 'rake/testtask'
require 'bump/tasks'
#Bump.tag_by_default = true

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc 'Run tests'
task :default => :test

task :newrelease do
  sh "bump patch --tag"
  sh "rake release"
end
