class Sessions::OmniauthController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    @user = User.from_omniauth(omniauth)

    if @user.persisted?
      session_record = @user.sessions.create!

      # WxLogin self_redirect:true runs callback inside an iframe.
      # Chrome's SameSite cookie policy blocks Set-Cookie from iframes,
      # so we cannot set the cookie here. Instead, store a short-lived token
      # in Rails.cache and redirect the top-level window to a handoff URL
      # that sets the cookie in the main browsing context.
      if params[:provider] == "open_wechat"
        handoff_token = SecureRandom.hex(32)
        Rails.cache.write("wechat_login_token:#{handoff_token}", session_record.id, expires_in: 60.seconds)
        handoff_url = auth_wechat_handoff_url(token: handoff_token)
        return render html: <<~HTML.html_safe, layout: false
          <!DOCTYPE html><html><body>
          <script>
            try { window.top.location.href = #{handoff_url.to_json}; }
            catch(e) { window.location.href = #{handoff_url.to_json}; }
          </script>
          </body></html>
        HTML
      end

      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }
      redirect_to root_path, notice: "已通过 #{omniauth.provider.humanize} 登录成功"
    else
      flash[:alert] = handle_password_errors(@user)
      redirect_to sign_in_path
    end
  end

  def failure
    error_type = params[:message] || request.env['omniauth.error.type']

    error_message = case error_type.to_s
    when 'access_denied'
      "Authorization was cancelled. Please try again if you'd like to sign in."
    when 'invalid_credentials'
      "Invalid credentials provided. Please check your information and try again."
    when 'timeout'
      "Authentication timed out. Please try again."
    else
      "Authentication failed: #{error_type&.to_s&.humanize || 'Unknown error'}"
    end

    flash[:alert] = error_message
    redirect_to sign_in_path
  end

  private

  def omniauth
    request.env["omniauth.auth"]
  end
end
