class AddWechatOpenidToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :wechat_openid, :string
    add_index :users, :wechat_openid, unique: true
  end
end
