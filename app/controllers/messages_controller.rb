class MessagesController < ApplicationController
  before_action :find_ticket,
                :ensure_ticket_is_replyable
  def create
    @message = @ticket.messages.create!(
      user: current_user,
      role: :customer,
      content: message_params[:content]
    )
    ProcessSupportMessageJob.perform_later(@message.id)

    redirect_to ticket_path(@ticket)
  end

  private

  def find_ticket
    @ticket = current_user.tickets.find(params[:ticket_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def ensure_ticket_is_replyable
    return unless @ticket.resolved?

    redirect_to ticket_path(@ticket),
                alert: "This ticket has already been resolved."
  end
end
