# frozen_string_literal: true

module AuthorizationHelper
  include ActionView::Helpers::TranslationHelper

  def authorization_scope(scope)
    html = []
    html << t("oauth.scopes.#{scope}")
    if Oauth::MODERATOR_SCOPES.include? scope
      html << " "
      html << tag.i(:class => "bi bi-star-fill fs-5 role-moderator align-middle",
                    :title => t("oauth.for_roles.moderator"),
                    :aria => { :hidden => "true" })
      html << tag.span(t("oauth.for_roles.moderator"), :class => "visually-hidden")
    end
    safe_join(html)
  end
end
