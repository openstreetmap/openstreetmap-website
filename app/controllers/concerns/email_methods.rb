module EmailMethods
  extend ActiveSupport::Concern

  private

  def canonical_email(email)
    local_part, domain = email.split("@")

    local_part.sub!(/\+.*$/, "")

    local_part.delete!(".") if %w[gmail.com googlemail.com].include?(domain)

    "#{local_part}@#{domain}"
  end

  ##
  # get list of MX servers for a domains
  def domain_mx_servers(domain)
    Resolv::DNS.open do |dns|
      dns.getresources(domain, Resolv::DNS::Resource::IN::MX).collect { |mx| mx.exchange.to_s }
    end
  end
end
