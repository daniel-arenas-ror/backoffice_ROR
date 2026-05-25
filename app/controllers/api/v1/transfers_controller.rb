module Api
  module V1
    class TransfersController < ApplicationController
      def create
        @transfer = Transfer.create!(t_params)

        # TODO: Si se crea con éxito, encolamos el proceso asíncrono

        render json: @transfer, status: :accepted

      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        @transfer = Transfer.find_by!(idempotency_key: t_params[:idempotency_key])
        render json: @transfer, status: :ok
      end

      private

      def transfers_params
        params.require(:transfer).permit(:user_id, :amount_cents, :idempotency_key)
      end
    end
  end
end
