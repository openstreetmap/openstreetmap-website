require 'test/unit'
require 'rubygems'
require 'active_support'
require 'active_record'
require 'action_view'
require File.dirname(__FILE__) + '/connection'
require 'stringio'

RAILS_ROOT = File.dirname(__FILE__)
RAILS_ENV = ""

$: << "../lib"

require 'file_column'
require 'file_compat'
require 'validations'
require 'test_case'

# do not use the file executable normally in our tests as
# it may not be present on the machine we are running on
FileColumn::ClassMethods::DEFAULT_OPTIONS = 
  FileColumn::ClassMethods::DEFAULT_OPTIONS.merge({:file_exec => nil})

class ActiveRecord::Base
    include FileColumn
    include FileColumn::Validations
end


class RequestMock
  attr_accessor :relative_url_root

  def initialize
    @relative_url_root = ""
  end
end

class Test::Unit::TestCase

  def assert_equal_paths(expected_path, path)
    assert_equal normalize_path(expected_path), normalize_path(path)
  end


  private
  
  def normalize_path(path)
    Pathname.new(path).realpath
  end

  def clear_validations
    [:validate, :validate_on_create, :validate_on_update].each do |attr|
        Entry.write_inheritable_attribute attr, []
        Movie.write_inheritable_attribute attr, []
      end
  end

  def file_path(filename)
    File.expand_path("#{File.dirname(__FILE__)}/fixtures/#{filename}")
  end

  alias_method :f, :file_path
end
