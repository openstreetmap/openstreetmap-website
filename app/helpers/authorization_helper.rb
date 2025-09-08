# frozen_string_literal: true

module AuthorizationHelper
  include ActionView::Helpers::TranslationHelper

  def authorization_scope(scope)
    html = []
    html << t("oauth.scopes.#{scope}")
    if Oauth::MODERATOR_SCOPES.include? scope
      html << " "
      html << inline_svg_tag("icons/role-star.svg", :class => "role-icon moderator align-text-bottom",
                                                    :title => t("oauth.for_roles.moderator"))
    end
    safe_join(html)
  end
end
