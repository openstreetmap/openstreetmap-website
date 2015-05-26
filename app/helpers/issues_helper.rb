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
			link_to reportable.display_name,	:controller => reportable.class.name.underscore,
																				:action => "view",
																				:display_name => reportable.diary_entry.user.display_name
		when "DiaryComment"
			link_to "#{reportable.diary_entry.title} Comment id ##{reportable.id}",	:controller => reportable.diary_entry.class.name.underscore,
					                                                                   	:action => :view,
					                                                                   	:display_name => reportable.diary_entry.user.display_name,
					                                                                   	:id => reportable.id

		else
			nil
		end
	end
end
