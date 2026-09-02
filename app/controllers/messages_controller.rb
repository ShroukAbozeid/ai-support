class MessagesController < ApplicationController
  before_action :ensure_ticket_is_replyable
  def create
    @ticket = current_user.tickets.find(params[:ticket_id])

    @message = @ticket.messages.create!(
      user: current_user,
      role: :customer,
      content: message_params[:content]
    )

    redirect_to ticket_path(@ticket)
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def ensure_ticket_is_replyable
    return unless @ticket.resolved?

    redirect_to ticket_path(@ticket),
                alert: "This ticket has already been resolved."
  end
end
