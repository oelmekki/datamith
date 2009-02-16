#!/usr/bin/env ruby
require 'spec'
require File.expand_path( File.join( File.dirname(__FILE__), 'spec_helper' ) )
require 'Runner'
require 'Converter'

def mock_db( stubs={} )
  return mock( 'database', stubs )
end

def simple_run( class_str="B", stubs_old={}, stubs_new={} )
  load "#{SPEC_ROOT}/fixtures/#{class_str}.rb"
  class_name = Object.const_get( class_str )
  converter = class_name.new @old_attrs, mock_db( stubs_old ), mock_db( stubs_new )
  converter.run
  return converter
end

describe Datamith::Converter do

  before( :each ) do
    Datamith::Converter::init()

    @old_attrs = { :id      => "1", 
                   :name    => 'old_name', 
                   :gender  => 'i', 
                   :date    => '2009-02-12 15:35:13', 
                   :tstamp  => '1234450083' 
    }
  end

  describe "conversion" do
    it "should pass data when convert required" do
      b = simple_run
      b.new_attrs[ :name ].should == sprintf( '"%s"', @old_attrs[ :name ] )
    end

    it "should pass data changing the column name if specified" do
      b = simple_run
      b.new_attrs[ :sex ].should == sprintf( '"%s"', @old_attrs[ :gender ] )
    end

    it "should convert datetime to timestamp" do
      b = simple_run
      b.new_attrs[ :date ].should == '1234452913'
    end

    it "should convert timestamp to datetime" do
      b = simple_run
      b.new_attrs[ :tstamp ].should == '"2009-02-12 15:48:03"'
    end
  end

  it "should skip record if requested" do
    @old_attrs[ :id ] = "2"
    b = simple_run
    lambda { b.query }.should change( B, :skipped ).by(1)
  end

  it "should not insert new data if insert is false" do
    b = simple_run( "B", {}, { :record_exists? => false } )
    b.config :insert, false
    lambda { b.query }.should_not change( B, :inserted )
  end

  it "should not update data if update is false" do
    b = simple_run( "B", {}, { :record_exists? => true, :match => false } )
    b.config :update, false
    lambda { b.query }.should_not change( B, :updated )
  end

  it "should stock and retrieve new id if in append mode" do
    c = simple_run( "C", {}, { :record_exists? => false, :query => 10 } )
    c.query
    @old_attrs[ :c_id ] = 1
    d = simple_run( "D" )
    d.new_attrs[ :c_id ].should == "10"
  end
end
