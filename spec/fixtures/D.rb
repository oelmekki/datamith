class D < Datamith::Converter
  attr_reader :new_attrs
  @@old_table = "d"
  @@new_table = "new_d"

  def run
    appended_FK :c_id, :new_c
    convert :int, :c_id
  end
end


