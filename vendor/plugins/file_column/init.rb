# plugin init file for rails
# this file will be picked up by rails automatically and
# add the file_column extensions to rails

require 'file_column'
require 'file_compat'
require 'file_column_helper'
require 'validations'
require 'test_case'

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send(:include, FileColumn)
  ActiveRecord::Base.send(:include, FileColumn::Validations)
end

if defined?(ActionView::Base)
  ActionView::Base.send(:include, FileColumnHelper)
end
