require "test/unit"
require File.dirname(__FILE__) + '/../../../../spec_helper.rb'

module TestSuiteAdapterSpecHelper
  def create_adapter(group)
    Test::Unit::TestSuiteAdapter.new(group)
  end
end

describe "TestSuiteAdapter#size" do
  include TestSuiteAdapterSpecHelper
  it "should return the number of examples in the example group" do
    group = Class.new(Spec::ExampleGroup) do
      describe("some examples")
      it("bar") {}
      it("baz") {}
    end
    adapter = create_adapter(group)
    adapter.size.should == 2
  end
end

describe "TestSuiteAdapter#delete" do
  include TestSuiteAdapterSpecHelper
  it "should do nothing" do
    group = Class.new(Spec::ExampleGroup) do
      describe("Some Examples")
      it("does something") {}
    end
    adapter = create_adapter(group)
    adapter.delete(adapter.examples.first)
    adapter.should be_empty
  end
end
