class TicketsController < ApplicationController
 def index
   @tickets = current_user.tickets.order(created_at: :desc)
 end

def show
  @ticket = current_user.tickets.find(params[:id])
  @messages = @ticket.messages.includes(:user).order(:created_at)
end

def new
  @ticket = current_user.tickets.build
  @ticket.messages.build
end

def create
  @ticket = current_user.tickets.build(
    subject: ticket_params[:subject]
  )

  if @ticket.save
    @ticket.messages.create!(
      user: current_user,
      role: :customer,
      content: ticket_params[:message]
    )

    redirect_to @ticket
  else
    render :new, status: :unprocessable_entity
  end
end

private

def ticket_params
 params.require(:ticket).permit(
    :subject,
    :message
  )
end
end
