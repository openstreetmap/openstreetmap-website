namespace :ar do
  desc 'Pre-load edge rails ActiveRecord'
  task :edge do
    unless path = ENV['EDGE_RAILS_DIR'] || ENV['EDGE_RAILS']
      puts <<-EOS

Need to define env var EDGE_RAILS_DIR or EDGE_RAILS- root of edge rails on your machine.
    i)  Get copy of Edge Rails - http://dev.rubyonrails.org
    ii) Set EDGE_RAILS_DIR to this folder in local/paths.rb - see local/paths.rb.sample for example
    or
    a)  Set folder from environment or command line (rake ar:edge EDGE_RAILS_DIR=/path/to/rails)
  
      EOS
      exit
    end
    
    ENV['AR_LOAD_PATH'] = File.join(path, "activerecord/lib")
  end
  
  desc 'Pre-load ActiveRecord using VERSION=X.Y.Z, instead of latest'
  task :set do
    unless version = ENV['VERSION']
      puts <<-EOS
Usage: rake ar:get_version VERSION=1.15.3
    Specify the version number with VERSION=X.Y.Z; and make sure you have that activerecord gem version installed.
    
      EOS
    end
    version = nil if version == "" || version == []
    begin
      version ? gem('activerecord', version) : gem('activerecord')
      require 'active_record'
      ENV['AR_LOAD_PATH'] = $:.reverse.find { |path| /activerecord/ =~ path }
    rescue LoadError
      puts <<-EOS
Missing: Cannot find activerecord #{version} installed.
    Install: gem install activerecord -v #{version}
    
      EOS
      exit
    end
  end
end