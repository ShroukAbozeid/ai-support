class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role
      t.text :content

      t.timestamps
    end

    add_index :messages, [ :ticket_id, :created_at ]
  end
end
