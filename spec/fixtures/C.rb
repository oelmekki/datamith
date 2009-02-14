class C < Datamith::Converter
  attr_reader :new_attrs

  @@old_table = "c"
  @@new_table = "new_c"

  def run
    append
    convert :string, :name
    convert :string, :gender, :sex
    convert :datetime_to_timestamp, :date
  end
end

