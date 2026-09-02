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
