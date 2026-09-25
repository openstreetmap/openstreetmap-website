# frozen_string_literal: true

class ChangeGpxFilesVisibilityDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :gpx_files, :visibility, :from => "public", :to => "trackable"
  end
end
