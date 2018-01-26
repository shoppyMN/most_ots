require 'net/http'
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

    attr_accessor :cipher_key, :cipher_iv

    # @param [Hash] options
    def initialize(options = {})
      logger.debug('MostOts Service API Initializing')
      @base_params = {
        lang: options.fetch(:lang) { '0' },
        srcInstId: options.fetch(:src_inst_id) { ENV['SRC_INST_ID'] }
      }
      @protocol_version = options.fetch(:protocol_version) { '05' }
      @most_pem_location = options.fetch(:most_pem_location)
      @api_host = options.fetch(:host) { 'http://202.131.242.165:9089' }

      @payee_id = options[:payee_id] if options.key?(:payee_id)
      @qr_bank_code = options[:qr_bank_code] if options.key?(:qr_bank_code)
      @qr_account_name = options[:qr_account_name] if options.key?(:qr_account_name)
      @qr_account_number = options[:qr_account_number] if options.key?(:qr_account_number)
      @tran_cur = options[:tran_cur] if options.key?(:tran_cur)
      @pos_no = options[:pos_no] if options.key?(:pos_no)
      @base_params[:channel] = options[:channel] if options.key?(:channel)
      @base_params[:device_mac] = options[:device_mac] if options.key?(:device_mac)
      @base_params[:device_ip] = options[:device_ip] if options.key?(:device_ip)
      @base_params[:device_name] = options[:device_name] if options.key?(:device_name)
      @cipher_key = options[:cipher_key]
      @cipher_iv = options.fetch(:cipher_iv)

      @user_agent = "most_ots/#{VERSION} ruby/#{RUBY_VERSION}"
      @user_agent << " #{options[:app_name]}/#{options[:app_version]}" if options.key?(:app_name) && options.key?(:app_version)
    end

    def purchase_qr(params)
      logger.debug('MostOts Service Purchase QR Called')
      base = {}
      base[:payeeId] = @payee_id unless @payee_id.nil?
      base[:posNo] = @pos_no unless @pos_no.nil?
      base[:tranCur] = @tran_cur unless @tran_cur.nil?
      api_request('/api/mapi/TT3051', base.merge(params))
    end

    def transfer_qr(params)
      logger.debug('MostOts Service Transfer QR Called')
      base = {}
      base[:qrBankCode] = @qr_bank_code unless @qr_bank_code.nil?
      base[:qrAccountName] = @qr_account_name unless @qr_account_name.nil?
      base[:qrAccountNumber] = @qr_account_number unless @qr_account_number.nil?
      base[:tranCur] = @tran_cur unless @tran_cur.nil?
      api_request('/api/mapi/TT3061', params)
    end

    def wait_payment_response(params)
      logger.debug('MostOts Service Waiting Payment Response')
      base = {}
      base[:payeeId] = @payee_id unless @payee_id.nil?
      base[:posNo] = @pos_no unless @pos_no.nil?
      api_request('/api/mapi/TT3064', params)
    end

    def check_qr_payment(params)
      logger.debug('MostOts Service Check QR Payment Called')
      base = {}
      base[:payeeId] = @payee_id unless @payee_id.nil?
      base[:posNo] = @pos_no unless @pos_no.nil?
      base[:tranCur] = @tran_cur unless @tran_cur.nil?
      api_request('/api/mapi/TT3065', params)
    end

    # @param [Object] params
    def purchase_tan(params)
      logger.debug('MostOts Service Purchase Tan Called')
      base = {}
      base[:payeeId] = @payee_id unless @payee_id.nil?
      base[:posNo] = @pos_no unless @pos_no.nil?
      base[:tranCur] = @tran_cur unless @tran_cur.nil?
      api_request('/api/mapi/TT1608', params)
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
      rsa = OpenSSL::PKey::RSA.new File.read @most_pem_location
      key = @cipher_key.nil? ? cipher.random_key : @cipher_key
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
      params = generate_params(params)
      headers = {
        'Content-Type' => 'application/json',
        :Accept => 'application/json',
        'Accept-Charset' => 'utf-8',
        :TT => path.split('TT').last,
        :RS => '00',
        'User-Agent' => @user_agent,
        :PV => @protocol_version
      }
      logger.debug("Service Called With endpoint #{@api_host}#{path} params: #{params}")
      logger.debug("headers: #{headers}")
      req = HTTParty.post(
        "#{@api_host}#{path}",
        body: params,
        headers: headers
      )
      JSON.parse(req.body)
    end

    # @param [Hash] params
    def generate_params(params)
      to_encrypt = {}
      ENCRYPTED_FIELDS.each do |encrypted_key|
        to_encrypt[encrypted_key] = params.delete(encrypted_key) if params.key?(encrypted_key)
      end
      JSON.generate(@base_params.merge(params).merge(encrypt(to_encrypt)))
    end

  end
end