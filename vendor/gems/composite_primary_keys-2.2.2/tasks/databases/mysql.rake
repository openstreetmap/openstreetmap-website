namespace :mysql do
  desc 'Build the MySQL test databases'
  task :build_databases => :load_connection do 
    puts File.join(SCHEMA_PATH, 'mysql.sql')
    options_str = ENV['cpk_adapter_options_str']
    # creates something like "-u#{username} -p#{password} -S#{socket}"
    sh %{ mysqladmin #{options_str} create "#{GEM_NAME}_unittest" }
    sh %{ mysql #{options_str} "#{GEM_NAME}_unittest" < #{File.join(SCHEMA_PATH, 'mysql.sql')} }
  end

  desc 'Drop the MySQL test databases'
  task :drop_databases => :load_connection do 
    options_str = ENV['cpk_adapter_options_str']
    sh %{ mysqladmin #{options_str} -f drop "#{GEM_NAME}_unittest" }
  end

  desc 'Rebuild the MySQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
  
  task :load_connection do
    require File.join(PROJECT_ROOT, %w[lib adapter_helper mysql])
    spec = AdapterHelper::MySQL.load_connection_from_env
    options = {}
    options['u'] = spec[:username]  if spec[:username]
    options['p'] = spec[:password]  if spec[:password]
    options['S'] = spec[:sock]      if spec[:sock]
    options_str = options.map { |key, value| "-#{key}#{value}" }.join(" ")
    ENV['cpk_adapter_options_str'] = options_str
  end
end
