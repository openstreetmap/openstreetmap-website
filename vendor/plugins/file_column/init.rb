# plugin init file for rails
# this file will be picked up by rails automatically and
# add the file_column extensions to rails

require 'file_column'
require 'file_compat'
require 'file_column_helper'
require 'validations'
require 'test_case'

ActiveRecord::Base.send(:include, FileColumn)
ActionView::Base.send(:include, FileColumnHelper)
ActiveRecord::Base.send(:include, FileColumn::Validations)