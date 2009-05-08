namespace :sqlite3 do
  desc 'Build the sqlite test databases'
  task :build_databases => :load_connection do 
    file = File.join(SCHEMA_PATH, 'sqlite.sql')
    dbfile = File.join(PROJECT_ROOT, ENV['cpk_adapter_options_str'])
    cmd = "mkdir -p #{File.dirname(dbfile)}"
    puts cmd
    sh %{ #{cmd} }
    cmd = "sqlite3 #{dbfile} < #{file}"
    puts cmd
    sh %{ #{cmd} }
  end

  desc 'Drop the sqlite test databases'
  task :drop_databases => :load_connection do 
    dbfile = ENV['cpk_adapter_options_str']
    sh %{ rm -f #{dbfile} }
  end

  desc 'Rebuild the sqlite test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]

  task :load_connection do
    require File.join(PROJECT_ROOT, %w[lib adapter_helper sqlite3])
    spec = AdapterHelper::Sqlite3.load_connection_from_env
    ENV['cpk_adapter_options_str'] = spec[:dbfile]
  end
end
