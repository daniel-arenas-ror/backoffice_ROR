require 'rails_helper'

RSpec.describe Transfer, type: :model do
  describe 'Validaciones de Presencia y Atributos Básicos' do
    subject { build(:transfer) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:amount_cents) }
    it { should validate_presence_of(:idempotency_key) }
    it { should validate_presence_of(:status) }
  end

  describe 'Validaciones de Reglas de Negocio (Monto)' do
    it 'es inválido con un monto igual a cero' do
      transfer = build(:transfer, amount_cents: 0)
      expect(transfer).not_to be_valid
    end
  end

  describe 'Validación de Idempotencia Estricta (Unicidad)' do
    it 'no permite crear dos transferencias con la misma idempotency_key' do
      first_transfer = create(:transfer, idempotency_key: "mismo-uuid")

      # Intentamos armar otra con la misma llave
      duplicate_transfer = build(:transfer, idempotency_key: "mismo-uuid")

      expect(duplicate_transfer).not_to be_valid
    end
  end
end
