class Transfer < ApplicationRecord
  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  validates :user_id, :amount_cents, :idempotency_key, :status, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :idempotency_key, uniqueness: { case_sensitive: false }
end
