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

module Datamith
  # == Presentation
  #
  # The converter is the core of the framework. Each file of rules should be
  # derivated from it.
  #
  # == Initialization
  #
  # There are a few variables you can use to initialize the converter.
  #
  # Every rule file must define <tt>@@old_table</tt> and <tt>@@new_table</tt>, to indicate which tables
  # to process.
  #
  # You can use <tt>@@skip</tt> to determine which records to skip ( based on the value of the primary
  # key of the old table ). <tt>@@skip</tt> must be an array of strings.
  #
  # You can tell the name of the old and new primary keys in <tt>@@old_primary_key</tt> and 
  # <tt>@@new_primary_key</tt>. This must be a symbol. By default, each one is <tt>:id</tt> .
  #
  # Finaly, you can tweak the behaviour of the converter with <tt>@@config</tt>. It's a hash accepting
  # those three options :
  # :insert : boolean. Allow insertions ( default : true )
  # :update : boolean. Allow updates ( default : true )
  # :on_error : :warn, :silent or :abort ( default : :warn )
  #
  # == Conversion
  #
  # The main method to be defined in a derivated class is #run(). While in #run(),
  # you can use #convert() to specify which field should be converted and how.
  #
  # You can set the converter in append mode by putting <tt>append</tt> on top of the rules. Doing so,
  # the primary key won't be preserved and the last insert value will be associated to it in the appended
  # array.
  #
  # You may then retrive this value in a further converter using #appended_PK .
  #
  # === Straight conversion
  #
  # We have a product table like this :
  #
  #   `product` (
  #     `id` int(10) unsigned NOT NULL auto_increment,
  #     `name` varchar(255) NOT NULL default '',
  #     `price` int(10) unsigned NOT NULL default '0',
  #     PRIMARY KEY ( `id` )
  #   )
  #
  # We have kept this structure in our new database ( but with a plural table name ), so we only want to pass the value as-is.
  #
  #   class Product < Converter
  #     @@old_table = "product"
  #     @@new_table = "products"
  #
  #     def run
  #       convert :int, :id
  #       convert :string, :name
  #       convert :int, :price
  #     end
  #   end
  #
  # The first argument for convert is the type of the data. The accepted data types are : <tt>:int</tt> ( or <tt>:integer</tt> ), <tt>:string</tt>, <tt>:date</tt>, <tt>:datetime</tt>, <tt>:timestamp</tt>, <tt>:datetime_to_timestamp</tt> or <tt>:timestamp_to_datetime</tt>.
  #
  # If the new database already has a record with the same primary key value, it will be updated ( given that it has changed and that update hasn't be explicitly forbidden ).
  #
  # === Changing field name
  #
  # Let's say now that we want to change the <tt>price</tt> field name into <tt>pricing</tt>, the convert rule would have been :
  #  convert :int, :price, :pricing
  #
  # === Converting datetime to timestamp and timestamp to datetime
  #
  # Now, let's say we have a datetime field, `created_at` and that we want it to be a timestamp rather :
  #  convert :datetime_to_timestamp, :created_at
  #
  # === Skipping records
  #
  # You can use <tt>@@skip</tt> to determine which records to skip ( based on the value of the primary
  # key of the old table ). <tt>@@skip</tt> must be an array of strings.
  #
  #   class Product < Converter
  #     @@old_table = "product"
  #     @@new_table = "products"
  #     @@skip = %w( 12 18 )
  #
  #     def run
  #       convert :int, :id
  #       convert :string, :name
  #       convert :int, :price, :pricing
  #       convert :datetime_to_timestamp, :created_at
  #     end
  #   end
  #
  # === Appending
  #
  # If you want a record to be appended, you can use the append mode. This mechanism allow to insert a row and remember it's primary value, so you can then modify some associated record accordingly.
  #
  # Let's say you want to import users from a database to an other database which is already full of users. There are also some Posts, and the posts table has a user_id field. This can be done like this :
  #
  #   # tables/User.rb
  #   class User < Converter
  #     @@old_table = "users"
  #     @@new_table = "users"
  #
  #     def run
  #       append
  #       convert :int, :id
  #       convert :string, :name
  #       convert :datetime, :created_at
  #     end
  #   end
  #  
  #   # tables/Post.rb
  #   class Post < Converter
  #     @@old_table = "posts"
  #     @@new_table = "posts"
  #
  #     def run
  #       appended_FK :user_id, :user
  #       convert :int, :id
  #       convert :int, :user_id
  #       convert :string, :text
  #     end
  #   end
  #  
  # The converter will check the old user_id value and find to which new inserted user id match.
  #
  # This way, all the user of the first database will be inserted as new. This may not be what you want. If the two databases are the same, but with some differing point, you can specify a set records to be appended, will the other are treated normally.
  #
  # This is done by passing a Proc object will be used as a condition :
  #
  #   # tables/User.rb
  #   class User < Converter
  #     @@old_table = "users"
  #     @@new_table = "users"
  #
  #     def run
  #       append :condition => Proc.new { |old,new| ( 100..120 ).include?( old[ :id ] ) }
  #       convert :int, :id
  #       convert :string, :name
  #       convert :datetime, :created_at
  #     end
  #   end
  #
  # The Proc object must take two arguments, which will be fill with two hashes representing the old row and the new one. The Proc must return a boolean. Record will be appended if true.
  #
  # === Custom conversion
  #
  # You can write your own conversion method to tweak further. You simply have to add it in you conversion class and call it from #run(). The old attributes are accesible in the @old_attrs hash and the new ones in @new_attrs :
  #
  #   # tables/User.rb
  #   class User < Converter
  #     @@old_table = "users"
  #     @@new_table = "users"
  #
  #     def run
  #       append :condition => Proc.new { |old,new| ( 100..120 ).include?( old[ :id ] ) }
  #       convert :int, :id
  #       convert_name
  #       convert :datetime, :created_at
  #     end
  #
  #     def convert_name
  #       @new_attrs[ :name ] = @old_attrs[ :firstname ] + ' ' + @old_attrs[ :lastname ]
  #     end
  #   end

  class Converter
    def self.init() # :nodoc:
      @@old_primary_key = :id
      @@new_primary_key = :id
      @@results         = { :nochange => 0, :skipped => 0, :updated => 0, :inserted => 0 }

      # this array can contains some value of the primary key that will be skipped
      @@skip = Array.new

      # determine what can be done. To be overloaded in the child classes.
      # :on_error can be one of :warn, :silent or :abort
      @@config = { :insert => true, :update => true, :on_error => :warn }
    end
   
    init()

    def initialize( attrs, old_db, new_db ) # :nodoc:
      @old_db     = old_db
      @new_db     = new_db
      @old_attrs  = attrs
      @new_attrs  = Hash.new
    end

    # abstract method to be replaced by the table conversion rules in child class.
    def run()
      puts "You either called the abstract class directly or didn\'t feeded the run method. This is bad."
      exit 1
    end

    # The convert() method is aimed to be used in the run() method of a derivated class.
    # Its goal is to perform the actual conversion of the old field of a row to the new one.
    # It must take the type of data as first argument, then the name of the old field and optionally
    # the new name if it has to be changed.
    #
    # * type : one of <tt>:int</tt> ( or <tt>:integer</tt> ), <tt>:string</tt>, <tt>:date</tt>, <tt>:datetime</tt>, <tt>:timestamp</tt>, <tt>:datetime_to_timestamp</tt> or <tt>:timestamp_to_datetime</tt>
    # * old_name : the name of the field to be converted
    # * new_name ( optional ) : the name of the new field
    #
    # <tt>:datetime_to_timestamp</tt> convert, as the name say, from datetime to timestamp and <tt>:timestamp_to_datetime</tt> do the opposite.
    def convert( type, old_name, new_name=nil )
      new_name ||= old_name 

      case type
      when :datetime_to_timestamp
        @new_attrs[ new_name ] = sprintf( '%s', DateTime.tstampize( @old_attrs[ old_name ] ) )
        return

      when :timestamp_to_datetime
        time = Time.at( @old_attrs[ old_name ].to_i )
        @new_attrs[ new_name ] = time.strftime( '"%Y-%m-%d %H:%M:%S"' )
        return

      when :string, :date, :datetime
        format = '"%s"'
        @old_attrs[ old_name ] = '' if @old_attrs[ old_name ] == nil

      when :int, :integer, :timestamp
        case @old_attrs[ old_name ] 
        when nil
          format = '"%s"'
          @old_attrs[ old_name ] = '' 
        when /^@/  # mysql var
          format = '%s'
        else
          format = '%s'
          @old_attrs[ old_name ] = @old_attrs[ old_name ].to_i.to_s # in case of zerofill
        end

      else
        throw Exception.new( "Unknown type: " + type.inspect )
      end

      @new_attrs[ new_name ] = sprintf( format, e( @old_attrs[ old_name ] ) )
    end

    # When append is called, the inserted primary key will be recorded and
    # will be retrievable with Converter#appended_FK. This let you keeping track of the foreign keys.
    #
    # An optional hash may be passed as :
    #
    # <tt>append :condition => Proc</tt>
    #
    # The Proc object must accept two arguments, old and new, which will be fill with the hashes of the old and the new values of the proceeded row. The block should return true or false, which determine if the row must be in append mode or not.
    def append( arg=nil )
      @condition_proc = ( arg ? arg[ :condition ] : Proc.new { |old,new| true } )
      Datamith::Runner::appended[ self.class.new_table ] ||= Hash.new
    end

    # Retrieve the new value of a foreign key.
    #
    # key_name : the name of the foreign key
    # table_name : the name of the table which the primary has changed
    def appended_FK( key_name, table_name )
      if Datamith::Runner::appended[ table_name.to_s ][ @old_attrs[ key_name ].to_s ]
        @old_attrs[ key_name ] = Datamith::Runner::appended[ table_name.to_s ][ @old_attrs[ key_name ].to_s ]
      end
    end

    def query() # :nodoc:
      primary_value = @old_attrs[ self.class.old_primary_key ]

      # there's no need to process any longer if the records has been asked to be skipped
      if @@skip.include? primary_value
        @@results[ :skipped ] += 1
          printf '_' unless Datamith::Runner::DUMP # skip requested by user
        return false
      end

      # if the record is in appended mode, jump to the query build
      unless Datamith::Runner::appended[ self.class.new_table ] and @condition_proc.call( @old_attrs, @new_attrs )

        # there already is a record with this value for primary key
        if @new_db.record_exists? self.class.new_table, primary_value, self.class.new_primary_key

          # skip records with no changes
          if @new_db.match self.class.new_table, @new_attrs
            @@results[ :nochange ] += 1
            printf '.' unless Datamith::Runner::DUMP  # no change
            return false
          end

          # the record has changed, build an update query
          update( primary_value )
          return
        end

      # append mode
      else
        @new_attrs.delete self.class.new_primary_key
      end

      inserted = insert( primary_value )

    end

    def self.old_table() # :nodoc:
      class_variable_get :@@old_table
    end

    def self.new_table() # :nodoc:
      class_variable_get :@@new_table
    end

    def self.old_primary_key() # :nodoc:
      class_variable_get :@@old_primary_key
    end

    def self.new_primary_key() # :nodoc:
      class_variable_get :@@new_primary_key
    end

    def self.skip() # :nodoc:
      class_variable_get :@@skip
    end

    def self.results() # :nodoc:
      res = sprintf "-- Inserted: %i, Updated: %i, No change: %i, Skipped: %i\n", @@results[ :inserted ], @@results[ :updated ], @@results[ :nochange ], @@results[ :skipped ]
      self.init
      res
    end

    protected

    def update( primary_value ) # :nodoc:
      setters = "set "

      @new_attrs.each { |attr,val|
        next if attr == self.class.new_primary_key
        setters << sprintf( "%s = %s,", e(attr.to_s), val )
      }

      unless @@config[ :update ]
        query_type_error :update
        return false
      end

      @@results[ :updated ] += 1
      query = sprintf( "update %s %s where %s = %s", e( self.class.new_table ), setters.chop, e(self.class.new_primary_key.to_s), e( primary_value ) )
      if Datamith::Runner::DUMP
        puts query
      else
        printf 'U'  # update
        @new_db.query query
      end
    end

    def insert( primary_value ) # :nodoc:

      # build the query
      fields, values = "", ""
      
      @new_attrs.each { |attr,val|
        fields << sprintf( "%s,", e(attr.to_s) )
        values << sprintf( "%s,", val )
      }

      unless @@config[ :insert ]
        query_type_error :insert
        return false
      end

      @@results[ :inserted ] += 1
      query = sprintf( "insert into %s( %s ) values( %s )", e( self.class.new_table.to_s ), fields.chop, values.chop )
      if Datamith::Runner::DUMP 
        puts query

        if Datamith::Runner::appended[ self.class.new_table ] and @condition_proc.call( @old_attrs, @new_attrs )
          mysql_var = "@#{self.class.new_table.to_s}_#{primary_value}"
          puts "set #{mysql_var} = last_insert_id()"
          Datamith::Runner::appended[ self.class.new_table ][ primary_value ] = mysql_var
        end
      else
        printf 'I' # insert
        inserted = @new_db.query  query
        if Datamith::Runner::appended[ self.class.new_table ] and @condition_proc.call( @old_attrs, @new_attrs )
          Datamith::Runner::appended[ self.class.new_table ][ primary_value ] = inserted
        end
      end
    end

    def query_type_error( type ) # :nodoc:
      printf "%s: %s explicitly forbidden.\n", @@config[ :on_error ].to_s, type.to_s if @@config[ :on_error ] != :silent and not Datamith::Runner::DUMP
      exit 1 if @@config[ :on_error ] == :abort
    end
  end
end

