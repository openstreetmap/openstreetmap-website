# frozen_string_literal: true

# Include our custom RichtextField input method for `f.richtext_field` in forms
Rails.application.reloader.to_prepare do
  BootstrapForm::FormBuilder.include BootstrapForm::Inputs::RichtextField
end

BootstrapForm.configure do |config|
  # As of writing these lines, if this is not set it will behave differently
  # in dev and prod. See https://github.com/bootstrap-ruby/bootstrap_form/pull/779
  #
  # Additionally, a `true` setting will generate markup more conformant
  # with WAI-ARIA, which hopefully will be more accessible.
  config.group_around_collections = true
end
