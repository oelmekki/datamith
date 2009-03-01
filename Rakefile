require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'yaml'

ROOT = File.dirname(__FILE__)
$:.unshift( "#{ROOT}/libs" )

require "#{ROOT}/libs/Runner.rb"

File.open( File.expand_path( File.join(ROOT, "config.yml" ) ) ) do |confile|
  @config  = YAML::load( confile )
end

def default_config?
  default = { 'host' => 'host', 'user' => 'user', 'passwd' => 'password', 'database' => 'database_name' }
  @config[ 'database_from' ] == default and @config[ 'database_to' ] == default
end

def runner mode=:exec
  return Datamith::Runner.new( mode ) if mode != :exec
  @runner ||= Datamith::Runner.new
end

def existing_rules
  runner.existing_rule_files.num_string_sort.collect { |f| f =~ /(\d+_)?(.*?)\.rb$/; $2 }.compact
end

def intersects_tables_to_convert( tables )
  selected = @config[ 'tables_to_convert' ]
  tables = selected & tables unless ( selected.nil? or selected.empty? )
  tables.reject { |table| existing_rules.include?( table.camelize ) }
end

def puts_at_exit( message )
  Kernel.at_exit do
    puts message
  end
end

task :default => :convert

desc "Lauch the conversion"
task :convert do
  runner.run()
end

namespace :convert do
  desc "Lauch the conversion and dump the sql instead of executing it"
  task :dump do
    runner( :dump ).run()
  end

  desc "Show a diff of the databases"
  task :diff do
    runner( :diff ).run()
  end
end

if default_config?
  puts_at_exit "\nYou may automatically generate rule files if you fullfill config.yml first."
else
  namespace :tables do

    all_tables = intersects_tables_to_convert( runner.old_tables )
    unless all_tables.empty?
      desc "Generate table files for all the tables"
      task :populate do
        all_tables.each do |old_table|
          runner.generate_table_file( old_table )
        end
      end
    end

    namespace :generate do
      begin
        intersects_tables_to_convert( runner.old_tables ).each do |old_table|
          desc "Generate table file for #{old_table}"
          task old_table.intern do
            runner.generate_table_file( old_table )
          end
        end
      rescue
        puts_at_exit "\nErrors while trying to read table names. Is config.yml ok?"
      end
    end

    desc "Display the order the rule files will be proceeded"
    task :order do
      existing_rules.each { |r| puts r }
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

