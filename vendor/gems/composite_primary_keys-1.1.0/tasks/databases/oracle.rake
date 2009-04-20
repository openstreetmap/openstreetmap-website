namespace :oracle do
  desc 'Build the Oracle test databases'
  task :build_databases => :load_connection do 
    puts File.join(SCHEMA_PATH, 'oracle.sql')
    options_str = ENV['cpk_adapter_options_str']
    sh %( sqlplus #{options_str} < #{File.join(SCHEMA_PATH, 'oracle.sql')} )
  end

  desc 'Drop the Oracle test databases'
  task :drop_databases => :load_connection do 
    puts File.join(SCHEMA_PATH, 'oracle.drop.sql')
    options_str = ENV['cpk_adapter_options_str']
    sh %( sqlplus #{options_str} < #{File.join(SCHEMA_PATH, 'oracle.drop.sql')} )
  end

  desc 'Rebuild the Oracle test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
  
  task :load_connection do
    require File.join(PROJECT_ROOT, %w[lib adapter_helper oracle])
    spec = AdapterHelper::Oracle.load_connection_from_env
    ENV['cpk_adapter_options_str'] = "#{spec[:username]}/#{spec[:password]}@#{spec[:host]}"
  end
  
end
