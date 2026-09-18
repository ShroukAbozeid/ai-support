module Ai
  module Tools
    class LookupInvoice
      def initialize(user_id:, invoice_number:)
        @user_id = user_id
        @invoice_number = invoice_number
      end

      def call
        @invoice = Invoice.find_by(number: invoice_number, user_id:)
      end

      attr_reader :user_id, :invoice_number, :invoice
    end
  end
end
