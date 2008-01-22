require "test/unit"
require File.dirname(__FILE__) + '/../../../../spec_helper.rb'

describe "TestCase#method_name" do
  it "should equal the description of the example" do
    @method_name.should == "should equal the description of the example"
  end

  def test_this
    true.should be_true
  end

  def testThis
    true.should be_true
  end

  def testament
    raise "testament is not a test"
  end
end
