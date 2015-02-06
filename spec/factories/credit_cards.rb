FactoryGirl.define do
  factory :credit_card do
    customer {create :customer}
    sequence(:name) {|n| "Name#{n}"}
    sequence(:cardholder_name) {|n| "Cardholder Name#{n}"}
    number "4242424242424242"
    exp_month '11'
    exp_year (Date.current.year + 1).to_s
    cvc {format '%03d', rand(1000)}
  end
end
