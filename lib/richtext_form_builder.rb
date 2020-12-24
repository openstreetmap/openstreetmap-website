class RichtextFormBuilder < BootstrapForm::FormBuilder
  def richtext_field(attribute, options = {})
    id = "#{@object_name}_#{attribute}"
    type = options.delete(:format) || "markdown"

    @template.render(:partial => "shared/richtext_field",
                     :locals => { :object => @object,
                                  :attribute => attribute,
                                  :object_name => @object_name,
                                  :id => id,
                                  :type => type,
                                  :options => options,
                                  :builder => self })
  end
end
