class CreateAiRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_runs do |t|
      t.references :message, null: false, foreign_key: true, index: { unique: true }
      t.string :open_ai_response_id
      t.string :open_ai_conversation_id
      t.string :error_type
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :status

      t.timestamps
    end
  end
end
