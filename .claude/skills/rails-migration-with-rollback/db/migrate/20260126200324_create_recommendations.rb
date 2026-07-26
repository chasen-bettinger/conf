# frozen_string_literal: true

class CreateRecommendations < ActiveRecord::Migration[7.0]
  def up
    create_table :recommendations do |t|
      t.bigint :role_id, null: false
      t.string :recommendation_type, null: false
      t.string :severity, null: false
      t.string :status, null: false
      t.string :title, null: false
      t.text :description
      t.json :current_state, null: false, comment: 'JSON data for current_state'
      t.json :proposed_state, null: false, comment: 'JSON data for proposed_state'
      t.json :diff_data, null: false, comment: 'JSON data for diff_data'
      t.text :ai_reasoning, null: false
      t.integer :estimated_risk_reduction, null: false
      t.decimal :cost_savings_estimate, null: false
      t.string :created_by, null: false
      t.string :reviewed_by, null: true
      t.datetime :reviewed_at, null: true
      t.datetime :applied_at, null: true

      t.timestamps
    end

    add_index :recommendations, :role_id
    add_index :recommendations, :recommendation_type
    add_index :recommendations, :severity
    add_index :recommendations, :status
  end

  def down
    drop_table :recommendations
  end
end
