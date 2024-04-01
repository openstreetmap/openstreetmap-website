class ChangeColumnUserConsiderPdDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, "consider_pd", from: false, to: true
  end
end
