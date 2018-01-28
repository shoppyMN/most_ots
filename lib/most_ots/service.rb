require 'json'
require 'openssl'
require 'base64'
require 'most_ots/logging'
require 'httparty'

module MostOts
  #
  class Service
    include Logging
    # Fields that needs to be encrypted
    ENCRYPTED_FIELDS = %i[traceNo qrAccountNumber qrCode srcMsisdn tan].freeze
    PROTOCOL_VERSION = '05'.freeze
    
    # SSL cipher key and IV
    attr_accessor :cipher_key, :cipher_iv

    # Base Parameters
    # @return [Hash]
    attr_accessor :base_params
    
    # Most Provided Public Key
    # @return [File] or [String] certificate_string
    attr_accessor :certificate
    
    # Most API Endpoint
    # @return [String] MOST Service HOST
    attr_accessor :api_host
    
    # @param [Hash] options
    def initialize(options = {})
      logger.debug('MostOts Service API Initializing')
      self.base_params = {
        lang: options.fetch(:lang) { '0' },
        srcInstId: options.fetch(:src_inst_id) { ENV['SRC_INST_ID'] },
        channel: options[:channel],
        deviceMac: options[:device_mac],
        deviceIp: options[:device_ip],
        deviceName: options[:device_name],
        payeeId: options[:payee_id],
        qrBankCode: options[:qr_bank_code],
        qrAccountName: options[:qr_account_name],
        qrAccountNumber: options[:qr_account_number],
        tranCur: options[:tran_cur],
        posNo: options[:pos_no]
      }
      self.certificate = options.fetch(:most_cert_file)
      self.api_host = options.fetch(:host) { 'http://202.131.242.165:9089' }
      self.cipher_key = options[:cipher_key]
      self.cipher_iv = options.fetch(:cipher_iv)
    end

    def purchase_qr(params)
      logger.debug('MostOts Service Purchase QR Called')
      # Mandatory Fields
      mf = %i[srcInstId channel lang traceNo payeeId posNo tranAmount tranCur tranDesc]
      # Optional Fields 
      of = %i[billId deviceIP deviceMac deviceName]
      api_request('/api/mapi/TT3051', configure_params(params, mf, of))
    end

    def transfer_qr(params)
      logger.debug('MostOts Service Transfer QR Called')
      # Mandatory Fields
      mf = %i[srcInstId channel lang traceNo qrBankCode qrAccountName qrAccountNumber tranAmount tranCur]
      # Optional Fields
      of = %i[tranDesc]
      api_request('/api/mapi/TT3061', configure_params(params, mf, of))
    end

    def wait_payment_response(params)
      logger.debug('MostOts Service Waiting Payment Response')
      # Mandatory Fields
      mf = %i[srcInstId channel lang qrBankCode qrAccountName qrAccountNumber tranAmount tranCur]
      # Optional Fields
      of = %i[tranDesc]
      api_request('/api/mapi/TT3064', configure_params(params, mf, of))
    end

    def check_qr_payment(params)
      logger.debug('MostOts Service Check QR Payment Called')
      # Mandatory Fields
      mf = %i[srcInstId channel lang traceNo qrCode payeeId posNo billId isCheckQr]
      # Optional Fields
      of = %i[deviceIP deviceMac deviceName]
      api_request('/api/mapi/TT3065', configure_params(params, mf, of))
    end

    # @param [Object] params
    def purchase_tan(params)
      logger.debug('MostOts Service Purchase Tan Called')
      # Mandatory Fields
      mf = %i[srcInstId channel lang traceNo payeeId posNo srcMsisdn tan tranAmount tranCur]
      # Optional Fields
      of = %i[billId tranDesc deviceIP deviceMac deviceName]
      api_request('/api/mapi/TT1608', configure_params(params, mf, of))
    end

    def check_network
      logger.debug('MostOts Checking Network Connection')
    end

    private

    # Encrypts Hash into MOST AES128 encryption
    # @param [Hash or String] data
    # @return [Hash] encrypted hash with signature
    def encrypt(data)
      data = JSON.generate(data) unless data.is_a?(String)
      cipher = OpenSSL::Cipher.new('AES-128-CBC')
      cipher.encrypt
      cipher.iv = @cipher_iv.pack('c*')
      rsa = OpenSSL::PKey::RSA.new self.certificate
      key = self.cipher_key.nil? ? cipher.random_key : self.cipher_key
      cipher.key = key
      {
        SD: Base64.encode64("#{cipher.update(data)}#{cipher.final}"),
        EK: Base64.encode64(rsa.public_encrypt(key)),
        SG: Digest::SHA1.base64digest(data)
      }
    end

    # @param [String] path
    # @param [Hash] params
    # @return [Object] response
    def api_request(path, params = nil)
      params = encrypt_params(params)
      headers = {
        'Content-Type' => 'application/json',
        :Accept => 'application/json',
        'Accept-Charset' => 'utf-8',
        :TT => path.split('TT').last,
        :RS => '00',
        'User-Agent' => user_agent,
        :PV => PROTOCOL_VERSION
      }
      logger.debug("Service Called With endpoint #{self.api_host}#{path} params: #{params}")
      req = HTTParty.post("#{self.api_host}#{path}", body: params, headers: headers)
      JSON.parse(req.body)
    end

    def configure_params(params, mandatory_fields, optional_fields = [])
      params = self.base_params.merge(params)
      processed_params = {}
      required = mandatory_fields.select{|mk| params[mk].nil? }
      if required.any?
        raise "Following mandatory Fields cannot be nil: #{required.join('.')}"
      end
      params.each do |k, v|
        processed_params[k] = v if (mandatory_fields + optional_fields).include?(k) && !v.nil?
      end
      processed_params
    end

    # @param [Hash] params
    # @return [String] json_string
    def encrypt_params(params)
      to_encrypt = {}
      ENCRYPTED_FIELDS.each do |encrypted_key|
        to_encrypt[encrypted_key] = params.delete(encrypted_key) if params.key?(encrypted_key)
      end
      JSON.generate(params.merge(encrypt(to_encrypt)))
    end

    def user_agent
      "most_ots/#{VERSION} ruby/#{RUBY_VERSION}"
    end
  end
end