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
      Datamith::Runner.const_set( "DUMP", dump )
      @old_db = Database.new config[ 'database_from' ]
      @new_db = Database.new( config[ 'database_to' ], :write )
    end

    def run() # :nodoc:
      # find the tables files
      files = Dir.glob( ROOT + "/tables/*" ).sort
      p ROOT # DEBUG
      files.each do |file|
        if ( converter_class = load_rules file )

          # get the old records
          old_records = @old_db.get converter_class.old_table

          old_records.each do |attrs|
            converter = converter_class.new attrs, @old_db, @new_db
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
  end
end
