def mock_tenant
  tenant = Tenant.find_or_create_by(subdomain: 'test') do |tenant|
    tenant.name = 'Test Tenant'
    tenant.api_key = 'test_key'
  end
  allow_any_instance_of(ApplicationController).to receive(:tenant).and_return(tenant)
end
