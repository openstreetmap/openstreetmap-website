module TitleHelper
  def set_title(title = false)
    if title
      title = t('layouts.project_name.title') + ' | ' + title
    else
      title = t('layouts.project_name.title')
    end
    response.headers["X-Page-Title"] = title 
    @title = title
  end
end
