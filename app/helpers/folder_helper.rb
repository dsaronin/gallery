module FolderHelper

  def picture_sub_folders
    picpath = File.join(
      Rails.configuration.photo_path,
      Rails.configuration.photo_base
    ) 

    return Dir.children( picpath ).select { |f| 
      File.directory?( File.join(picpath, f) ) 
    }
  end

  def picture_source_folders
    picpath = File.join(
      Rails.configuration.photo_path,
      Rails.configuration.photo_base
    ) 
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

  def file_to_path( folder )
    return File.join(
        Rails.configuration.photo_path,
        Rails.configuration.photo_base,
        folder,
        Rails.configuration.photo_source
     )    
  end

  def fn_to_dsc( f, dirpath )
    rx = Regexp.new( "^"+dirpath+"/" )
    return f.gsub(rx,"").gsub(/\.\w+$/,"").gsub(/_(sm|lg)$/,"")
  end


end  # module
