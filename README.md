# AI Support

AI Support is a Rails application for managing customer support tickets. Customers can create tickets and add replies; each customer message is processed asynchronously by an OpenAI-powered support agent. Ticket history is sent to the agent on the first message, and later messages continue the same OpenAI response conversation.

## Features

- Create and view support tickets.
- Set ticket status (`open`, `in_progress`, `waiting_for_customer`, or `resolved`) and priority (`low`, `medium`, `high`, or `urgent`).
- Add customer replies while a ticket is not resolved.
- Process support messages through Solid Queue.
- Store AI replies and OpenAI response IDs so later replies can continue the conversation.
- Broadcast new messages to the ticket view with Turbo Streams.

The current application uses a demo customer account. `ApplicationController` selects the first user in the database, or creates `Demo Customer` (`demo@example.com`) when no user exists. There is no authentication flow yet.

## Requirements

- Ruby 3.4.9
- PostgreSQL 9.5 or newer
- Bundler
- An OpenAI API key

The application uses Rails 8.1, Puma, PostgreSQL, import maps, Hotwire, Solid Cache, Solid Queue, and Solid Cable. Foreman is installed automatically by `bin/dev` when it is not already available.

## Setup

1. Install PostgreSQL and make sure the local server is running.
2. Set the OpenAI API key:

	```sh
	export OPENAI_KEY="your-openai-api-key"
	```

	`OPENAI_KEY` is required when the AI client is initialized. For local development, it can also be loaded through `dotenv-rails` from a local `.env` file. Do not commit that file.

3. Install dependencies and prepare the databases:

	```sh
	bin/setup --skip-server
	```

	This installs Ruby dependencies and prepares the primary, queue, and cable databases. To recreate the databases and seed them again, run `bin/setup --reset --skip-server`.

4. Start the development application:

	```sh
	bin/dev
	```

	Visit <http://localhost:3000>. The development process runs the Rails web server and the Solid Queue worker defined in `Procfile.dev`.

The seed data creates a demo customer and an example high-priority ticket:

```sh
bin/rails db:seed
```

## How It Works

1. A customer creates a ticket or posts a reply.
2. Rails enqueues `ProcessSupportMessageJob`.
3. The job locks the ticket, prevents concurrent processing, and marks it `in_progress`.
4. `Ai::SupportAgent` calls the OpenAI Responses API using `gpt-4.1-mini`.
5. The assistant response is saved as a message and linked to the customer message that produced it.
6. The ticket changes to `waiting_for_customer`.

Transient read timeouts are retried up to three times. OpenAI API errors are logged and recorded as an application message for the customer.

## Useful Commands

```sh
# Start web and background-job processes
bin/dev

# Run the full RSpec suite
bundle exec rspec

# Run one spec file
bundle exec rspec spec/jobs/process_support_message_job_spec.rb

# Run Rails security and dependency checks
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit

# Check Ruby style
bin/rubocop

# Open the Rails console
bin/rails console
```

The Solid Queue dashboard is available at <http://localhost:3000/jobs> in development.

## Routes

- `/` - ticket list
- `/tickets/new` - create a ticket
- `/tickets/:id` - view a ticket and its messages
- `/up` - Rails health check
- `/jobs` - Solid Queue dashboard in development

## Testing

RSpec uses the `ai_support_test` PostgreSQL database. To run tests locally, ensure PostgreSQL is running and execute:

```sh
RAILS_ENV=test bundle exec rspec
```

The CI workflow also runs Brakeman, Bundler Audit, Importmap Audit, RuboCop, and the RSpec suite against PostgreSQL.

## Deployment

The included `Dockerfile` builds a production image for Ruby 3.4.9 and exposes port 80. It expects a production database password through `AI_SUPPORT_DATABASE_PASSWORD` and a Rails master key at runtime.

Build and run the image manually:

```sh
docker build -t ai_support .
docker run --rm -p 80:80 \
  -e RAILS_MASTER_KEY="your-rails-master-key" \
  -e AI_SUPPORT_DATABASE_PASSWORD="your-database-password" \
  -e OPENAI_KEY="your-openai-api-key" \
  ai_support
```

For production deployments, the repository is configured for Kamal. Configure the production database, Rails credentials, and environment variables before deploying.
