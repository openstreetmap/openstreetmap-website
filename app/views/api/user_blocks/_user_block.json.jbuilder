json.id user_block.id
json.created_at user_block.created_at.xmlschema
json.updated_at user_block.updated_at.xmlschema
json.ends_at user_block.ends_at.xmlschema
json.needs_view user_block.needs_view

json.user :uid => user_block.user_id, :user => user_block.user.display_name
json.creator :uid => user_block.creator_id, :user => user_block.creator.display_name
json.revoker :uid => user_block.revoker_id, :user => user_block.revoker.display_name if user_block.revoker

json.reason user_block.reason unless @skip_reason
