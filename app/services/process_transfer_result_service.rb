class ProcessTransferResultService
  class UnknownStatusError < StandardError; end

  def initialize(transfer_id:, bank_status:)
    @transfer_id = transfer_id
    @bank_status = bank_status
  end

  def call
    transfer = Transfer.find(@transfer_id)
    Transfer.transaction do
      transfer.lock!

      if transfer.completed? || transfer.failed?
        return { success: true, duplicate: true, status: transfer.status.to_sym }
      end

      case @bank_status
      when 'success'
        transfer.update!(status: :completed)
        { success: true, duplicate: false, status: :completed }
      when 'error'
        transfer.update!(status: :failed)
        { success: true, duplicate: false, status: :failed }
      else
        raise UnknownStatusError, "Estado del banco desconocido: #{@bank_status}"
      end
    end
  end
end
