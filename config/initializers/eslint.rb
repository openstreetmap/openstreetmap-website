if defined?(ESLintRails::Runner)
  module OpenStreetMap
    module ESLintRails
      module ExcludeI18n
        def assets
          super.reject { |a| a.to_s =~ %r{/i18n/} }
        end
      end
    end
  end

  ESLintRails::Runner.prepend(OpenStreetMap::ESLintRails::ExcludeI18n)
end
