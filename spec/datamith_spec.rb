#!/usr/bin/env ruby
require 'spec'
require File.expand_path( File.join( File.dirname(__FILE__), 'spec_helper' ) )
require 'Runner'
#require "#{SPEC_ROOT}/fixtures/test_table.rb"

describe Datamith::Runner do
  before( :each ) do
    Datamith::Converter::init()
    db = mock( "database", :get => [1, 2, 3 ], :record_exists? => true, :match => true )
    Datamith::Database.stub!(:new).and_return( db )
  end

  it "should connect to dbs" do
    Datamith::Database.should_receive(:new).twice
    Datamith::Runner.new
  end

  it "should load the table rules" do
    d = Datamith::Runner.new
    file = "#{SPEC_ROOT}/fixtures/A.rb"
    Dir.stub!(:glob).and_return( [file] )
    d.run
    lambda { A }.should_not raise_error
  end
end
