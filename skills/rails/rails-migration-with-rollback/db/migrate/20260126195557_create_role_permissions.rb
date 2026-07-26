# frozen_string_literal: true

class CreateRolePermissions < ActiveRecord::Migration[7.0]
  def up
    create_table :role_permissions do |t|
      t.bigint :role_id, null: false
      t.bigint :permission_id, null: false
      t.string :resource_arn, null: false
      t.json :conditions, null: false, comment: 'JSON data for conditions'
      t.datetime :last_used_at, null: true

      t.timestamps
    end

    add_index :role_permissions, :role_id
    add_index :role_permissions, :permission_id
  end

  def down
    drop_table :role_permissions
  end
end
