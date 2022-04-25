module TitleHelper
  def self.coder
    @coder ||= HTMLEntities.new
  end

  def set_title(title = nil)
    project_title = t("layouts.project_name.title")

    if title
      @title = TitleHelper.coder.decode(title.gsub("<bdi>", "\u202a").gsub("</bdi>", "\u202c"))
      response.headers["X-Page-Title"] = ERB::Util.u("#{@title} | #{project_title}")
    else
      @title = title
      response.headers["X-Page-Title"] = ERB::Util.u(project_title)
    end
  end
end
