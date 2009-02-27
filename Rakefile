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

namespace :tables do

  desc "Generate table files for all the tables of the source database"
  task :populate do
    require "#{ROOT}/libs/Runner.rb"
    d = Datamith::Runner.new
    d.old_tables.each do |old_table|
      d.generate_table_file( old_table )
    end
  end

  namespace :generate do
    begin
      require "#{ROOT}/libs/Runner.rb"
      d = Datamith::Runner.new
      d.old_tables.each do |old_table|
        desc "Generate table file for #{old_table}"
        task old_table.intern do
          d.generate_table_file( old_table )
        end
      end
    rescue
    end
  end
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

