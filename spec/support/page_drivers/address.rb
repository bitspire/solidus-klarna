module PageDrivers
  class BillingForm < SitePrism::Section
    element :first_name, 'input#order_bill_address_attributes_firstname'
    element :last_name, 'input#order_bill_address_attributes_lastname'
    element :address, 'input#order_bill_address_attributes_address1'
    element :city, 'input#order_bill_address_attributes_city'
    element :zipcode, 'input#order_bill_address_attributes_zipcode'
    element :phone, 'input#order_bill_address_attributes_phone'
    element :country, '#order_bill_address_attributes_country_id'
    element :state, '#order_bill_address_attributes_state_id'
  end

  class ShippingForm < SitePrism::Section
    element :shipping_toggle, 'input#order_use_billing'
    element :first_name, 'input#order_ship_address_attributes_firstname'
    element :last_name, 'input#order_ship_address_attributes_lastname'
    element :address, 'input#order_ship_address_attributes_address1'
    element :city, 'input#order_ship_address_attributes_city'
    element :zipcode, 'input#order_ship_address_attributes_zipcode'
    element :phone, 'input#order_ship_address_attributes_phone'
    element :country, '#order_ship_address_attributes_country_id'
    element :state, '#order_ship_address_attributes_state_id'
  end

  class Address < Base
    set_url "/checkout"

    if KlarnaGateway.is_spree? && !KlarnaGateway.up_to_spree?('2.4.99')
      element :continue_button, 'form#checkout_form_address input.btn'
    else
      element :continue_button, 'form#checkout_form_address input.continue'
    end

    section :billing_fields, BillingForm, '#billing'
    section :shipping_fields, ShippingForm, '#shipping'

    def set_address(data, address= :billing)
      case address
      when :billing
        country = Spree::Country.find_by_iso(data[:country_iso])

        while billing_fields.country.value.to_i != country.id do
          billing_fields.country.find(:option, data[:country]).select_option
        end

        billing_fields.first_name.set(data[:first_name])
        billing_fields.last_name.set(data[:last_name])
        billing_fields.address.set(data[:street_address])
        billing_fields.city.set(data[:city])
        billing_fields.zipcode.set(data[:zip])
        billing_fields.phone.set(data[:phone])

        if state = country.states.find_by_name(data[:state])
          while billing_fields.state.value.to_i != state.id do
            billing_fields.state.find(:option, data[:state]).select_option
          end
        end
      when :shipping
        country = Spree::Country.find_by_iso(data[:country_iso])

        shipping_fields.shipping_toggle.click

        while shipping_fields.country.value.to_i != country.id do
          shipping_fields.country.find(:option, data[:country]).select_option
        end

        shipping_fields.first_name.set(data[:first_name])
        shipping_fields.last_name.set(data[:last_name])
        shipping_fields.address.set(data[:street_address])
        shipping_fields.city.set(data[:city])
        shipping_fields.zipcode.set(data[:zip])
        shipping_fields.phone.set(data[:phone])

        if state = country.states.find_by_name(data[:state])
          while shipping_fields.state.value.to_i != state.id do
            shipping_fields.state.find(:option, data[:state]).select_option
          end
        end
      end
    end

    def continue
      scroll_to(continue_button)
      continue_button.click
    end
  end
end
