# Copyright (C) 2009 Olivier El Mekki <http://olivier-elmekki.com/>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

require 'pathname'
require 'yaml'
require 'utilities'
require 'Database'
require 'Converter'


module Datamith
  class Runner
    # this var is used to store the new primary key value
    # of a table when it is in append mode, so the reference in other
    # tables can be converted too.
    @@appended = Hash.new

    def initialize(dump=false) # :nodoc:
      confile = File.open( "#{ROOT}/config.yml" ) 
      config  = YAML::load( confile )
      confile.close

      Datamith::Runner.const_set( "DUMP", dump )
      @old_db = Database.new config[ 'database_from' ]
      @new_db = Database.new( config[ 'database_to' ], :write )
    end

    def run() # :nodoc:
      # find the tables files
      files = Dir.glob( ROOT + "/tables/*.rb" ).sort
      files.each do |file|
        if ( converter_class = load_rules file )

          # get the old records
          old_records = old_database.get converter_class.old_table

          old_records.each do |attrs|
            converter = converter_class.new attrs, old_database, new_database
            converter.run

            # run the query
            converter.query
          end

          puts  "\n" + Converter.results + "\n" * 2 
        end
      end
    end

    def self.appended() # :nodoc:
      @@appended
    end

    def self.appended=( val ) # :nodoc:
      @@appended = val
    end

    # find a list of the old tables.
    # Used in rake tables:generate.
    def old_tables() # :nodoc:
      old_database.list_tables()
    end

    def generate_table_file( table_name ) # :nodoc:
      table_dir = File.expand_path( File.join( File.dirname(__FILE__), '..', 'tables' ) )
      table_files = Dir.new( table_dir ).entries.select { |f| f =~ /(\d+_)?\w+\.rb/ }
      used_numbers = table_files.collect { |f| f =~ /^\d+/ && $&.to_i }.compact.sort
      table_classes = table_files.collect { |f| f =~ /(\d+_)?(.*?)\.rb$/; $2 }.compact
      class_name = table_name.camelize

      if table_classes.include? class_name
        puts "Error: #{class_name} already defined. Skipped."
        return false
      end

      number = ( ( used_numbers.last || 0 ) / 10 * 10 ) + 10
      filename = "#{number}_#{class_name}.rb"

      convert_string = ""
      old_database.list_fields( table_name ).fetch_fields.each do |field|
        convert_string << "    convert " + ( field.is_num? ? ":integer" : ":string" ) + ", :#{field.name}\n"
      end

      template = File.read( "#{File.dirname(__FILE__)}/templates/table.tpl" )
      template.gsub!( /__CLASS_NAME__/, class_name )
      template.gsub!( /__TABLE__/, table_name )
      template.gsub!( /__CONVERTS__/, convert_string.chomp )

      puts "generating #{filename}"
      f = File.new( "#{table_dir}/#{filename}", 'w' ) 
      f.puts template
      f.close
    end

    private

    # get the name of the class from the filename and require it
    # it can be prefixed by a number and an underscore to determine the order
    # e.g. :
    # User.rb, Account.rb, Post.rb ( Account will be parsed first, then Post, then User )
    # 10_Post.rb, 20_User.rb, 30_Account.rb
    #
    def load_rules( file )
      if file[/(.*?)\.rb$/]
        require_name = $1
        class_name = require_name.gsub( /.*\/(?:\d+_)*(.*?)$/, '\1' )
        if require( require_name ) and ( converter_class = Object.const_get( class_name ) )
          printf "----- %s -----\n", class_name 
          return converter_class
        end
      end

      return false
    end

    def old_database # :nodoc:
      @old_db
    end

    def new_database # :nodoc:
      @new_db
    end
  end
end
