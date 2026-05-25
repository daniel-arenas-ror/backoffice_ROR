module Api
  module V1
    class TransfersController < BaseController
      before_action :load_transfer, only: [:show]

      def create
        @transfer = Transfer.create!(transfers_params)

        #TODO: Si se crea con éxito, encolamos el proceso asíncrono

        render json: @transfer, status: :accepted

      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        @transfer = Transfer.find_by!(idempotency_key: transfers_params[:idempotency_key])
        render json: @transfer, status: :ok
      end

      def show
        render json: @transfer, status: :ok
      end

      private

      def transfers_params
        params.require(:transfer).permit(:user_id, :amount_cents, :idempotency_key)
      end

      def load_transfer
        @transfer = Transfer.find(params[:id])
      end
    end
  end
end
