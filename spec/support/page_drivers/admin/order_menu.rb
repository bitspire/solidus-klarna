module PageDrivers
  module Admin
    class OrderMenu < SitePrism::Section
      element :payments, 'li[data-hook="admin_order_tabs_payments"] a'
      element :customer, 'li[data-hook="admin_order_tabs_customer_details"] a'

      def shipments
        if KlarnaGateway.up_to_spree?('2.4.99') || KlarnaGateway.is_solidus?
          root_element.all('li[data-hook="admin_order_tabs_order_details"]').select{|e| e.text.downcase.match(/shipments/)}.first.find('a')
        else
          root_element.find('li[data-hook="admin_order_tabs_shipment_details"] a')
        end
      end
    end
  end
end
