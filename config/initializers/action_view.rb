#
# Make :formats work when rendering one partial from another
#
# Taken from https://github.com/rails/rails/pull/6626
#
module ActionView
  class AbstractRenderer #:nodoc:
    def prepend_formats(formats)
      formats = Array(formats)
      return if formats.empty?
      @lookup_context.formats = formats | @lookup_context.formats
    end
  end

  class PartialRenderer
    def setup_with_formats(context, options, block)
      prepend_formats(options[:formats])
      setup_without_formats(context, options, block)
    end

    alias_method_chain :setup, :formats
  end

  class TemplateRenderer
    def render_with_formats(context, options)
      prepend_formats(options[:formats])
      render_without_formats(context, options)
    end

    alias_method_chain :render, :formats
  end
end
