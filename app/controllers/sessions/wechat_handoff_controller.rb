# Handles the top-level window redirect after WeChat QR login.
# The iframe callback cannot set cookies due to Chrome SameSite policy,
# so it stores a short-lived token in Rails.cache and redirects here.
# This action runs in the main browsing context and can safely set cookies.
class Sessions::WechatHandoffController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def show
    token = params[:token].to_s
    session_id = Rails.cache.read("wechat_login_token:#{token}")

    if session_id.present?
      Rails.cache.delete("wechat_login_token:#{token}")
      cookies.signed.permanent[:session_token] = { value: session_id, httponly: true }
      redirect_to root_path, notice: "微信登录成功"
    else
      redirect_to sign_in_path, alert: "登录已过期，请重新扫码"
    end
  end
end
