class AddOpenAiResponseIdToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :open_ai_response_id, :string
    add_index :messages, :open_ai_response_id
  end
end
