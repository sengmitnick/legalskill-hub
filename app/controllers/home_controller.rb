class HomeController < ApplicationController
  include HomeDemoConcern
  before_action :require_profile_complete, if: :user_signed_in?

  def index
    # 性能优化：所有关联一次性 includes，消除 N+1
    @featured_skills  = Rails.cache.fetch("home:featured_skills", expires_in: 10.minutes) do
      Skill.includes(:category).order(download_count: :desc).limit(6).to_a
    end
    @skill_categories = Rails.cache.fetch("home:skill_categories", expires_in: 10.minutes) do
      Category.for_skill.order(:name).to_a
    end
    @hero_video_url   = SiteSetting.cached("hero_video_url")
    @hero_video_title = SiteSetting.cached("hero_video_title").presence || "青狮龙虾快速上手"
    @install_cmd_mac   = SiteSetting.cached("install_cmd_mac")
    @install_cmd_win   = SiteSetting.cached("install_cmd_win")
    @uninstall_cmd_mac = SiteSetting.cached("uninstall_cmd_mac")
    @uninstall_cmd_win = SiteSetting.cached("uninstall_cmd_win")
    @delivered_skills = Rails.cache.fetch("home:delivered_skills", expires_in: 5.minutes) do
      DeliveredSkill.ordered.to_a
    end
    @offline_classes  = Rails.cache.fetch("home:offline_classes", expires_in: 5.minutes) do
      OfflineClass.upcoming.where(status: ["open", "full"]).to_a
    end

    # 当前用户的方案三资格（已付款订单，不缓存——用户相关数据）
    if user_signed_in?
      @plan3_order = current_user.wechat_orders.paid.plan3.order(created_at: :desc).first
    end
  end
end
