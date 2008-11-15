# Load local config files in /local
begin
  local_file_supported = Dir[File.join(PROJECT_ROOT, 'local/*.sample')].map { |path| File.basename(path).sub(".sample","") }
  local_file_supported.each do |file|
    require "local/#{file}"
  end
rescue LoadError
  puts <<-EOS
  This Gem supports local developer extensions in local/ folder. 
  Supported files:
    #{local_file_supported.map { |f| "local/#{f}"}.join(', ')}

  Setup default sample files:
    rake local:setup

  Current warning: #{$!}
  
  EOS
end


# Now load Rake tasks from /tasks
rakefiles = Dir[File.join(File.dirname(__FILE__), "tasks/**/*.rake")]
rakefiles.each { |rakefile| load File.expand_path(rakefile) }
