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

require "date"
require "mysql"

class DateTime
  # turn a DateTime to a timestamp
  def to_i()
    days_since_unix_epoch = self - ::DateTime.civil(1970)
    (days_since_unix_epoch * 86_400).to_i
  end

  # turn a date string to a timestamp
  def self.tstampize( value )
    begin
      ( ( value == "0000-00-00 00:00:00" or value == nil ) ? 0 : DateTime.parse( value ).to_i )
    rescue
      p value
      puts $!
      exit 1
    end
  end
end

def e( val )
  Mysql.escape_string( val.to_s )
end

class Hash
  # Recursively replace key names that should be symbols with symbols.
  def key_strings_to_symbols!
    r = Hash.new
    self.each_pair do |k,v|
      if (k.kind_of? String)
        v.key_strings_to_symbols! if v.kind_of? Hash and v.respond_to? :key_strings_to_symbols!
        r[k.to_sym] = v
      else
        v.key_strings_to_symbols! if v.kind_of? Hash and v.respond_to? :key_strings_to_symbols!
        r[k] = v
      end
    end
    self.replace(r)
  end
end

class String
  def camelize()
    self.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
end
