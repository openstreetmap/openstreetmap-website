json.partial! "api/root_attributes"

json.preferences(@user_preferences.to_h { |pref| [pref.k, pref.v] })
