class B < Datamith::Converter
  attr_reader :new_attrs

  @@old_table = "b"
  @@new_table = "new_b"
  @@skip += %w( 2 )

  def run
    convert :integer, :id
    convert :string, :name
    convert :string, :gender, :sex
    convert :datetime_to_timestamp, :date
    convert :timestamp_to_datetime, :tstamp
  end

  def self.skipped
    @@results[ :skipped ]
  end

  def self.inserted
    @@results[ :inserted ]
  end

  def self.updated
    @@results[ :updated ]
  end

  def config attr, value
    @@config[ attr ] = value
  end
end
