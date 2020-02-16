require "test_helper"

class MicrocosmTest < ActiveSupport::TestCase
  def test_microcosm_validations
    validate({})

    validate({ :name => nil }, false)
    validate({ :name => "" }, false)
    validate(:name => "a" * 255)
    validate({ :name => "a" * 256 }, false)

    validate({ :description => "" }, false)
    validate(:description => "a" * 1023)
    validate({ :description => "a" * 1024 }, false)

    validate(:latitude => 90)
    validate({ :latitude => 90.00001 }, false)
    validate(:latitude => -90)
    validate({ :latitude => -90.00001 }, false)

    validate(:longitude => 180)
    validate({ :longitude => 180.00001 }, false)
    validate(:longitude => -180)
    validate({ :longitude => -180.00001 }, false)

    [:min, :max].each do |extremum|
      [:lat, :lon].each do |coord|
        attr =  "#{extremum}_#{coord}"
        validate({attr => nil}, false)
        validate({attr => -200}, false)
        validate({attr => 200}, false)
      end
    end
  end

  # There's a possibility to factory this out.  See microcosm_member_test.rb.
  def validate(attrs, result = true)
    object = build(:microcosm, attrs)
    valid = object.valid?
    errors = object.errors.messages
    assert_equal result, valid, "Expected #{attrs.inspect} to be #{result} but #{errors}"
  end
end
