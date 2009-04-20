class SqlSessionStoreGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    runtime_args.insert(0, 'add_sql_session')
    if runtime_args.include?('postgresql')
      @_database = 'postgresql'
    elsif runtime_args.include?('mysql')
      @_database = 'mysql'
    elsif runtime_args.include?('oracle')
      @_database = 'oracle'
    else
      puts "error: database type not given.\nvalid arguments are: mysql or postgresql"
      exit
    end
    super
  end

  def manifest
    record do |m|
      m.migration_template("migration.rb", 'db/migrate',
                           :assigns => { :migration_name => "SqlSessionStoreSetup", :database => @_database },
                           :migration_file_name => "sql_session_store_setup"
                           )
    end
  end
end
