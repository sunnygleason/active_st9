require "bundler/setup"
require "bundler/gem_tasks"

desc "Run the test suite"
task :test do
  system %{bundle exec ruby -Itest -e "Dir['test/*test.rb'].each { |f| require File.basename(f) }"}
end

task :default => :test

Dir["lib/tasks/*.rake"].each do |rake|
  load rake
end
