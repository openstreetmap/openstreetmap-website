require 'globalize/i18n/missing_translations_log_handler'

I18n.missing_translations_logger = Logger.new("#{RAILS_ROOT}/log/missing_translations.log")
I18n.exception_handler = :missing_translations_log_handler

I18n.backend.add_pluralizer :sl, lambda { |c| c%100 == 1 ? :one : c%100 == 2 ? :two : (3..4).include?(c%100) ? :few : :other }
