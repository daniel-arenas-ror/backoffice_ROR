class Transfer < ApplicationRecord
  enum status: {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }, _default: :pending


end
