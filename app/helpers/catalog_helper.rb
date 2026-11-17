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
    dirpath, _warning = resolve_catalog_dirpath(catalog)
    dirpath
  end

  # Resolves the effective source directory for a catalog, honoring an optional
  # dotfile (Rails.configuration.photo_dotfile) inside the base photo_source folder.
  # Returns [effective_dirpath, warning_message_or_nil].
  def resolve_catalog_dirpath(catalog)
    base_dir = File.join(
      Rails.configuration.photo_path,
      Rails.configuration.photo_base,
      catalog,
      Rails.configuration.photo_source
    )
    result = read_gallery_subpath(base_dir)
    effective_dir = result[:subpath].present? ? File.join(base_dir, result[:subpath]) : base_dir
    [effective_dir, result[:warning]]
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
    return File.join( '/', 'photos', fn )
  end

  def shell_escaped_path(path)
    Shellwords.escape(path.to_s)
  end

  # Validates that subpath is a clean, strictly downward relative path
  # (no leading/trailing slashes, backslashes, null bytes, or '.' / '..' segments).
  # If base_dir is provided, verifies the expanded target remains strictly beneath base_dir.
  def valid_downward_subpath?(subpath, base_dir = nil)
    return false unless subpath.is_a?(String)

    candidate = subpath.strip
    return false if candidate.empty?
    return false if candidate.include?("\0") || candidate.include?("\\")
    return false if candidate.start_with?("/") || candidate.end_with?("/")
    return false if candidate.include?("//")

    segments = candidate.split("/")
    return false if segments.empty?
    return false if segments.any? { |seg| seg.empty? || seg == "." || seg == ".." }

    if base_dir.present?
      expanded_base   = File.expand_path(base_dir.to_s)
      expanded_target = File.expand_path(candidate, expanded_base)
      return false unless expanded_target.start_with?("#{expanded_base}/")
    end

    true
  end

  # Reads an optional dotfile (Rails.configuration.photo_dotfile) inside base_source_dir.
  # Ignores blank lines and '#' comment lines, returning the first active
  # downward subpath if valid and existing on disk.
  # Invalid or missing targets are ignored with a warning so ingestion can fall back.
  def read_gallery_subpath(base_source_dir)
    dotfile_name = Rails.configuration.photo_dotfile
    dotfile_path = File.join(base_source_dir.to_s, dotfile_name)
    return { subpath: nil, warning: nil } unless File.file?(dotfile_path)

    active_line = File.readlines(dotfile_path, chomp: true)
                      .map(&:strip)
                      .reject { |line| line.empty? || line.start_with?("#") }
                      .first

    return { subpath: nil, warning: nil } if active_line.nil?

    unless valid_downward_subpath?(active_line, base_source_dir)
      msg = "Ignored invalid #{dotfile_name} subpath '#{active_line}' in #{base_source_dir}; using base source directory."
      Gallery::Environ.log_warn(msg)
      return { subpath: nil, warning: msg }
    end

    target_dir = File.join(base_source_dir, active_line)
    unless Dir.exist?(target_dir)
      msg = "Ignored missing #{dotfile_name} target '#{active_line}' in #{base_source_dir}; using base source directory."
      Gallery::Environ.log_warn(msg)
      return { subpath: nil, warning: msg }
    end

    { subpath: active_line, warning: nil }
  end

# **********************************************
end  # module
