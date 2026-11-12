json.partial! "api/root_attributes"

json.osmChange do
  json.create(@created.map { |elt| JSON.parse(render(:partial => "api/#{elt.to_partial_path}", :object => elt)) })
  json.modify(@modified.map { |elt| JSON.parse(render(:partial => "api/#{elt.to_partial_path}", :object => elt)) })
  json.delete(@deleted.map { |elt| JSON.parse(render(:partial => "api/#{elt.to_partial_path}", :object => elt)) })
end
