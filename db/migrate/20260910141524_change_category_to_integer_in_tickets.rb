class ChangeCategoryToIntegerInTickets < ActiveRecord::Migration[8.1]
  def up
    Ticket.where(category: "billing").update_all(category: '0')
    Ticket.where(category: "technical").update_all(category: '1')
    Ticket.where(category: "general").update_all(category: '2')
    change_column :tickets, :category, :integer, using: 'category::integer'
  end

  def down
    change_column :tickets, :category, :string
  end
end
