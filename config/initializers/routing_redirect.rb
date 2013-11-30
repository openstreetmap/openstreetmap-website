require "action_dispatch/routing/redirection"

#
# Fix escaping in routes to use path style escaping
#
# https://github.com/rails/rails/issues/13110
#
module ActionDispatch
  module Routing
    class PathRedirect < Redirect
      def escape(params)
        Hash[params.map{ |k,v| [k, URI.escape(v)] }]
      end
    end
  end
end
