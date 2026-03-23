# Handles WeChat MP (公众号) OAuth authorization.
#
# Supports two purposes (via `purpose` param in state):
#   - "login"  → snsapi_userinfo scope, gets unionid, creates session (H5 login)
#   - "pay"    → snsapi_base scope, gets openid only (JSAPI payment)
#
# Flow:
#   authorize(purpose: "login", return_to: "/") →
#     WeChat OAuth → callback →
#       login: find/create user by unionid, set cookie, redirect
#       pay:   store openid in session, redirect back
class Wechat::MpOauthController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  MP_OAUTH_URL = "https://open.weixin.qq.com/connect/oauth2/authorize"
  TOKEN_URL    = "https://api.weixin.qq.com/sns/oauth2/access_token"

  # GET /wechat/mp_oauth/authorize?purpose=login&return_to=<url>
  def authorize
    purpose   = params[:purpose].presence || "pay"
    return_to = params[:return_to] || root_path
    scope     = purpose == "login" ? "snsapi_userinfo" : "snsapi_base"
    state     = build_state(purpose, return_to)

    redirect_to build_oauth_url(scope, state), allow_other_host: true
  end

  # GET /wechat/mp_oauth/callback?code=xxx&state=xxx
  def callback
    code  = params[:code]
    state = params[:state]

    if code.blank?
      redirect_to root_path, alert: "微信授权失败，请重试"
      return
    end

    purpose, return_to = parse_state(state)

    token_data = fetch_token_data(code)

    if token_data.nil?
      redirect_to root_path, alert: "获取微信用户信息失败，请重试"
      return
    end

    if purpose == "login"
      handle_login(token_data, return_to)
    else
      handle_pay_openid(token_data, return_to)
    end
  end

  private

  # ── Login flow ─────────────────────────────────────────────────────

  def handle_login(token_data, return_to)
    unionid = token_data["unionid"]
    openid  = token_data["openid"]
    name    = token_data.dig("nickname").presence || "微信用户"

    if unionid.blank? && openid.blank?
      redirect_to root_path, alert: "无法获取微信身份信息，请重试"
      return
    end

    user = find_or_create_user_by_wechat(unionid, openid, name)

    unless user&.persisted?
      redirect_to root_path, alert: "登录失败，请重试"
      return
    end

    # Save mp_openid for later JSAPI payment use
    user.update_column(:wechat_mp_openid, openid) if openid.present? && user.wechat_mp_openid.blank?

    session_record = user.sessions.create!
    # WeChat in-app browser is not subject to SameSite restrictions, set cookie directly
    cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

    redirect_to return_to, notice: "微信登录成功"
  end

  def find_or_create_user_by_wechat(unionid, openid, name)
    User.transaction do
      # 1. Find by unionid (cross-app stable identifier)
      user = User.find_by(wechat_unionid: unionid) if unionid.present?

      # 2. Fall back to mp_openid (legacy)
      user ||= User.find_by(wechat_mp_openid: openid) if openid.present?

      if user
        user.update!(
          wechat_unionid: unionid,
          provider:       "open_wechat",
          uid:            unionid || openid
        )
        return user
      end

      # 3. New user — create with generated email (no password)
      User.create!(
        wechat_unionid: unionid,
        wechat_mp_openid: openid,
        name:           name,
        email:          User.generate_email("wx_#{(unionid || openid).last(8)}"),
        provider:       "open_wechat",
        uid:            unionid || openid,
        verified:       false
      ).tap(&:create_profile!)
    end
  rescue => e
    Rails.logger.error "[MpOauth] find_or_create_user failed: #{e.message}"
    nil
  end

  # ── Pay flow (openid only) ─────────────────────────────────────────

  def handle_pay_openid(token_data, return_to)
    openid = token_data["openid"]

    if openid.present?
      session[:wechat_mp_openid] = openid

      if current_user && current_user.wechat_mp_openid.blank?
        current_user.update_column(:wechat_mp_openid, openid)
      end

      redirect_to return_to
    else
      redirect_to root_path, alert: "获取微信用户信息失败，请重试"
    end
  end

  # ── OAuth helpers ──────────────────────────────────────────────────

  def build_oauth_url(scope, state)
    query = {
      appid:         ENV.fetch("WECHAT_MP_APPID"),
      redirect_uri:  wechat_mp_oauth_callback_url,
      response_type: "code",
      scope:         scope,
      state:         state
    }.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
    "#{MP_OAUTH_URL}?#{query}#wechat_redirect"
  end

  # state = "<purpose>|<base64_return_to>"
  def build_state(purpose, return_to)
    "#{purpose}|#{Base64.urlsafe_encode64(return_to, padding: false)}"
  end

  def parse_state(state)
    return ["pay", root_path] if state.blank?

    parts   = state.split("|", 2)
    purpose = parts[0].presence || "pay"
    encoded = parts[1].presence

    return_to = if encoded
      begin
        decoded = Base64.urlsafe_decode64(encoded)
        uri     = URI.parse(decoded)
        uri.host.blank? ? decoded : root_path
      rescue
        root_path
      end
    else
      root_path
    end

    [purpose, return_to]
  end

  # Exchanges code for token data. For snsapi_userinfo returns full user info.
  def fetch_token_data(code)
    uri    = URI(TOKEN_URL)
    uri.query = URI.encode_www_form(
      appid:      ENV.fetch("WECHAT_MP_APPID"),
      secret:     ENV.fetch("WECHAT_MP_APPSECRET"),
      code:       code,
      grant_type: "authorization_code"
    )

    response = Net::HTTP.get_response(uri)
    data     = JSON.parse(response.body)

    Rails.logger.info "[MpOauth] token response: #{data.except('access_token').inspect}"

    return nil if data["errcode"].present? && data["errcode"] != 0

    data
  rescue => e
    Rails.logger.error "[MpOauth] fetch_token_data error: #{e.message}"
    nil
  end
end
