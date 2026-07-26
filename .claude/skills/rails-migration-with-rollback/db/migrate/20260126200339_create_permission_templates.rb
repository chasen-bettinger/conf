# frozen_string_literal: true

class CreatePermissionTemplates < ActiveRecord::Migration[7.0]
  def up
    create_table :permission_templates do |t|
      t.string :name, null: false
      t.text :description
      t.string :template_type, null: false
      t.json :permissions_config, null: false, comment: 'JSON data for permissions_config'
      t.json :tags, null: false, comment: 'JSON data for tags'
      t.boolean :is_public, null: false
      t.integer :usage_count, null: false
      t.string :created_by, null: true

      t.timestamps
    end

    add_index :permission_templates, :name
  end

  def down
    drop_table :permission_templates
  end
end
