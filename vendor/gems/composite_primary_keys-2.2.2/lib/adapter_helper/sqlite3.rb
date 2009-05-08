require File.join(File.dirname(__FILE__), 'base')

module AdapterHelper
  class Sqlite3 < Base
    class << self
      def load_connection_from_env
        spec = super('sqlite3')
        spec[:dbfile] ||= "tmp/test.db"
        spec
      end
    end
  end
end