#!/usr/bin/env ruby
# License and Copyright {{{
# Copyright (c) 2003 Thomas Hurst <freaky@aagh.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# }}}

# PHP serialize() and unserialize() workalikes
#  First Released: 2003-06-02 (1.0.0)
#  Prev Release: 2003-06-16 (1.0.1), by Thomas Hurst <tom@hur.st>
#  This Release: 2004-09-17 (1.0.2), by Thomas Hurst <tom@hur.st>
#                Switch all {}'s to explicit Hash.new's.
#
#  These two methods should, for the most part, be functionally identical
#  to the respective PHP functions;
#   http://www.php.net/serialize, http://www.php.net/unserialize
#
#
#  string = PHP.serialize(mixed var[, bool assoc])
#   Returns a string representing the argument in a form PHP.unserialize
#   and PHP's unserialize() should both be able to load.
#
#   Array, Hash, Fixnum, Float, True/FalseClass, NilClass, String and Struct
#   are supported; as are objects which support the to_assoc method, which
#   returns an array of the form [['attr_name', 'value']..].  Anything else
#   will raise a TypeError.
#
#   If 'assoc' is specified, Array's who's first element is a two value
#   array will be assumed to be an associative array, and will be serialized
#   as a PHP associative array rather than a multidimensional array.
#
#
#
#  mixed = PHP.unserialize(string serialized, [hash classmap, [bool assoc]])
#   Returns an object containing the reconstituted data from serialized.
#
#   If a PHP array (associative; like an ordered hash) is encountered, it
#   scans the keys; if they're all incrementing integers counting from 0,
#   it's unserialized as an Array, otherwise it's unserialized as a Hash.
#   Note: this will lose ordering.  To avoid this, specify assoc=true,
#   and it will be unserialized as an associative array: [[key,value],...]
#
#   If a serialized object is encountered, the hash 'classmap' is searched for
#   the class name (as a symbol).  Since PHP classnames are not case-preserving,
#   this *must* be a .capitalize()d representation.  The value is expected
#   to be the class itself; i.e. something you could call .new on.
#
#   If it's not found in 'classmap', the current constant namespace is searched,
#   and failing that, a new Struct(classname) is generated, with the arguments
#   for .new specified in the same order PHP provided; since PHP uses hashes
#   to represent attributes, this should be the same order they're specified
#   in PHP, but this is untested.
#
#   each serialized attribute is sent to the new object using the respective
#   {attribute}=() method; you'll get a NameError if the method doesn't exist.
#
#   Array, Hash, Fixnum, Float, True/FalseClass, NilClass and String should
#   be returned identically (i.e. foo == PHP.unserialize(PHP.serialize(foo))
#   for these types); Struct should be too, provided it's in the namespace
#   Module.const_get within unserialize() can see, or you gave it the same
#   name in the Struct.new(<structname>), otherwise you should provide it in
#   classmap.
#
# Note: StringIO is required for unserialize(); it's loaded as needed

module PHP
	def PHP.serialize(var, assoc = false) # {{{
		s = ''
		case var
			when Array
				s << "a:#{var.size}:{"
				if assoc and var.first.is_a?(Array) and var.first.size == 2
					var.each { |k,v|
						s << PHP.serialize(k) << PHP.serialize(v)
					}
				else
					var.each_with_index { |v,i|
						s << "i:#{i};#{PHP.serialize(v)}"
					}
				end

				s << '}'

			when Hash
				s << "a:#{var.size}:{"
				var.each do |k,v|
					s << "#{PHP.serialize(k)}#{PHP.serialize(v)}"
				end
				s << '}'

			when Struct
				# encode as Object with same name
				s << "O:#{var.class.to_s.length}:\"#{var.class.to_s.downcase}\":#{var.members.length}:{"
				var.members.each do |member|
					s << "#{PHP.serialize(member)}#{PHP.serialize(var[member])}"
				end
				s << '}'

			when String
				s << "s:#{var.length}:\"#{var}\";"

			when Fixnum # PHP doesn't have bignums
				s << "i:#{var};"

			when Float
				s << "d:#{var};"

			when NilClass
				s << 'N;'

			when FalseClass, TrueClass
				s << "b:#{var ? 1 :0};"

			else
				if var.respond_to?(:to_assoc)
					v = var.to_assoc
					# encode as Object with same name
					s << "O:#{var.class.to_s.length}:\"#{var.class.to_s.downcase}\":#{v.length}:{"
					v.each do |k,v|
						s << "#{PHP.serialize(k.to_s)}#{PHP.serialize(v)}"
					end
					s << '}'
				else
					raise TypeError, "Unable to serialize type #{var.class}"
				end
		end

		s
	end # }}}

	def PHP.unserialize(string, classmap = nil, assoc = false) # {{{
		require 'stringio'
		string = StringIO.new(string)
		def string.read_until(char)
			val = ''
			while (c = self.read(1)) != char
				val << c
			end
			val
		end

		classmap ||= Hash.new

		do_unserialize(string, classmap, assoc)
	end

	def PHP.do_unserialize(string, classmap, assoc)
		val = nil
		# determine a type
		type = string.read(2)[0,1]
		case type
			when 'a' # associative array, a:length:{[index][value]...}
				count = string.read_until('{').to_i
				val = vals = Array.new
				count.times do |i|
					vals << [do_unserialize(string, classmap, assoc), do_unserialize(string, classmap, assoc)]
				end
				string.read(1) # skip the ending }

				unless assoc
					# now, we have an associative array, let's clean it up a bit...
					# arrays have all numeric indexes, in order; otherwise we assume a hash
					array = true
					i = 0
					vals.each do |key,value|
						if key != i # wrong index -> assume hash
							array = false
							break
						end
						i += 1
					end

					if array
						vals.collect! do |key,value|
							value
						end
					else
						val = Hash.new
						vals.each do |key,value|
							val[key] = value
						end
					end
				end

			when 'O' # object, O:length:"class":length:{[attribute][value]...}
				# class name (lowercase in PHP, grr)
				len = string.read_until(':').to_i + 3 # quotes, seperator
				klass = string.read(len)[1...-2].capitalize.intern # read it, kill useless quotes

				# read the attributes
				attrs = []
				len = string.read_until('{').to_i

				len.times do
					attr = (do_unserialize(string, classmap, assoc))
					attrs << [attr.intern, (attr << '=').intern, do_unserialize(string, classmap, assoc)]
				end
				string.read(1)

				val = nil
				# See if we need to map to a particular object
				if classmap.has_key?(klass)
					val = classmap[klass].new
				elsif Struct.const_defined?(klass) # Nope; see if there's a Struct
					classmap[klass] = val = Struct.const_get(klass)
					val = val.new
				else # Nope; see if there's a Constant
					begin
						classmap[klass] = val = Module.const_get(klass)

						val = val.new
					rescue NameError # Nope; make a new Struct
						classmap[klass] = val = Struct.new(klass.to_s, *attrs.collect { |v| v[0].to_s })
					end
				end

				attrs.each do |attr,attrassign,v|
					val.__send__(attrassign, v)
				end

			when 's' # string, s:length:"data";
				len = string.read_until(':').to_i + 3 # quotes, separator
				val = string.read(len)[1...-2] # read it, kill useless quotes

			when 'i' # integer, i:123
				val = string.read_until(';').to_i

			when 'd' # double (float), d:1.23
				val = string.read_until(';').to_f

			when 'N' # NULL, N;
				val = nil

			when 'b' # bool, b:0 or 1
				val = (string.read(2)[0] == ?1 ? true : false)

			else
				raise TypeError, "Unable to unserialize type '#{type}'"
		end

		val
	end # }}}
end


if $0 == __FILE__
	require 'tempfile'

	class Foo # :nodoc:
		attr_accessor :foo, :bar, :wibble
		def initialize
			@foo    = 'a'
			@bar    = 'b'
			@wibble = 'c'
		end

		def to_assoc
			[['foo', @foo], ['bar', @bar], ['wibble', @wibble]]
		end
	end

	puts "The following should all be equivilent, taking into account our limitations."
	puts " 1. Is the original Ruby data structure."
	puts " >> Is our generated serialized string."
	puts " << Is the serialized string after PHP's eaten it."
	puts " 2. Is the reconstructed Ruby data structure"
	puts "--"
	T = Struct.new(:structures,:ass)
	[
		{5 => nil, "foo" => 1, "nana" => ["x","y","z"], 3 => false, "bar" => 2.4, 4 => true},
		T.new('Kick','Dude!'),
		['a','b','c',['z','y','x'],{'hash' => 'smoke'},"\"\\''\""],
		"He said \"Damnit, I'm lame\", and then I kicked his ass.",
		Foo.new
	].each do |v|
		print " 1. "
		p v
		out = PHP.serialize(v)

		tmp = Tempfile.new('php')
		tmp.print(out)
		tmp.close

		puts " >> #{out}"
		ret = `php -r 'echo serialize(unserialize(join("\n", file("#{tmp.path}"))));'`
		puts " << #{ret}"
		print " 2. "
		p PHP.unserialize(ret)
		puts " == #{out == ret ? 'Perfect!' : 'Differ!'}", ''
		tmp.close!
	end
end

