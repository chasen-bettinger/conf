# frozen_string_literal: true

class CreateCrownJewelPermissions < ActiveRecord::Migration[7.0]
  def up
    create_table :crown_jewel_permissions do |t|
      t.bigint :crown_jewel_id, null: false
      t.bigint :role_id, null: false
      t.bigint :permission_id, null: false
      t.string :access_type, null: false
      t.boolean :is_authorized, null: false
      t.text :justification, null: false

      t.timestamps
    end

    add_index :crown_jewel_permissions, :crown_jewel_id
    add_index :crown_jewel_permissions, :role_id
    add_index :crown_jewel_permissions, :permission_id
  end

  def down
    drop_table :crown_jewel_permissions
  end
end
