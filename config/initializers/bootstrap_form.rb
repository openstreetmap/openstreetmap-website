# Include our custom RichtextField input method for `f.richtext_field` in forms
Rails.application.reloader.to_prepare do
  BootstrapForm::FormBuilder.include BootstrapForm::Inputs::RichtextField
end
