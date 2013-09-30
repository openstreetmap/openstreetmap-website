module ActionDispatch
  class Request < Rack::Request
    class Session
      def clear_with_rescue
        clear_without_rescue
      rescue
        # lets not worry about it...
      end

      alias_method_chain :clear, :rescue
    end
  end
end
