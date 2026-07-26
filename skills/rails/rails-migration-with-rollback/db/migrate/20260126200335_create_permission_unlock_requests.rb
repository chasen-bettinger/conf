# frozen_string_literal: true

class CreatePermissionUnlockRequests < ActiveRecord::Migration[7.0]
  def up
    create_table :permission_unlock_requests do |t|
      t.bigint :user_id, null: true
      t.string :user_identifier, null: false
      t.bigint :role_id, null: false
      t.bigint :permission_id, null: false
      t.string :resource_arn, null: false
      t.text :reason, null: false
      t.string :status, null: false
      t.integer :duration_minutes, null: false
      t.string :approved_by, null: true
      t.datetime :approved_at, null: true
      t.datetime :expires_at, null: true
      t.datetime :auto_revoked_at, null: true
      t.json :context, null: false, comment: 'JSON data for context'

      t.timestamps
    end

    add_index :permission_unlock_requests, :user_identifier
    add_index :permission_unlock_requests, :role_id
    add_index :permission_unlock_requests, :permission_id
    add_index :permission_unlock_requests, :status
    add_index :permission_unlock_requests, :expires_at
  end

  def down
    drop_table :permission_unlock_requests
  end
end
