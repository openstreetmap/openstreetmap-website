class ChangeDefaultFormats < ActiveRecord::Migration[4.2]
  def up
    change_column_default :diary_entries, :body_format, "markdown"
    change_column_default :diary_comments, :body_format, "markdown"
    change_column_default :messages, :body_format, "markdown"
    change_column_default :users, :description_format, "markdown"
    change_column_default :user_blocks, :reason_format, "markdown"
  end

  def down
    change_column_default :diary_entries, :body_format, "html"
    change_column_default :diary_comments, :body_format, "html"
    change_column_default :messages, :body_format, "html"
    change_column_default :users, :description_format, "html"
    change_column_default :user_blocks, :reason_format, "html"
  end
end
