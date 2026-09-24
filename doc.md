1. **Why is conversation state stored?**

The ticket stores `open_ai_conversation_id`, which lets later requests continue the same OpenAI conversation instead of sending the entire history every time.

Rails also stores the message history locally. The first AI request builds a summary from Rails messages; later requests use the OpenAI conversation ID.

**Not handled:** There is no recovery strategy if the OpenAI conversation is deleted, expires, becomes unavailable, or diverges from the Rails message history.

2. **Why do I need Rails messages if OpenAI has conversation state?**

Rails messages are the application’s durable source of truth. They are needed for:

- Rendering the ticket UI
- Auditing what the customer and assistant said
- Linking an assistant reply to its customer message
- Preventing duplicate job execution
- Rebuilding prompts if OpenAI state is unavailable
- Supporting provider changes or data exports
- Applying Rails authorization and business rules

OpenAI conversation state is model context, not a complete application record.

**Not handled:** The application does not currently reconcile Rails messages against OpenAI conversation history.

3. **Why use structured outputs instead of JSON prompting?**

The application requests a strict JSON schema:

```ruby
text: {
  format: {
    type: :json_schema,
    strict: true,
    schema: OUTPUT_SCHEMA
  }
}
```

This is more reliable than merely telling the model “return JSON.” The code also parses and validates the response before updating the ticket.

Structured output ensures required fields and allowed enum values such as `category` and `priority`.

**Not handled:** Schema validation does not guarantee that the values are contextually correct. The model could return a valid but inappropriate classification.

4. **Why can’t the AI directly access ActiveRecord?**

Direct database access would allow the model to:

- Read data outside the current customer’s scope
- Modify records without authorization
- Perform destructive or irreversible actions
- Bypass validations and business rules
- Make behavior difficult to audit and test

The current design exposes explicit tools through ToolsHandler. The model can request only the tools declared in `client_tools`.

**Not handled:** Tool execution is still partly trusted. There is no general policy layer, approval workflow, or capability system for AI actions.

5. **How do I authorize AI-requested actions?**

Authorization should happen inside the tool implementation, never in the prompt.

The current lookup tools scope records by `user_id`:

```ruby
Invoice.find_by(number: invoice_number, user_id:)
Subscription.find_by(id: subscription_id, user_id:)
```

`EscalateToHuman` also scopes the ticket by `user_id` before updating it.

**Not handled:**

- There is no authentication system yet; the application uses the first user as the demo customer.
- There are no policy objects such as Pundit policies.
- There is no separate actor or permission context.
- There is no human confirmation step for consequential actions.
- Tool calls are not persisted in an audit log.
- Authorization rules are not centralized across tools.

6. **What happens if OpenAI times out?**

The job retries these failures:

- `Net::ReadTimeout`
- `Net::OpenTimeout`
- Faraday timeout and connection errors
- Faraday server errors
- `Timeout::Error`

The retry configuration allows three attempts with a five-second delay. When processing fails, the ticket is reopened. After retries are exhausted, the discard callback logs the error, creates an application message, and reopens the ticket.

**Not handled:** The OpenAI request may have succeeded remotely even if the response timed out locally. Retrying can therefore create duplicate remote requests or tool actions. There is no OpenAI request idempotency key or reconciliation mechanism.

7. **What happens if the job retries?**

The job runs again with the same message ID.

Before processing, it:

- Skips the message if it already has an assistant reply.
- Locks the ticket.
- Reschedules if another job currently has the ticket `in_progress`.
- Processes pending customer messages in creation order.

After a successful response, the ticket becomes `waiting_for_customer`.

**Not handled:** A retry can repeat external OpenAI calls and tool calls if the first attempt reached OpenAI but failed before Rails saved the assistant reply.

8. **How do I prevent duplicate actions?**

The current code prevents duplicate assistant replies using:

- `reply_to_message_id`
- `message.reply.present?`
- Ticket row locking
- Ordered pending-message processing

This protects the Rails assistant-message record reasonably well.

**Not handled:** It does not provide general idempotency for tool actions or external side effects. For example, future email, refund, payment, or provisioning tools could execute twice during retries. Tool calls should have persisted call IDs and unique idempotency keys.

9. **How do I observe AI failures?**

Current observability includes:

- `Rails.logger.error`
- `report: true` on retryable ActiveJob failures
- An application message shown on the ticket
- Mission Control Jobs at `/jobs` in development

**Not handled:**

- No structured AI event logs
- No metrics for latency, tokens, cost, retries, or failure rate
- No tracing across the Rails job, OpenAI request, and tool calls
- No Sentry or equivalent alerting integration
- No persistent AI failure table
- No correlation ID linking a job, OpenAI response, and tool execution

10. **How do I test deterministic Rails behavior around nondeterministic AI output?**

The current specs stub the OpenAI client and provide fixed responses. They test deterministic application behavior such as:

- Schema and response parsing
- Ticket classification
- Assistant message persistence
- Job status transitions
- Retry and failure handling
- Message ordering
- Duplicate execution
- Concurrent job behavior
- Tool-round limits

This is the correct boundary: tests should not depend on live model output.

**Not handled:** There are no live integration tests against OpenAI, model-quality evaluations, prompt regression tests, or automated checks for whether a response is actually helpful or factually correct.

11. **How do I control token and cost growth?**

The code currently limits:

- Model output to `200` tokens
- Tool rounds to `5`
- The model to `gpt-4.1-mini`

It also avoids resending the full Rails history on every later request by using the OpenAI conversation.

**Not handled:**

- No input-token limit
- No token or cost tracking
- No per-ticket or per-user budget
- No rate limiting
- No maximum message length validation
- No cost limit for retries
- No alert when usage grows unexpectedly

12. **How do I handle a conversation that becomes very long?**

Currently, it is not explicitly handled.

For the first response, the application sends a Rails-generated summary containing all non-application messages up to the current message. That summary can grow indefinitely. Later requests continue the OpenAI conversation, which can also grow indefinitely.

`MAX_OUTPUT_TOKENS` only limits generated output. It does not limit the input context.

A production implementation should add one or more of:

- Message truncation by token budget
- Rolling summaries
- Older-message archival
- Periodic conversation compaction
- A maximum context size
- Starting a new OpenAI conversation with a persisted summary
- Token estimation before sending requests

This is currently the largest unhandled area in the conversation design.