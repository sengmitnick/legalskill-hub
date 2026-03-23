class WechatOrder < ApplicationRecord
  belongs_to :user, optional: true

  STATUSES = %w[pending paid failed closed].freeze
  PLANS = %w[plan1 plan2 plan3 plan4].freeze

  validates :out_trade_no, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :plan3, -> { where(plan: "plan3") }

  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }
  scope :recent, -> { order(created_at: :desc) }

  def paid?
    status == "paid"
  end

  def pending?
    status == "pending"
  end

  def amount_yuan
    amount / 100.0
  end

  def plan3?
    plan == "plan3"
  end

  # 动态生成订单展示标题（根据 plan + quantity）
  PLAN_LABELS = {
    "plan1" => "社群版",
    "plan2" => "线上课程",
    "plan3" => "线下课程",
    "plan4" => "团队线下内训"
  }.freeze

  def display_description
    label = PLAN_LABELS[plan] || plan.to_s
    qty   = quantity.presence || 1
    "青狮龙虾 · #{qty}人 · #{label} + 1 年期使用权"
  end
end
