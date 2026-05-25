class CreateTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :transfers do |t|
      t.integer :user_id
      t.integer :amount_cents
      t.string :idempotency_key
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :transfers, :idempotency_key, unique: true
  end
end
