Rails.application.configure do
  # MissionControl::Jobs.http_basic_auth_user = "dev"
  # MissionControl::Jobs.http_basic_auth_password = "secret"
  MissionControl::Jobs.http_basic_auth_enabled = false
end
