require 'rails_helper'

RSpec.describe ProcessSupportMessageJob, type: :job do
  let(:user) { create(:user) }
  let(:ticket) { create(:ticket, user: user, status: :open) }
  let!(:message) { create(:message, ticket: ticket, user: user) }

  describe '#perform' do
    it 'marks the ticket as in progress, processes it, and then waits for the customer' do
      agent = instance_double(Ai::SupportAgent)

      expect(Ai::SupportAgent).to receive(:new).with(
        message: message
      ).and_return(agent)
      expect(agent).to receive(:call)

      described_class.new.perform(message.id)

      expect(ticket.reload.status).to eq('waiting_for_customer')
      expect(message.reload.ai_run).to be_processing
      expect(message.ai_run.started_at).to be_present
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
        message: message
      ).and_return(agent)

      described_class.new.perform(message.id)
    end

    it 'reschedules a newer message until older customer messages are processed' do
      newer_message = create(:message, ticket: ticket, user: user)
      scheduled_job = instance_double(ActiveJob::ConfiguredJob)

      expect(Ai::SupportAgent).not_to receive(:new)
      expect(described_class).to receive(:set).with(wait: 5.seconds).and_return(scheduled_job)
      expect(scheduled_job).to receive(:perform_later).with(message.id)

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

    it 'handles an OpenAI API error and reopens the ticket' do
      allow(Ai::SupportAgent).to receive(:new).and_raise(OpenAI::Error, 'API failed')

      expect { described_class.new.perform(message.id) }.not_to raise_error

      expect(ticket.reload).to be_open
      expect(message.reload.ai_run).to have_attributes(
        status: 'failed',
        error_type: 'OpenAI::Error',
        error_message: 'API failed'
      )
      expect(ticket.messages.where(role: :app).last.content).to include('encountered an error')
    end

    it 'handles a conversation creation failure and does not call responses' do
      conversations = instance_double('Conversations')
      client = instance_double('OpenAI::Client', conversations: conversations)
      allow(Ai::Client).to receive(:new).and_return(client)
      allow(conversations).to receive(:create).and_raise(OpenAI::Error, 'conversation failed')
      responses = instance_double('Responses')
      allow(responses).to receive(:create)
      allow(client).to receive(:responses).and_return(responses)

      expect { described_class.new.perform(message.id) }.not_to raise_error

      expect(responses).not_to have_received(:create)
      expect(ticket.reload).to be_open
      expect(ticket.messages.where(role: :app).last.content).to include('encountered an error')
    end

    it 'reopens the ticket and reports a timeout after retries are discarded' do
      job = described_class.new(message.id)
      expect(Ai::SupportAgent).to receive(:new).and_raise(Net::ReadTimeout)

      expect { job.perform(message.id) }.to raise_error(Net::ReadTimeout)
      expect(ticket.reload).to be_open
      expect(ticket.messages.where(role: :app)).to be_empty
      expect(message.reload.ai_run).to have_attributes(
        status: 'processing',
        error_type: 'Net::ReadTimeout'
      )

      described_class.after_discard_procs.first.call(job, Net::ReadTimeout.new)

      expect(ticket.reload).to be_open
      expect(message.reload.ai_run).to have_attributes(
        status: 'failed',
        error_type: 'Net::ReadTimeout'
      )
      expect(ticket.messages.where(role: :app).last.content).to include('encountered an error')
    end

    it 'reopens the ticket when processing fails after OpenAI responds' do
      response = {
        'id' => 'resp_after_failure',
        'output' => [ {
          'type' => 'message',
          'content' => [ {
            'type' => 'output_text',
            'text' => { category: 'general', priority: 'medium', requires_human: false,
                        message: 'A reply.' }.to_json
          } ]
        } ]
      }
      responses = instance_double('Responses', create: response)
      conversations = instance_double('Conversations', create: { 'id' => 'conv_after_failure' })
      client = instance_double('OpenAI::Client', conversations: conversations, responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)
      allow(Ai::TicketClassifier).to receive(:new).and_raise(ActiveRecord::RecordInvalid.new(ticket))

      expect { described_class.new.perform(message.id) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(responses).to have_received(:create)
      expect(ticket.reload).to be_open
      expect(message.reload.ai_run).to have_attributes(
        status: 'completed',
        error_type: 'ActiveRecord::RecordInvalid'
      )
    end

    it 'reopens the ticket when saving the assistant message fails' do
      response = {
        'id' => 'resp_persistence_failure',
        'output' => [ {
          'type' => 'message',
          'content' => [ {
            'type' => 'output_text',
            'text' => { category: 'general', priority: 'medium', requires_human: false,
                        message: 'A reply.' }.to_json
          } ]
        } ]
      }
      responses = instance_double('Responses', create: response)
      conversations = instance_double('Conversations', create: { 'id' => 'conv_persistence_failure' })
      client = instance_double('OpenAI::Client', conversations: conversations, responses: responses)
      allow(Ai::Client).to receive(:new).and_return(client)
      persistence_error = ActiveRecord::RecordInvalid.new(message)
      allow_any_instance_of(Ai::ResponseHandler).to receive(:create_support_message)
        .and_raise(persistence_error)

      expect { described_class.new.perform(message.id) }.to raise_error(ActiveRecord::RecordInvalid)

      expect(responses).to have_received(:create)
      expect(ticket.reload).to be_open
      expect(message.reload.ai_run).to have_attributes(
        status: 'completed',
        error_type: 'ActiveRecord::RecordInvalid'
      )
    end

    it 'processes multiple customer messages in creation order' do
      older_message = message
      newer_message = create(:message, ticket: ticket, user: user)
      processed_ids = []
      allow(Ai::SupportAgent).to receive(:new) do |message:|
        processed_ids << message.id
        agent = instance_double(Ai::SupportAgent)
        allow(agent).to receive(:call) do
          message.ticket.messages.create!(
            user: nil,
            role: :assistant,
            content: 'A reply.',
            reply_to_message: message
          )
        end
        agent
      end

      described_class.new.perform(older_message.id)
      described_class.new.perform(newer_message.id)

      expect(processed_ids).to eq([ older_message.id, newer_message.id ])
      expect(ticket.reload).to be_waiting_for_customer
    end

    it 'does not process a duplicate execution after the assistant reply exists' do
      agent = instance_double(Ai::SupportAgent)
      allow(agent).to receive(:call) do
        message.ticket.messages.create!(
          user: nil,
          role: :assistant,
          content: 'A reply.',
          reply_to_message: message
        )
      end
      expect(Ai::SupportAgent).to receive(:new).once.and_return(agent)

      described_class.new.perform(message.id)
      described_class.new.perform(message.id)

      expect(ticket.reload).to be_waiting_for_customer
    end

    it 'does not recreate an existing AI run when processing is retried' do
      ai_run = create(:ai_run, message: message)
      allow(Ai::SupportAgent).to receive(:new).and_raise(Net::ReadTimeout)

      expect { described_class.new.perform(message.id) }.to raise_error(Net::ReadTimeout)

      expect(message.reload.ai_run).to eq(ai_run)
      expect(AiRun.where(message: message).count).to eq(1)
      expect(ai_run.reload).to be_processing
    end

    it 'reschedules the second of two concurrent jobs' do
      started = Queue.new
      release = Queue.new
      agent = instance_double(Ai::SupportAgent)
      allow(Ai::SupportAgent).to receive(:new).and_return(agent)
      allow(agent).to receive(:call) do
        started << true
        release.pop
      end
      scheduled_job = instance_double(ActiveJob::ConfiguredJob, perform_later: true)
      allow(described_class).to receive(:set).with(wait: 10.seconds).and_return(scheduled_job)

      first_job = Thread.new { described_class.new.perform(message.id) }
      started.pop

      described_class.new.perform(message.id)

      expect(scheduled_job).to have_received(:perform_later).with(message.id)
      release << true
      first_job.join
      expect(ticket.reload).to be_waiting_for_customer
    end

    it 'ignores customer messages that already have replies when selecting pending work' do
      answered_message = create(:message, ticket: ticket, user: user)
      create(
        :message,
        ticket: ticket,
        user: nil,
        role: :assistant,
        content: 'Answered.',
        reply_to_message: answered_message
      )

      expect(described_class.new.pending_messages(ticket)).to eq([ message ])
    end
  end
end
