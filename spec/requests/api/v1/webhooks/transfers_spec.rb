require 'rails_helper'

RSpec.describe "Api::V1::Webhooks::Transfers", type: :request do
  let!(:transfer) { create(:transfer, status: :processing) }

  describe "POST /api/v1/webhooks/transfers/transfer_result" do
    context 'con una transferencia existente' do
      it 'retorna HTTP 200 cuando el servicio procesa una nueva actualización' do
        post "/api/v1/webhooks/transfers/transfer_result", params: { 
          transfer_id: transfer.id, 
          status: "success" 
        }

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("completed")
        expect(json_response["message"]).to eq("Transferencia actualizada con éxito.")
      end

      it 'retorna HTTP 200 con mensaje de duplicado si vuelve a llegar el mismo webhook' do
        transfer.update!(status: :completed)

        post "/api/v1/webhooks/transfers/transfer_result", params: { 
          transfer_id: transfer.id, 
          status: "success" 
        }

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Webhook procesado previamente.")
      end
    end

    context 'con una transferencia que NO existe en el sistema' do
      it 'retorna HTTP 404 Not Found de forma controlada' do
        post "/api/v1/webhooks/transfers/transfer_result", params: { 
          transfer_id: 999999,
          status: "success" 
        }

        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Transferencia no encontrada")
      end
    end
  end
end
