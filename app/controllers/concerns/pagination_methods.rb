# frozen_string_literal: true

module PaginationMethods
  extend ActiveSupport::Concern

  private

  ##
  # limit selected items to one page, get ids of first item before/after the page
  def get_page_items(items, includes: [], limit: 20, cursor_column: :id)
    param! :before, Integer, :min => 0
    param! :after, Integer, :min => 0

    qualified_cursor_column = "#{items.table_name}.#{cursor_column}"
    page_items = if params[:before]
                   items.where("#{qualified_cursor_column} < ?", params[:before]).reorder(cursor_column => :desc)
                 elsif params[:after]
                   items.where("#{qualified_cursor_column} > ?", params[:after]).reorder(cursor_column => :asc)
                 else
                   items.reorder(cursor_column => :desc)
                 end

    page_items = page_items.limit(limit)
    page_items = page_items.includes(includes)
    page_items = page_items.sort.reverse

    newer_items_cursor = page_items.first&.send cursor_column
    older_items_cursor = page_items.last&.send cursor_column

    [
      page_items,
      (newer_items_cursor if page_items.any? && items.exists?(["#{qualified_cursor_column} > ?", newer_items_cursor])),
      (older_items_cursor if page_items.any? && items.exists?(["#{qualified_cursor_column} < ?", older_items_cursor]))
    ]
  end
end
