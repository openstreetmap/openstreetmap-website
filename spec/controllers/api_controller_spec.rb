require File.dirname(__FILE__) + '/../spec_helper'

module ApiMapHelpers
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  def boundary_params(key)
    case key
      when :valid
        '-0.3565352711206896,51.464740877658045,-0.2686446461206896,51.508686190158045'
      when :min_lat_more_than_max_lat
        '-0.3565352711206896,51.508686190158045,-0.2686446461206896,51.464740877658045'
      when :min_lon_more_than_max_lon
        '51.464740877658045,-0.2686446461206896,51.508686190158045,-0.3565352711206896'
    end
  end

  module ClassMethods
    def otherasdfa
    end
  end
end

describe "When accessing /api/0.5/map" do
  controller_name :api
  include ApiMapHelpers
  
  before(:each) do
  end

  it "should _return success_ with _correct boundary longitudes/latitudes_" do
    get :map, :bbox => boundary_params(:valid)
    response.should be_success
  end

  it "should return an _error_ when _minimum longitude more than or equal to maximum longitude_" do
    get :map, :bbox => boundary_params(:min_lat_more_than_max_lat)
    response.should_not be_success
  end

  it "should return an error unless minimum latitude less than maximum latitude" do
    get :map, :bbox => boundary_params(:min_lon_more_than_max_lon)
    response.should_not be_success
  end

  it "should return an error unless latitudes are between -90 and 90 degrees" do
    pending
  end

  it "should return an error unless longitudes are between -180 and 180 degrees" do
    pending
  end
  
end
