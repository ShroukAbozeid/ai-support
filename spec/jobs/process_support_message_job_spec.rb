require 'rails_helper'

RSpec.describe ProcessSupportMessageJob, type: :job do
  let(:user) { create(:user) }
  let(:ticket) { create(:ticket, user: user, status: :open) }
  let!(:message) { create(:message, ticket: ticket, user: user) }

  describe '#perform' do
    it 'marks the ticket as in progress, processes it, and then waits for the customer' do
      agent = instance_double(Ai::SupportAgent)

      expect(Ai::SupportAgent).to receive(:new).with(ticket).and_return(agent)
      expect(agent).to receive(:call)

      described_class.new.perform(message.id)

      expect(ticket.reload.status).to eq('waiting_for_customer')
    end

    it 'reschedules itself when the ticket is already in progress' do
      ticket.update!(status: :in_progress)

      scheduled_job = instance_double(ActiveJob::ConfiguredJob)

      expect(Ai::SupportAgent).not_to receive(:new)
      expect(described_class).to receive(:set).with(wait: 10.seconds).and_return(scheduled_job)
      expect(scheduled_job).to receive(:perform_later).with(message.id)

      described_class.new.perform(message.id)
    end
  end
end
