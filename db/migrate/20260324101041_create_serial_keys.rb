class CreateSerialKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :serial_keys do |t|
      t.string :serial_key
      t.integer :user_id
      t.string :plan
      t.datetime :activated_at
      t.datetime :expires_at
      t.text :notes

      t.timestamps
    end

    add_index :serial_keys, :serial_key, unique: true
  end
end
