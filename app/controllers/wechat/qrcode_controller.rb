# GET /wechat/qrcode  - generates a WeChat temporary QR code for login
# GET /wechat/check   - polls whether a QR code has been scanned; on success
#                       creates a Session and sets the auth cookie
class Wechat::QrcodeController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def show
    service = WechatMpService.new
    data    = service.create_qrcode
    render json: {
      ticket:         data[:ticket],
      qrcode_url:     "https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=#{CGI.escape(data[:ticket])}",
      expire_seconds: data[:expire_seconds]
    }
  rescue => e
    Rails.logger.error("WeChat QR error: #{e.message}")
    render json: { error: "二维码生成失败，请稍后重试" }, status: :service_unavailable
  end

  def check
    ticket  = params[:ticket].to_s.strip
    service = WechatMpService.new
    openid  = service.fetch_scan_result(ticket)

    if openid.blank?
      render json: { status: "pending" }
      return
    end

    user           = User.from_wechat(openid)
    session_record = user.sessions.create!
    cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

    render json: { status: "ok", redirect_url: root_path }
  rescue => e
    Rails.logger.error("WeChat check error: #{e.message}")
    render json: { error: "登录失败，请重试" }, status: :internal_server_error
  end
end
