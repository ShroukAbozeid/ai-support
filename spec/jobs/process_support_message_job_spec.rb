require 'rails_helper'

RSpec.describe ProcessSupportMessageJob, type: :job do
  let(:user) { create(:user) }
  let(:ticket) { create(:ticket, user: user, status: :open) }
  let!(:message) { create(:message, ticket: ticket, user: user) }

  describe '#perform' do
    it 'marks the ticket as in progress, processes it, and then waits for the customer' do
      agent = instance_double(Ai::SupportAgent)

      expect(Ai::SupportAgent).to receive(:new).with(
        message: message,
        previous_response_id: nil
      ).and_return(agent)
      expect(agent).to receive(:call)

      described_class.new.perform(message.id)

      expect(ticket.reload.status).to eq('waiting_for_customer')
    end

    it 'passes the latest assistant response ID to the agent' do
      create(
        :message,
        ticket: ticket,
        user: nil,
        role: :assistant,
        content: 'Previous reply',
        open_ai_response_id: 'resp_previous'
      )
      agent = instance_double(Ai::SupportAgent, call: nil)

      expect(Ai::SupportAgent).to receive(:new).with(
        message: message,
        previous_response_id: 'resp_previous'
      ).and_return(agent)

      described_class.new.perform(message.id)
    end

    it 'reschedules a newer message until older customer messages are processed' do
      newer_message = create(:message, ticket: ticket, user: user)
      scheduled_job = instance_double(ActiveJob::ConfiguredJob)

      expect(Ai::SupportAgent).not_to receive(:new)
      expect(described_class).to receive(:set).with(wait: 10.seconds).and_return(scheduled_job)
      expect(scheduled_job).to receive(:perform_later).with(newer_message.id)

      described_class.new.perform(newer_message.id)
    end

    it 'reopens the ticket and propagates processing failures' do
      allow(Ai::SupportAgent).to receive(:new).and_raise(Net::ReadTimeout)

      expect { described_class.new.perform(message.id) }.to raise_error(Net::ReadTimeout)
      expect(ticket.reload).to be_open
    end

    it 'does not process a message that already has an assistant reply' do
      create(
        :message,
        ticket: ticket,
        user: nil,
        role: :assistant,
        content: 'Already answered',
        reply_to_message: message,
        open_ai_response_id: 'resp_answered'
      )

      expect(Ai::SupportAgent).not_to receive(:new)

      described_class.new.perform(message.id)

      expect(ticket.reload).to be_open
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
