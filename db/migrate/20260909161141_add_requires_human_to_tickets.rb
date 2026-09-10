class AddRequiresHumanToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :requires_human, :boolean, default: false, null: false
  end
end
