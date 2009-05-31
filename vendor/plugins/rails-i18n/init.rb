# Rails plugin initialization: add default locales to I18n.load_path
# - only add locales that are actually used in the application
# - prepend locales so that they can be overwritten by the application
#
# We do this after_initialize as the I18n.load_path might be modified
# in a config/initializers/initializer.rb
class Rails::Initializer #:nodoc:
  def after_initialize_with_translations_import
    after_initialize_without_translations_import
    used_locales = I18n.load_path.map { |f| File.basename(f).gsub(/\.(rb|yml)$/, '') }.uniq
    files_to_add = Dir[File.join(File.dirname(__FILE__), 'locale', "{#{used_locales.join(',')}}.{rb,yml}")]
    I18n.load_path.unshift(*files_to_add)
  end
  alias_method_chain :after_initialize, :translations_import 
end
