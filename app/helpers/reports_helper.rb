module ReportsHelper
  def report_link(name, reportable)
    link_to name, new_report_url(:reportable_id => reportable.id, :reportable_type => reportable.class.name)
  end
end
