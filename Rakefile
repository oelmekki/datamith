require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'yaml'

ROOT = File.dirname(__FILE__)
$:.unshift( "#{ROOT}/libs" )

File.open( File.expand_path( File.join(ROOT, "config.yml" ) ) ) do |confile|
  @config  = YAML::load( confile )
end

def default_config?
  default = { 'host' => 'host', 'user' => 'user', 'passwd' => 'password', 'database' => 'database_name' }
  @config[ 'database_from' ] == default and @config[ 'database_to' ] == default
end

def intersects_tables_to_convert( array )
  selected = @config[ 'tables_to_convert' ]
  return array if ( selected.nil? or selected.empty? )
  selected & array
end

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

if default_config?
  Kernel.at_exit do
    puts "\nYou may automatically generate rule files if you fullfill config.yml first."
  end
else
  namespace :tables do

    desc "Generate table files for all the tables"
    task :populate do
      require "#{ROOT}/libs/Runner.rb"
      d = Datamith::Runner.new
      intersects_tables_to_convert( d.old_tables ).each do |old_table|
        d.generate_table_file( old_table )
      end
    end

    namespace :generate do
      begin
        require "#{ROOT}/libs/Runner.rb"
        d = Datamith::Runner.new
        intersects_tables_to_convert( d.old_tables ).each do |old_table|
          desc "Generate table file for #{old_table}"
          task old_table.intern do
            d.generate_table_file( old_table )
          end
        end
      rescue
        Kernel.at_exit do
          puts "\nErrors while trying to read table names. Is config.yml ok?"
        end
      end
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

