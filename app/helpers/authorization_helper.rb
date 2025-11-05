# frozen_string_literal: true

module AuthorizationHelper
  include ActionView::Helpers::TranslationHelper

  def authorization_scope(scope)
    html = []
    html << t("oauth.scopes.#{scope}")
    if Oauth::MODERATOR_SCOPES.include? scope
      html << " "
      html << role_icon(:classes => "bi-star-fill role-moderator", :title => t("oauth.for_roles.moderator"))
    end
    safe_join(html)
  end

  def role_icon(classes: "", title: "")
    safe_join([
                tag.i(:class => ["bi fs-5 align-middle", classes], :title => title, :aria => { :hidden => "true" }),
                tag.span(title, :class => "visually-hidden")
              ])
  end
end
