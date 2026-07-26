# frozen_string_literal: true

class CreatePermissions < ActiveRecord::Migration[7.0]
  def up
    create_table :permissions do |t|
      t.string :action, null: false, unique: true
      t.string :service, null: false
      t.string :access_level, null: false
      t.boolean :is_dangerous, null: false
      t.integer :danger_score, null: false
      t.text :danger_reason, null: false
      t.datetime :last_analyzed_at, null: false

      t.timestamps
    end

    add_index :permissions, :action, unique: true
    add_index :permissions, :service
    add_index :permissions, :is_dangerous
  end

  def down
    drop_table :permissions
  end
end
