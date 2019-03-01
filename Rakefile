# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

FileList['lib/tasks/**.rake'].each do |task|
  load task
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*.rb']
  t.verbose = true
end

task default: :test
