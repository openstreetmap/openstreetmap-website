#--
# Copyright (c) 2006 Nic Williams
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

unless defined?(ActiveRecord)
  begin
    require 'active_record'  
  rescue LoadError
    require 'rubygems'
    require_gem 'activerecord'
  end
end

require 'composite_primary_keys/fixtures'
require 'composite_primary_keys/composite_arrays'
require 'composite_primary_keys/associations'
require 'composite_primary_keys/association_preload'
require 'composite_primary_keys/reflection'
require 'composite_primary_keys/base'
require 'composite_primary_keys/calculations'
require 'composite_primary_keys/migration'
require 'composite_primary_keys/attribute_methods'

ActiveRecord::Base.class_eval do
  include CompositePrimaryKeys::ActiveRecord::Base
end

Dir[File.dirname(__FILE__) + '/composite_primary_keys/connection_adapters/*.rb'].each do |adapter|
  begin
    require adapter.gsub('.rb','')
  rescue MissingSourceFile
  end
end
