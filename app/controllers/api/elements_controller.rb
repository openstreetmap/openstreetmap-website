module Api
  class ElementsController < ApiController
    # Dump the details on many elements whose ids and optionally verions are given in the "nodes"/"ways"/"relations" parameter.
    def index
      raise OSM::APIBadUserInput, "The parameter #{controller_name} is required, and must be of the form #{controller_name}=ID[vVER][,ID[vVER][,ID[vVER]...]]" unless params[controller_name]

      search_strings = params[controller_name].split(",")

      raise OSM::APIBadUserInput, "No #{controller_name} were given to search for" if search_strings.empty?

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
      instance_variable_set :"@#{controller_name}", result

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end
  end
end
