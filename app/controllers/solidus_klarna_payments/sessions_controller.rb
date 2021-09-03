# frozen_string_literal: true

module SolidusKlarnaPayments
  class SessionsController < ::Spree::StoreController
    def create
      if current_order.klarna_session_expired?
        klarna_payment_method.gateway.create_session(klarna_order(skip_personal_data: true).to_hash).tap do |response|
          raise response.inspect unless response.success?

          current_order.update_klarna_session(
            session_id: response.session_id,
            client_token: response.client_token
          )
        end
      else
        klarna_payment_method.gateway.update_session(
          current_order.klarna_session_id,
          klarna_order(skip_personal_data: true).to_hash
        ).tap do |response|
          raise response.inspect unless response.success?

          current_order.update_klarna_session_time
        end
      end

      if current_order.klarna_client_token.blank?
        raise "Could not create or update Klarna session for order '#{current_order.number}'."
      end

      render json: {
        token: current_order.reload.klarna_client_token,
      }
    end

    def show
      render json: {
        status: !current_order.klarna_session_expired?,
        token: current_order.klarna_client_token,
        data: klarna_order.to_hash,
      }
    end

    def order_addresses
      addresses = {
        billing_address: SolidusKlarnaPayments::AddressSerializer.new(current_order.billing_address).to_hash,
        shipping_address: SolidusKlarnaPayments::AddressSerializer.new(current_order.shipping_address).to_hash
      }

      addresses.update(addresses) do |_k, v|
        { email: current_order.email }.merge(v)
      end

      render json: klarna_order.addresses
    end

    def klarna_update_session
      @order.klarna_payments.last.source.update(authorization_token: params[:token])
      render json: { status: "ok" }
    end

    private

    def klarna_order(skip_personal_data: false)
      order = current_order.to_klarna(klarna_payment_method.options[:country])
      order.options = klarna_options
      order.skip_personal_data = skip_personal_data
      order.design = klarna_payment_method.options[:design]
      order.store = current_store
      order
    end

    def klarna_payment_method
      @klarna_payment_method ||= ::Spree::PaymentMethod.find_by(id: klarna_payment_method_id, type: 'Spree::PaymentMethod::KlarnaCredit')
    end

    def klarna_options
      klarna_payment_method.options.select do |key, value|
        key.to_s.start_with?("color_", "radius_") && value.present?
      end
    end

    def klarna_payment_method_id
      params[:klarna_payment_method_id] || current_order.payments.where(source_type: 'Spree::KlarnaCreditPayment').last.payment_method_id
    end
  end
end
