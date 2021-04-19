json.partial! "api/root_attributes"

json.preferences @user_preferences.map { |pref| [pref.k, pref.v] }.to_h
