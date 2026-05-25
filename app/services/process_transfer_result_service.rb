class ProcessTransferResultService
  class UnknownStatusError < StandardError; end

  def initialize(transfer_id:, bank_status:)
    @transfer_id = transfer_id
    @bank_status = bank_status
  end

  def call
    { success: true, duplicate: false, status: :failed }
  end
end
