module AdapterHelper
  class Base
    class << self
      attr_accessor :adapter

      def load_connection_from_env(adapter)
        self.adapter = adapter
        unless ENV['cpk_adapters']
          puts error_msg_setup_helper
          exit
        end

        ActiveRecord::Base.configurations = YAML.load(ENV['cpk_adapters'])
        unless spec = ActiveRecord::Base.configurations[adapter]
          puts error_msg_adapter_helper
          exit
        end
        spec[:adapter] = adapter
        spec
      end
    
      def error_msg_setup_helper
        <<-EOS
Setup Helper:
  CPK now has a place for your individual testing configuration.
  That is, instead of hardcoding it in the Rakefile and test/connections files,
  there is now a local/database_connections.rb file that is NOT in the
  repository. Your personal DB information (username, password etc) can
  be stored here without making it difficult to submit patches etc.

Installation:
  i)   cp locals/database_connections.rb.sample locals/database_connections.rb
  ii)  For #{adapter} connection details see "Adapter Setup Helper" below.
  iii) Rerun this task
  
#{error_msg_adapter_helper}
  
Current ENV:
  #{ENV.inspect}
        EOS
      end
        
      def error_msg_adapter_helper
        <<-EOS
Adapter Setup Helper:
  To run #{adapter} tests, you need to setup your #{adapter} connections.
  In your local/database_connections.rb file, within the ENV['cpk_adapter'] hash, add:
      "#{adapter}" => { adapter settings }

  That is, it will look like:
    ENV['cpk_adapters'] = {
      "#{adapter}" => {
        :adapter  => "#{adapter}",
        :username => "root",
        :password => "root",
        # ...
      }
    }.to_yaml
        EOS
      end
    end
  end
end