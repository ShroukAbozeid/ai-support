class AddOpenAiConversationIdToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :open_ai_conversation_id, :string
    add_index :tickets, :open_ai_conversation_id, unique: true
  end
end
