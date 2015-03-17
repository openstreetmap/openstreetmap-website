require "htmlentities"

module TitleHelper
  def self.coder
    @coder ||= HTMLEntities.new
  end

  def set_title(title = false)
    if title
      @title = TitleHelper.coder.decode(title.gsub("<bdi>", "\u202a").gsub("</bdi>", "\u202c"))
      response.headers["X-Page-Title"] = URI.escape(t("layouts.project_name.title") + " | " + @title)
    else
      @title = title
      response.headers["X-Page-Title"] = URI.escape(t("layouts.project_name.title"))
    end
  end
end
