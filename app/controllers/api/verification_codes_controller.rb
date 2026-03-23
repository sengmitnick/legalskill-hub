# 短信验证码接口（AJAX）
# POST /api/verification_codes → 发送验证码
class Api::VerificationCodesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :require_profile_complete, raise: false

  # POST /api/verification_codes
  # params: mobile
  def create
    mobile = params[:mobile].to_s.strip

    unless mobile =~ UserProfile::PHONE_REGEXP
      render json: { message: "手机号格式不正确，请输入 11 位大陆手机号" }, status: :unprocessable_entity
      return
    end

    if UserProfile.where(phone: mobile).where.not(user_id: current_user.id).exists?
      render json: { message: "该手机号已被其他账号使用" }, status: :unprocessable_entity
      return
    end

    vcode = VerificationCode.regenerate!(mobile, purpose: "profile")

    if Rails.env.development?
      render json: { message: "开发模式：验证码为 #{vcode.code}" }, status: :ok
    else
      SmsSender.deliver(mobile, vcode.code)
      render json: { message: "验证码已发送到您的手机" }, status: :ok
    end
  rescue => e
    Rails.logger.error("SmsSender error: #{e.message}")
    render json: { message: "短信发送失败：#{e.message}" }, status: :service_unavailable
  end
end
