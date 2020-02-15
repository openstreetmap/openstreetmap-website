require "test_helper"

class MicrocosmTest < ActiveSupport::TestCase
  def test_microcosm_validations
    microcosm_valid({})

    microcosm_valid({ :name => nil }, false)
    microcosm_valid({ :name => "" }, false)
    microcosm_valid(:name => "a" * 255)
    microcosm_valid({ :name => "a" * 256 }, false)

    microcosm_valid({ :description => "" }, false)
    microcosm_valid(:description => "a" * 1023)
    microcosm_valid({ :description => "a" * 1024 }, false)

    microcosm_valid(:latitude => 90)
    microcosm_valid({ :latitude => 90.00001 }, false)
    microcosm_valid(:latitude => -90)
    microcosm_valid({ :latitude => -90.00001 }, false)

    microcosm_valid(:longitude => 180)
    microcosm_valid({ :longitude => 180.00001 }, false)
    microcosm_valid(:longitude => -180)
    microcosm_valid({ :longitude => -180.00001 }, false)

    [:min, :max].each do |extremum|
      [:lat, :lon].each do |coord|
        attr =  "#{extremum}_#{coord}"
        microcosm_valid({attr => nil}, false)
        microcosm_valid({attr => -200}, false)
        microcosm_valid({attr => 200}, false)
      end
    end
  end

  def microcosm_valid(attrs, result = true)
    mic = build(:microcosm, attrs)
    #print(mic.inspect)
    assert_equal result, mic.valid?, "Expected #{attrs.inspect} to be #{result}"
  end
end
