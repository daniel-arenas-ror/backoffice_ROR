module Api
  module V1
    class TransfersController < BaseController
      def create
        t_params = transfers_params
        @transfer = Transfer.create!(
          user_id: t_params[:user_id],
          amount_cents: t_params[:amount],
          idempotency_key: t_params[:idempotency_key],
          status: :pending
        )

        # Si se crea con éxito, encolamos el proceso asíncrono
        ProcessCoreBankTransferJob.perform_later(@transfer.id)

        render json: @transfer, status: :accepted # 202 Accepted para procesos asíncronos

      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        # Si la llave ya existe, recuperamos el registro existente de forma segura
        @transfer = Transfer.find_by!(idempotency_key: t_params[:idempotency_key])
        render json: @transfer, status: :ok # 200 OK informando el estado actual
      end

      private

      def transfers_params
        params.require(:transfer).permit(:user_id, :amount_cents, :idempotency_key)
      end
    end
  end
end
