module Api
  module V1
    module Webhooks
      class TransfersController < BaseController
        def transfer_result
          return render json: {}, status: :ok
        end
      end
    end
  end
end
