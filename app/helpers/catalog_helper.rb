  require "shellwords"

module CatalogHelper

  def make_picpath()
    return File.join(
      Rails.configuration.photo_path,
      Rails.configuration.photo_base
    ) 
  end

  def picture_sub_catalogs
    picpath = make_picpath
    return Dir.children( picpath ).select { |f| 
      File.directory?( File.join(picpath, f) ) 
    }
  end

  def picture_source_catalogs
    picpath = make_picpath
    picglob = File.join(
      picpath,
      "**",
      Rails.configuration.photo_source
    ) 

    list = Dir[picglob]
    selects = list.map {|f|
      f.gsub( Regexp.new( picpath + "/" ), "" ).gsub( Regexp.new( "/" + Rails.configuration.photo_source), "")
    }
    return selects
  end

  def file_to_path( catalog )
    return File.join(
        Rails.configuration.photo_path,
        Rails.configuration.photo_base,
        catalog,
        Rails.configuration.photo_source
     )    
  end

  def fn_to_dsc( f, dirpath )
    rx = Regexp.new( "^"+dirpath+"/" )
    return f.gsub(rx,"").gsub(/\.\w+$/,"").gsub(/_(sm|lg)$/,"")
  end

  def filepath_to_fn( fp )
    picpath = "^" + make_picpath + "/"
    pprex = Regexp.new( picpath )
    return fp.gsub(pprex,"")
  end 

  def public_fn(fn)
    return File.join( '..', 'photos', fn )
  end

  def shell_escaped_path(path)
    Shellwords.escape(path.to_s)
  end

end  # module
