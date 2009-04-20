require File.join(File.dirname(__FILE__), 'base')

module AdapterHelper
  class Postgresql < Base
    class << self
      def load_connection_from_env
        spec = super('postgresql')
        spec[:database] ||= 'composite_primary_keys_unittest'
        spec
      end
    end
  end
end