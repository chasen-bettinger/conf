# frozen_string_literal: true

class CreateCrownJewels < ActiveRecord::Migration[7.0]
  def up
    create_table :crown_jewels do |t|
      t.string :resource_type, null: false
      t.string :resource_arn, null: false, unique: true
      t.string :resource_name, null: false
      t.text :description
      t.string :criticality, null: false
      t.decimal :business_value, null: false
      t.integer :current_protection_score, null: false
      t.integer :required_protection_score, null: false
      t.json :compliance_requirements, null: false, comment: 'JSON data for compliance_requirements'
      t.json :metadata, null: false, comment: 'JSON data for metadata'

      t.timestamps
    end

    add_index :crown_jewels, :resource_arn, unique: true
    add_index :crown_jewels, :criticality
  end

  def down
    drop_table :crown_jewels
  end
end
