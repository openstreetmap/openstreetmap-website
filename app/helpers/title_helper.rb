module TitleHelper
  def set_title(title = false)
    if title
      @title = title.gsub("<bdi>", "\u202a").gsub("</bdi>", "\u202c")
      response.headers["X-Page-Title"] = t('layouts.project_name.title') + ' | ' + @title
    else
      @title = title
      response.headers["X-Page-Title"] = t('layouts.project_name.title')
    end
  end
end
