class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.wechat_orders.order(created_at: :desc)
  end
end
