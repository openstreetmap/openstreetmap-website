module AuthorizationHelper
  include ActionView::Helpers::TranslationHelper

  def authorization_scope(scope)
    html = []
    html << t("oauth.scopes.#{scope}")
    if Oauth::MODERATOR_SCOPES.include? scope
      html << " "
      html << role_icon_svg_tag("moderator", false, t("oauth.for_roles.moderator"), :class => "align-text-bottom")
    end
    safe_join(html)
  end
end
