class OrdersController < ApplicationController
  before_action :require_login

  def index
    @orders = current_user.wechat_orders.order(created_at: :desc)
  end
end
