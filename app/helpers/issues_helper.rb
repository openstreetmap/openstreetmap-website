module IssuesHelper

	def reportable_url(reportable)
		class_name = reportable.class.name
		case class_name
		when "DiaryEntry"
			link_to reportable.title,	:controller => reportable.class.name.underscore,
										:action => :view,
										:display_name => reportable.user.display_name,
										:id => reportable.id
		when "User"
			link_to reportable.display_name.to_s,	:controller => reportable.class.name.underscore,
													:action => :view,
													:display_name => reportable.display_name
		when "DiaryComment"
			link_to "#{reportable.diary_entry.title}, Comment id ##{reportable.id}",	:controller => reportable.diary_entry.class.name.underscore,
					                                                                   	:action => :view,
					                                                                   	:display_name => reportable.diary_entry.user.display_name,
					                                                                   	:id => reportable.diary_entry.id,
					                                                                   	:comment_id => reportable.id
		when "Changeset"
			link_to "Changeset ##{reportable.id}",		:controller => :browse,
														:action => :changeset,
														:id => reportable.id
		when "Note"
			link_to "Note ##{reportable.id}", 	:controller => :browse,
											  	:action => :note,
											  	:id => reportable.id
		else
			nil
		end
	end

	def reports_url(issue)
		class_name = issue.reportable.class.name
		case class_name
		when "DiaryEntry"
			link_to issue.reportable.title, issue
		when "User"
			link_to issue.reportable.display_name.to_s, issue
		when "DiaryComment"
			link_to "#{issue.reportable.diary_entry.title}, Comment id ##{issue.reportable.id}", issue
		when "Changeset"
			link_to "Changeset ##{issue.reportable.id}",issue
		when "Note"
			link_to "Note ##{issue.reportable.id}", issue
		else
			nil
		end
	end

	def instance_url(reportable)
		class_name = reportable.class.name
		case class_name
		when "DiaryEntry"
			link_to "Show Instance",	:controller => reportable.class.name.underscore,
										:action => :view,
										:display_name => reportable.user.display_name,
										:id => reportable.id
		when "User"
			link_to "Show Instance",	:controller => reportable.class.name.underscore,
										:action => :view,
										:display_name => reportable.display_name
		when "DiaryComment"
			link_to "Show Instance",	:controller => reportable.diary_entry.class.name.underscore,
		                               	:action => :view,
		                               	:display_name => reportable.diary_entry.user.display_name,
		                               	:id => reportable.diary_entry.id,
		                               	:comment_id => reportable.id
		when "Changeset"
			link_to "Show Instance", :controller => :browse,
									 :action => :changeset,
									 :id => reportable.id
		when "Note"
			link_to "Show Instance", :controller => :browse,
									 :action => :note,
									 :id => reportable.id
		else
			nil
		end
	end

	def sortable(column,title=nil)
		title ||= column.titleize
		direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
		if column == sort_column
			arrow = direction == "desc" ? ["25B2".hex].pack("U") : ["25BC".hex].pack("U")
			title = title + arrow
		end
		link_to title, params.merge(:sort => column, :direction => direction)
	end

	def report_type(report_class) 
		case report_class
		when "DiaryEntry"
			t('activerecord.models.diary_entry')
		when "User"
			t('activerecord.models.user')
		when "DiaryComment"
			t('activerecord.models.diary_comment')
		when "Changeset"
			t('activerecord.models.changeset')
		when "Note"
			t('activerecord.models.note')				
		else
			nil
		end
	end
end
