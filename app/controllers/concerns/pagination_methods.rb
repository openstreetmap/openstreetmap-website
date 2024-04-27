module PaginationMethods
  extend ActiveSupport::Concern

  private

  ##
  # limit selected items to one page, get ids of first item before/after the page
  def get_page_items(items, includes: [], limit: 20)
    id_column = "#{items.table_name}.id"
    page_items = if params[:before]
                   items.where("#{id_column} < ?", params[:before]).order(:id => :desc)
                 elsif params[:after]
                   items.where("#{id_column} > ?", params[:after]).order(:id => :asc)
                 else
                   items.order(:id => :desc)
                 end

    page_items = page_items.limit(limit)
    page_items = page_items.includes(includes)
    page_items = page_items.sort.reverse

    newer_param = { :after => page_items.first.id } if page_items.count.positive? && items.exists?(["#{id_column} > ?", page_items.first.id])
    older_param = { :before => page_items.last.id } if page_items.count.positive? && items.exists?(["#{id_column} < ?", page_items.last.id])

    [page_items, newer_param, older_param]
  end
end
