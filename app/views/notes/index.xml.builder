xml.instruct!

xml.notes << (render(:partial => "note", :collection => @notes) || "")
