class AddWechatFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :wechat_unionid, :string
    add_column :users, :wechat_mp_openid, :string
    add_index :users, :wechat_unionid, unique: true
    add_index :users, :wechat_mp_openid, unique: true
  end
end
