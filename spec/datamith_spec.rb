#!/usr/bin/env ruby
require 'spec'
require File.expand_path( File.join( File.dirname(__FILE__), 'spec_helper' ) )
require 'Runner'

describe Datamith::Runner do
  before( :each ) do
    Datamith::Converter::init()
  end

  def mock_db( stubs={} )
    @db ||= mock( "database", stubs )
  end

  it "should connect to dbs" do
    db = mock_db( :get => [1, 2, 3 ], :record_exists? => true, :match => true )
    Datamith::Database.stub!(:new).and_return( mock_db )

    Datamith::Database.should_receive(:new).twice
    Datamith::Runner.new
  end

  it "should load the table rules" do
    db = mock_db( :get => [1, 2, 3 ], :record_exists? => true, :match => true )
    Datamith::Database.stub!(:new).and_return( mock_db )
    file = "#{SPEC_ROOT}/fixtures/A.rb"
    Dir.stub!(:glob).and_return( [file] )

    d = Datamith::Runner.new
    d.run
    lambda { A }.should_not raise_error
  end

  it "should generate the table files" do
    db = mock_db( :list_fields => (o = Object.new) )
    Datamith::Database.stub!(:new).and_return( mock_db )
    o.stub!( :fetch_fields ).and_return( [ mock( "field", :name => 'field_one', :is_num? => true ), mock( "field", :name => 'field_two', :is_num? => false ) ] )
    Dir.stub!(:new).and_return( d = Dir.new )
    d.stub!( :entries ).and_return( [] )
    File.stub!( :new ).and_return( file = mock( "file", :puts => true, :close => true ) )
    
    d = Datamith::Runner.new
    File.should_receive( :read ).and_return( str = "__CLASS_NAME__ __TABLE__ __CONVERTS__" )
    str.should_receive( :gsub! ).exactly( 3 ).times
    #str.should_receive( :gsub! ).with( '/__CLASS_NAME__/', 'TableOne' )
    #str.should_receive( :gsub! ).with( /__TABLE__/, 'table_one' )
    #str.should_receive( :gsub! ).with( /__CONVERT__/, /convert :integer, :field_one.*?convert :string, :field_two/ )
    file.should_receive( :puts )
    file.should_receive( :close )
    d.generate_table_file( 'table_one' )
  end
end
