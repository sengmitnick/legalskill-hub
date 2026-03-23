class OfflineClassesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_offline_class, only: [:enroll, :unenroll]

  def index
    @offline_classes = OfflineClass.upcoming
  end

  def enroll
    plan3_order = current_user.wechat_orders.paid.plan3.order(created_at: :desc).first

    unless plan3_order
      redirect_to root_path, alert: "需要购买方案三（线下课程）才能报名"
      return
    end

    if @offline_class.enrolled?(current_user)
      redirect_to root_path, alert: "你已经报名了这个班次"
      return
    end

    attendee_count = plan3_order.quantity || 1
    if @offline_class.spots_remaining < attendee_count
      redirect_to root_path, alert: "班次名额不足（剩余 #{@offline_class.spots_remaining} 人）"
      return
    end

    enrollment = @offline_class.offline_class_enrollments.build(
      user: current_user,
      attendee_count: attendee_count
    )

    if enrollment.save
      redirect_to root_path, notice: "报名成功！共报名 #{attendee_count} 人"
    else
      redirect_to root_path, alert: enrollment.errors.full_messages.join("，")
    end
  end

  def unenroll
    enrollment = @offline_class.offline_class_enrollments.find_by(user: current_user)
    if enrollment
      enrollment.destroy
      redirect_to root_path, notice: "已取消报名"
    else
      redirect_to root_path, alert: "未找到报名记录"
    end
  end

  private

  def set_offline_class
    @offline_class = OfflineClass.find(params[:id])
  end
end
