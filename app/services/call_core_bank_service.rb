require 'net/http'

class CallCoreBankService
  class BankCommunicationError < StandardError; end

  OPEN_TIMEOUT = 3.freeze
  READ_TIMEOUT = 5.freeze

  def initialize(transfer:)
    @transfer = transfer
    @core_bank_url = URI("http://127.0.0.1:8000")
  end

  def call
    http = Net::HTTP.new(@core_bank_url.host, @core_bank_url.port)
    http.use_ssl = false
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT

    request = Net::HTTP::Post.new(@core_bank_url)
    request['Content-Type'] = 'application/json'
    request['X-Idempotency-Key'] = @transfer.idempotency_key # Pasamos nuestra llave al banco

    request.body = {
      transaction_id: @transfer.id,
      account_id: @transfer.user_id,
      amount_cents: @transfer.amount_cents
    }.to_json

    begin
      response = http.request(request)
      if response.code == "200" || response.code == "201"
        Rails.logger.info "--- [CORE BANK] Solicitud enviada con éxito para Transferencia ##{@transfer.id} ---"
        { success: true }
      else
        raise BankCommunicationError, "El banco respondió con código de error: #{response.code}"
      end

    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      Rails.logger.error "--- [CORE BANK TIMEOUT/ERROR] Fallo conectando al banco: #{e.message} ---"
      raise BankCommunicationError, "Fallo de conexión con el Core Bancario externo: #{e.message}"
    end
  end
end
