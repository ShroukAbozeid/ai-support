class CreateBillingRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan_name, null: false
      t.string :status, null: false, default: "active"
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false, default: "USD"
      t.date :current_period_start, null: false
      t.date :current_period_end, null: false

      t.timestamps
    end
    add_index :subscriptions, [ :user_id, :status ]

    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription, null: true, foreign_key: true
      t.string :number, null: false
      t.string :status, null: false, default: "draft"
      t.string :currency, null: false, default: "USD"
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tax, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.date :due_on

      t.timestamps
    end
    add_index :invoices, :number, unique: true
    add_index :invoices, [ :user_id, :status ]

    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :quantity, null: false
      t.decimal :unit_amount, precision: 12, scale: 2, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false

      t.timestamps
    end

    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.string :transaction_id, null: false
      t.string :status, null: false, default: "pending"
      t.string :currency, null: false, default: "USD"
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.datetime :paid_at

      t.timestamps
    end
    add_index :payments, :transaction_id, unique: true
    add_index :payments, [ :user_id, :status ]
  end
end
