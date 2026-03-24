class AddPaidAtToWechatOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :wechat_orders, :paid_at, :datetime

  end
end
