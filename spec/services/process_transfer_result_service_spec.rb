require 'rails_helper'

RSpec.describe ProcessTransferResultService, type: :service do
  let!(:transfer) { create(:transfer, status: :processing) }

  describe '#call' do
    context 'cuando el core bancario reporta un procesamiento exitoso' do
      it 'actualiza el estado de la transferencia a completed y retorna éxito' do
        service = ProcessTransferResultService.new(
          transfer_id: transfer.id,
          bank_status: 'success'
        )
        
        result = service.call

        expect(result[:success]).to be true
        expect(result[:duplicate]).to be false
        expect(result[:status]).to eq(:completed)
        expect(transfer.reload.status).to eq('completed')
      end
    end

    context 'cuando el core bancario reporta un fallo' do
      it 'actualiza el estado de la transferencia a failed' do
        service = ProcessTransferResultService.new(
          transfer_id: transfer.id,
          bank_status: 'error'
        )
        
        result = service.call

        expect(result[:success]).to be true
        expect(result[:status]).to eq(:failed)
        expect(transfer.reload.status).to eq('failed')
      end
    end

    context 'cuando el webhook llega duplicado' do
      it 'no altera el estado y reconoce que es un duplicado de una transferencia completada' do
        transfer.update!(status: :completed)

        service = ProcessTransferResultService.new(
          transfer_id: transfer.id,
          bank_status: 'success'
        )
        
        result = service.call

        expect(result[:success]).to be true
        expect(result[:duplicate]).to be true
        expect(result[:status]).to eq(:completed)
        expect(transfer.reload.status).to eq('completed')
      end

      it 'no altera el estado y reconoce que es un duplicado de una transferencia fallida' do
        transfer.update!(status: :failed)

        service = ProcessTransferResultService.new(
          transfer_id: transfer.id,
          bank_status: 'error'
        )
        
        result = service.call

        expect(result[:duplicate]).to be true
        expect(result[:status]).to eq(:failed)
      end
    end

    context 'cuando el estado enviado por el banco no es reconocido' do
      it 'lanza una excepción de estado desconocido' do
        service = ProcessTransferResultService.new(
          transfer_id: transfer.id,
          bank_status: 'status_raro_del_banco'
        )

        expect { service.call }.to raise_error(ProcessTransferResultService::UnknownStatusError)
      end
    end
  end
end
