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

require "mysql"
require "forwardable"

module Datamith
  class Database # :nodoc:
    extend Forwardable
    def_delegators :@co, :list_tables
    def_delegators :@co, :list_fields

    def initialize( config, mode=:read )
      @co = Mysql.new config[ 'host' ], config[ 'user' ], config[ 'passwd' ], config[ 'database' ]
      unless @co
        puts "Can't connect to #{host}. Exiting."
        exit 1
      end

      @mode = mode
    end

    def query( query )
      return false if @mode == :read

      begin
        @co.query query
        if @co.error.length > 0
          puts @co.error
        end
      rescue Mysql::Error
        puts "\n\nA Mysql error stop the process!\n"
        puts $!
        puts "\nThe query was :"
        puts query
        exit 1
      end

      return @co.insert_id
    end

    def get( table_name )
      return false if @mode == :write

      attrs = []
      res = @co.query( "select * from #{e table_name}" )
      while (h = res.fetch_hash)
        h.key_strings_to_symbols!
        attrs << h 
      end
      return attrs
    end

    # check if a record with the same primary key exists
    def record_exists?( table, id, id_name="id" )
      id ||= 'null'
      query = sprintf( "select * from %s where %s = %s", e( table ), e( id_name ), e( id ) )
      res = @co.query query
      return ( res.num_rows == 0 ? false : true )
    end

    def get_record( table, id, id_name="id" )
      res = @co.query sprintf( "select * from %s where %s = %s", e( table ), e( id_name ), e( id ) )
      return res.fetch_hash
    rescue Mysql::Error
      return false
    end

    # check if a records with all same attributes exists
    def match( table, attributes )
      conds = ""
      attributes.each { |attr,val|
        conds << sprintf( "%s = %s and ", e(attr), val )
      }

      conds.gsub! /and $/, ''
      query = sprintf( "select * from %s where %s", table, conds )
      res = @co.query query

      return ( res.num_rows == 0 ? false : true )
    end

    def match_field( table, pk_value, field, value, pk_name="id" )
      query = sprintf( "select %s from %s where %s = %s", field, table, pk_name, e(pk_value) )
      res = @co.query query

      return res.fetch_hash[ field.to_s ] == value
    end
  end
end
