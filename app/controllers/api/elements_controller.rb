module Api
  class ElementsController < ApiController
    # Dump the details on many elements whose ids are given in the "nodes"/"ways"/"relations" parameter.
    def index
      type_plural = current_model.model_name.plural

      raise OSM::APIBadUserInput, "The parameter #{type_plural} is required, and must be of the form #{type_plural}=id[,id[,id...]]" unless params[type_plural]

      ids = params[type_plural].split(",").collect(&:to_i)

      raise OSM::APIBadUserInput, "No #{type_plural} were given to search for" if ids.empty?

      instance_variable_set :"@#{type_plural}", current_model.find(ids)

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
