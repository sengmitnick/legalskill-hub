require Rails.root.join("lib/omniauth/strategies/open_wechat")

# Redirect to failure path instead of calling Rails stack directly,
# which avoids Faraday stream_response bytesize nil crash.
OmniAuth.config.on_failure = proc { |env|
  error_type = env["omniauth.error.type"]
  [302, { "Location" => "/auth/failure?message=#{error_type}", "Content-Type" => "text/html" }, []]
}

# Allow both GET and POST for OAuth callbacks
OmniAuth.config.allowed_request_methods = [:get, :post]

Rails.application.config.middleware.use OmniAuth::Builder do
  # OAuth providers - only enabled if OAUTH_ENABLED is true

  if ENV['GOOGLE_OAUTH_ENABLED'] == 'true'
    provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
      scope: 'email,profile',
      prompt: 'select_account',
      image_aspect_ratio: 'square',
      image_size: 50
    }
  end

  if ENV['FACEBOOK_OAUTH_ENABLED'] == 'true'
    provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'], {
      scope: 'email,public_profile',
      info_fields: 'name,email'
    }
  end

  if ENV['TWITTER_OAUTH_ENABLED'] == 'true'
    provider :twitter2, ENV['TWITTER_API_KEY'], ENV['TWITTER_API_SECRET'], {
      scope: "tweet.read users.read"
    }
  end

  if ENV['GITHUB_OAUTH_ENABLED'] == 'true'
    provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'], {
      scope: 'user:email'
    }
  end

  # WeChat Open Platform (PC QR code login / WxLogin)
  # provider_ignores_state: true because WeChat JS SDK handles the redirect
  # directly (state is set in JS, not stored in Rails session)
  if ENV["WECHAT_OPEN_APPID"].present?
    provider :open_wechat, ENV["WECHAT_OPEN_APPID"], ENV["WECHAT_OPEN_APPSECRET"], {
      scope: "snsapi_login",
      provider_ignores_state: true
    }
  end

  # Development provider (only in development)
  provider :developer unless Rails.env.production?
end
