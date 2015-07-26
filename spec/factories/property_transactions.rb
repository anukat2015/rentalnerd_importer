FactoryGirl.define do
  factory :property_transaction_rental do
    property_id 1
    transaction_id 1
    transaction_type "rental"
  end

  factory :property_transaction_sales do
    property_id 1
    transaction_id 1
    transaction_type "sales"
  end

end
