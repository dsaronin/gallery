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


end  # module
