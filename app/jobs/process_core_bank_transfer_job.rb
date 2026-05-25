class ProcessCoreBankTransferJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 3, wait: :exponentially_longer do |job, error|
    transfer = Transfer.find(job.arguments.first)
    transfer.update!(status: :failed)
    Rails.logger.error "--- [JOB CRÍTICO] Transferencia #{transfer.id} falló definitivamente tras 3 intentos. ---"
  end

  def perform(transfer_id)
    @transfer = Transfer.find(transfer_id)
    return unless @transfer.pending?

    Transfer.transaction do
      @transfer.lock!
      @transfer.update!(status: :processing)
    end

    # TODO: call bank API
  end
end
