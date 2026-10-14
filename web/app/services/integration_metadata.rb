# Public service details shared by every integration contract.
class IntegrationMetadata
  def self.details
    {
      website_url: ENV.fetch("INTEGRATION_WEBSITE_URL", "https://lumiere.host").presence,
      company_name: ENV.fetch("INTEGRATION_COMPANY_NAME", "Love Wins Media, Inc.").presence,
      support_url: ENV["INTEGRATION_SUPPORT_URL"].presence,
      support_email: ENV["INTEGRATION_SUPPORT_EMAIL"].presence
    }
  end
end
