FactoryGirl.define do
  factory :property_transaction do
    property

    factory :property_transaction_rental do
      transaction_type "rental"
    end

    factory :property_transaction_sales do
      transaction_type "sales"
    end    
  end
end
