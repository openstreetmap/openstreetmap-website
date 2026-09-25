# frozen_string_literal: true

require "test_helper"

class MapLayersTest < ActiveSupport::TestCase
  def test_full_definitions_returns_well_formed_layers_collection
    layers = MapLayers.full_definitions("config/layers.yml")

    assert_kind_of Array, layers, "Expected full_definitions to return an array"
    assert_operator layers.count, :>, 0, "Expected some layers available"

    layer_properties = %w[layerId nameId code style credit]

    layers.each do |layer|
      assert_kind_of Hash, layer, "Expected each layer to be a hash"
      layer_properties.each do |key|
        assert layer.key?(key), "Expected layer to have key '#{key}'"
      end
    end
  end

  def test_first_layer_is_standard_layer
    layers = MapLayers.full_definitions("config/layers.yml")
    first_layer = layers.first

    assert_equal "standard", first_layer["nameId"], "Expected first layer to have nameId 'standard'"
  end
end
