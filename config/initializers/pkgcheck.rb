# config/initializers/pkgcheck.rb
# runs pkgcheck.sh to verify that expected system packages have been installed
# else aborts the initialization processing with a log message

if Rails.env.development?
  pkgcheck_path = Rails.root.join("bin", "pkgcheck.sh")

  if File.exist?(pkgcheck_path)
    unless system(pkgcheck_path.to_s)
      warn "\e[1;31mERROR: Required system packages are missing or not found in PATH.\e[0m"
      warn "Review the output of bin/pkgcheck.sh for details on missing dependencies."
      abort "Aborting Rails startup due to missing system dependencies."
    end
  end
end
