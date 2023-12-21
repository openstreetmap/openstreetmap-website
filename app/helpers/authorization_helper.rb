module AuthorizationHelper
  include ActionView::Helpers::TranslationHelper

  def authorization_scope(scope)
    html = []
    html << t("oauth.scopes.#{scope}")
    if Oauth::MODERATOR_SCOPES.include? scope
      html << " "
      html << image_tag("roles/moderator.png", :srcset => image_path("roles/moderator.svg", :class => "align-text-bottom"), :size => "20x20")
    end
    safe_join(html)
  end
end
