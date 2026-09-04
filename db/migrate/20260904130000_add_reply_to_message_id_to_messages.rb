class AddReplyToMessageIdToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages,
            :reply_to_message,
            foreign_key: { to_table: :messages },
            index: { unique: true }
  end
end
