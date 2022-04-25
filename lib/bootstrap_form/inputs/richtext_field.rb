# frozen_string_literal: true

# A custom richtext_field form group. By using form_group_builder we get to use
# the built-in methods for generating labels and help text.
module BootstrapForm
  module Inputs
    module RichtextField
      extend ActiveSupport::Concern
      include Base

      # It's not clear to me why this needs to be duplicated from the upstream BootstrapForm::FormBuilder class
      delegate :content_tag, :capture, :concat, :tag, :to => :@template

      included do
        def richtext_field_with_bootstrap(name, options = {})
          id = "#{@object_name}_#{name}"
          type = options.delete(:format) || "markdown"

          form_group_builder(name, options) do
            @template.render(:partial => "shared/richtext_field",
                             :locals => { :object => @object,
                                          :attribute => name,
                                          :object_name => @object_name,
                                          :id => id,
                                          :type => type,
                                          :options => options,
                                          :builder => self })
          end
        end

        alias_method :richtext_field, :richtext_field_with_bootstrap
      end
    end
  end
end
