class SerialKey < ApplicationRecord
  belongs_to :user

  validates :serial_key, presence: true, uniqueness: true

  # 状态
  def active?
    activated_at.present? && (expires_at.nil? || expires_at > Time.current)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def status_label
    if expired?
      "已过期"
    elsif active?
      "生效中"
    else
      "未激活"
    end
  end

  def status_color
    if expired?
      "text-error"
    elsif active?
      "text-success"
    else
      "text-muted"
    end
  end

  # plan 显示名
  PLAN_LABELS = {
    "plan1" => "社群版",
    "plan2" => "线上课程版",
    "plan3" => "线下课程版",
    "plan4" => "团队内训版"
  }.freeze

  def plan_label
    PLAN_LABELS[plan] || plan
  end
end
