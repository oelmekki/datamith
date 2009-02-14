require "digest/sha1"

class Compte < Converter
  include Digest
  @@old_table = "compte"
  @@new_table = "tl_member"
  @@skip += %w( 62 67 )

  def run
    convert :int, "id_compte", "id"
    convert :string, "courriel", "email"
    convert :string, "nom", "firstname"
    convert :datetime, "date_dernier_acces", "tstamp"
    convert_type_compte
    convert_motdepasse
    convert_supprime
    convert :string, "courriel", "username"
    convert :string, "telephone", "phone"
    convert_b_supprime
    convert :int, "cree_par_id", "pid"
    add_login_true
  end

  protected

  def convert_motdepasse
    @new_attrs[ 'password' ] = sprintf( '"%s"', SHA1.hexdigest( @old_attrs[ 'motdepasse' ] ) )
  end

  def convert_supprime
    @new_attrs[ 'disable' ] = '1' if @old_attrs[ 'supprime' ] == '1'
  end

  def add_login # courriel
    @new_attrs[ 'username' ] = sprintf( "'%s'", @old_attrs[ 'courriel' ] )
  end

  def convert_type_compte
    case @old_attrs[ 'type_compte' ]
      when '0': @new_attrs[ 'groups' ] = sprintf( "'%s'", 'a:1:{i:0;s:1:"1";}' )
      when '1': @new_attrs[ 'groups' ] = sprintf( "'%s'", 'a:1:{i:0;s:1:"2";}' )
    end
  end

  def convert_b_supprime
    @new_attrs[ 'disable' ] = sprintf( '"%s"', ( @old_attrs == 1 ? '1' : '' ) )
  end

  def add_login_true
    @new_attrs[ 'login' ] = 1
  end
end

