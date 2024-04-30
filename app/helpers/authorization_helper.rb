module AuthorizationHelper
  include ActionView::Helpers::TranslationHelper

  def authorization_scope(scope)
    html = []
    html << t("oauth.scopes.#{scope}")
    if Oauth::MODERATOR_SCOPES.include? scope
      html << " "
      html << image_tag("roles.svg#moderator", :size => "20x20", :class => "align-text-bottom")
    end
    safe_join(html)
  end
end
