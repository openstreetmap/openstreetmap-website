# From https://stackoverflow.com/a/65700370/
module FactoryBot
  module Strategy
    # Does not work when passing objects as associations: `FactoryBot.find_or_create(:entity, association: object)`
    # Instead do: `FactoryBot.find_or_create(:entity, association_id: id)`
    class FindOrCreate
      def initialize
        @build_strategy = FactoryBot.strategy_by_name(:build).new
      end

      delegate :association, :to => :@build_strategy

      def result(evaluation)
        attributes = attributes_shared_with_build_result(evaluation)
        evaluation.object.class.where(attributes).first || FactoryBot.strategy_by_name(:create).new.result(evaluation)
      end

      private

      # Here we handle possible mismatches between initially provided attributes and actual model attrbiutes
      # For example, devise's User model is given a `password` and generates an `encrypted_password`
      # In this case, we shouldn't use `password` in the `where` clause
      def attributes_shared_with_build_result(evaluation)
        object_attributes = evaluation.object.attributes
        evaluation.hash.filter { |k, _v| object_attributes.key?(k.to_s) }
      end
    end
  end

  register_strategy(:find_or_create, Strategy::FindOrCreate)
end
