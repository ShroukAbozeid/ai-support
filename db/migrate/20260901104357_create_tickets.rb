class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject
      t.integer :status
      t.integer :priority
      t.string :category
      t.text :summary

      t.timestamps
    end

    add_index :tickets, [ :user_id, :status ]
  end
end
