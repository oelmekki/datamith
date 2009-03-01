ROOT = File.expand_path( File.join( File.dirname(__FILE__), '..' ) )
SPEC_ROOT = "#{ROOT}/spec"
$:.unshift( "#{ROOT}/libs" )
require 'utilities'

module Datamith
  class Runner
    def dump
      false
    end
  end
end

