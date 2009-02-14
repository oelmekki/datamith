class A < Datamith::Converter
  @@old_table = "compte"
  @@new_table = "tl_member"
  @@skip += %w( 62 67 )

  def run
  end
end
