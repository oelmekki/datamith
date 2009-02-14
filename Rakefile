require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

ROOT = File.dirname(__FILE__)
$:.unshift( "#{ROOT}/libs" )

task :default => :convert

desc "Lauch the conversion"
task :convert do
  require "#{ROOT}/libs/Runner.rb"
  d = Datamith::Runner.new
  d.run()
end

desc "Lauch the conversion and dump the sql instead of executing it"
task :convert_dump do
  require "#{ROOT}/libs/Runner.rb"
  d = Datamith::Runner.new( true )
  d.run()
end

desc "Lauch specs"
Spec::Rake::SpecTask.new(:spec) do |task|
  task.spec_opts = ['--options', "\"#{ROOT}/spec/spec.opts\""]
  task.spec_files = FileList['spec/*_spec.rb']
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("README")
  rd.rdoc_files.include("libs/*.rb")
end

