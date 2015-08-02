FactoryGirl.define do
  factory :property_transaction_log do
    price 100
    transaction_status "closed"
    date_listed Time.now
    date_rented Time.now
    days_on_market 10

    factory :property_transaction_log_rental do
      transaction_type "rental"
    end

    factory :property_transaction_log_sales do
      transaction_type "sales"
    end

  end
end
