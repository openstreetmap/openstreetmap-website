namespace :postgresql do
  desc 'Build the PostgreSQL test databases'
  task :build_databases => :load_connection do 
    sh %{ createdb "#{GEM_NAME}_unittest" }
    sh %{ psql "#{GEM_NAME}_unittest" -f #{File.join(SCHEMA_PATH, 'postgresql.sql')} }
  end

  desc 'Drop the PostgreSQL test databases'
  task :drop_databases => :load_connection do 
    sh %{ dropdb "#{GEM_NAME}_unittest" }
  end

  desc 'Rebuild the PostgreSQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]

  task :load_connection do
    require File.join(PROJECT_ROOT, %w[lib adapter_helper postgresql])
    spec = AdapterHelper::Postgresql.load_connection_from_env
    options = {}
    options['u'] = spec[:username]  if spec[:username]
    options['p'] = spec[:password]  if spec[:password]
    options_str = options.map { |key, value| "-#{key}#{value}" }.join(" ")
    ENV['cpk_adapter_options_str'] = options_str
  end
end

