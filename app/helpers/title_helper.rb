module TitleHelper
  def set_title(title = false)
    response.headers["X-Page-Title"] = t('layouts.project_name.title') + (title ? ' | ' + title : '')
    @title = title
  end
end
