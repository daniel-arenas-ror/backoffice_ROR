module Api
  module V1
    module Webhooks
      class TransfersController < BaseController
        def transfer_result
          result = ::ProcessTransferResultService.new(
            transfer_id: params[:transfer_id],
            bank_status: params[:status]
          ).call

          if result[:duplicate]
            render json: { status: result[:status], message: "Webhook procesado previamente." }, status: :ok
          else
            render json: { status: result[:status], message: "Transferencia actualizada con éxito." }, status: :ok
          end

        rescue ActiveRecord::RecordNotFound
          render json: { error: "Transferencia no encontrada" }, status: :not_found
        rescue ::ProcessTransferResultService::UnknownStatusError => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error "--- [WEBHOOK CRITICAL ERROR] #{e.message} ---"
          render json: { error: "Error interno del servidor" }, status: :internal_server_error
        end
      end
    end
  end
end
