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

    context 'Manejo de Concurrencia Extrema (Condiciones de Carrera)' do
      let!(:transfer) { create(:transfer, status: :processing) }

      it 'maneja dos peticiones simultáneas de forma segura sin duplicar el procesamiento' do
        threads = []
        results = []

        results_mutex = Mutex.new 
        start_signal = false

        2.times do
          threads << Thread.new do
            true while !start_signal 

            service = ProcessTransferResultService.new(
              transfer_id: transfer.id,
              bank_status: 'success'
            )
            
            output = service.call

            results_mutex.synchronize do
              results << output
            end
          end
        end

        start_signal = true
        threads.each(&:join)

        expect(transfer.reload.status).to eq('completed')

        # Uno de los hilos tuvo que haber ganado (duplicate: false)
        # El otro hilo tuvo que haber perdido y activado la idempotencia (duplicate: true)
        winners = results.select { |r| r[:duplicate] == false }
        losers = results.select { |r| r[:duplicate] == true }

        expect(winners.count).to eq(1), "Debe haber exactamente 1 hilo ganador que procesó el cambio"
        expect(losers.count).to eq(1), "Debe haber exactamente 1 hilo que fue contenido por la idempotencia"
        
        expect(winners.first[:status]).to eq(:completed)
        expect(losers.first[:status]).to eq(:completed)
      end
    end
  end
end
