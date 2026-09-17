user = User.find_or_create_by(
  name: "Demo Customer",
  email: "demo@example.com"
)

ticket = user.tickets.create!(
  subject: "Charged twice for my subscription",
  status: :open,
  priority: :high
)

ticket.messages.create!(
  user: user,
  role: :customer,
  content: "I was charged twice for my subscription."
)

ticket.messages.create!(
  user: user,
  role: :customer,
  content: "The second charge appeared yesterday."
)

subscription = user.subscriptions.find_or_create_by!(plan_name: "Pro") do |record|
  record.amount = 49.00
  record.currency = "USD"
  record.current_period_start = Date.current.beginning_of_month
  record.current_period_end = Date.current.end_of_month
end

invoice = user.invoices.find_or_create_by!(number: "INV-2026-0001") do |record|
  record.subscription = subscription
  record.status = :paid
  record.currency = "USD"
  record.subtotal = 49.00
  record.tax = 0
  record.total = 49.00
  record.due_on = Date.current
end

invoice.invoice_items.find_or_create_by!(description: "Pro subscription") do |item|
  item.quantity = 1
  item.unit_amount = 49.00
  item.amount = 49.00
end

user.payments.find_or_create_by!(transaction_id: "pay_demo_0001") do |payment|
  payment.invoice = invoice
  payment.status = :succeeded
  payment.currency = "USD"
  payment.amount = 49.00
  payment.paid_at = Time.current
end
