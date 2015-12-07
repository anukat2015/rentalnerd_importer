FactoryGirl.define do
  factory :covariance do
    prediction_model_id 1
    row_type "MyString"
    row_neighborhood_id 1
    row_year 1
    row_is_luxurious ""
    col_type "MyString"
    col_neighborhood_id 1
    col_year 1
    col_is_luxurious ""
    coefficient "9.99"
  end

end
