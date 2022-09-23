module Api
  class ElementsController < ApiController
    private

    def index_for_models(current_model, old_model)
      type_plural = current_model.model_name.plural

      raise OSM::APIBadUserInput, "The parameter #{type_plural} is required, and must be of the form #{type_plural}=ID[vVER][,ID[vVER][,ID[vVER]...]]" unless params[type_plural]

      search_strings = params[type_plural].split(",")

      raise OSM::APIBadUserInput, "No #{type_plural} were given to search for" if search_strings.empty?

      id_ver_strings, id_strings = search_strings.partition { |iv| iv.include? "v" }
      id_vers = id_ver_strings.map { |iv| iv.split("v", 2).map(&:to_i) }
      ids = id_strings.map(&:to_i)

      result = current_model.find(ids)
      unless id_vers.empty?
        result += old_model.find(id_vers)
        result.uniq! do |element|
          if element.id.is_a?(Array)
            element.id
          else
            [element.id, element.version]
          end
        end
      end
      instance_variable_set :"@#{type_plural}", result

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
