FactoryBot.define do
  factory :transfer do
    user_id { 1 }
    amount_cents { 50000 }
    sequence(:idempotency_key) { |n| "unique-uuid-#{n}-#{SecureRandom.uuid}" }
    
    status { :pending }
  end
end
