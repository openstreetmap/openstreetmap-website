require "ostruct"

module ReportsHelper
  def report_link(name, reportable)
    link_to name, new_report_url(:reportable_id => reportable.id, :reportable_type => reportable.class.name)
  end

  # Convert a list of strings into objects with methods that the collection_radio_buttons helper expects
  def report_categories(reportable)
    Report.categories_for(reportable).map do |c|
      OpenStruct.new(:id => c, :label => t(".categories.#{reportable.class.name.underscore}.#{c}_label"))
    end
  end
end
