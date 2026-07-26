# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[7.0]
  def up
    create_table :roles do |t|
      t.string :name, null: false, unique: true
      t.text :description
      t.string :arn, null: false
      t.string :service_type, null: false
      t.string :risk_level, null: false
      t.integer :privilege_score, null: false
      t.boolean :is_active, null: false
      t.string :aws_role_id, null: false
      t.json :metadata, null: false, comment: 'JSON data for metadata'

      t.timestamps
    end

    add_index :roles, :name, unique: true
    add_index :roles, :risk_level
  end

  def down
    drop_table :roles
  end
end
