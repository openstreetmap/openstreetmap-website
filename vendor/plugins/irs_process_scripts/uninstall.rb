# Install hook code here
unless defined?(RAILS_ROOT)
  $stderr.puts "$0 must be run from RAILS_ROOT with -rconfig/boot"
  exit
end

require 'fileutils'
FileUtils.rm_rf(RAILS_ROOT + '/script/process')