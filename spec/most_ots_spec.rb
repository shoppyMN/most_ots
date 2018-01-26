RSpec.describe MostOts do
  MostOts.logger.level = Logger::DEBUG

  TEST_CIPHER_KEY = '1234567891123456'.freeze

  # Random Bytes just for Testing
  TEST_CIPHER_IV = [0x9C, 0xC6, 0x60, 0xD0, 0x1A, 0x13, 0x2C, 0x62, 0x68, 0x79,
                    0x92, 0x84, 0x71, 0xA6, 0x05, 0x13].freeze

  s = MostOts::Service.new(
    most_pem_location: 'test/random.cert', # Random Public key just for test
    cipher_key: TEST_CIPHER_KEY,
    cipher_iv: TEST_CIPHER_IV,
    src_inst_id: '300000',
    channel: '20',
    lang: '0',
    tran_cur: 'MNT',
    pos_no: '1234',
    payee_id: '0',
    qr_account_name: '0',
    qr_account_number: '0',
    qr_bank_code: '0',
    protocol_version: '05'
  )

  it 'Check Encryption' do
    sample_data = JSON.generate(hello: 'world')
    encrypted_data = s.send(:encrypt, sample_data)
    expect(sample_data).to(eq(decrypt(encrypted_data)))
  end

  # it 'Check Purchase QR' do
  #   resp = s.purchase_qr(
  #     traceNo: '2017052405430504',
  #     tranAmount: '1',
  #     tranDesc: 'Test: QR Purchase'
  #   )
  #   expect(resp['responseCode']).to(eq('0'))
  # end
  #
  # it 'Check Transfer Qr' do
  #   resp = s.transfer_qr(
  #     traceNo: '2017052405430504',
  #     tranAmount: '1',
  #     tranDesc: 'Test QR Transfer'
  #   )
  #   expect(resp['responseCode']).to(eq('0'))
  # end

  def decrypt(encrypted_data)
    data = Base64.decode64(encrypted_data[:SD])
    decipher = OpenSSL::Cipher.new('AES-128-CBC')
    decipher.decrypt
    decipher.key = TEST_CIPHER_KEY
    decipher.iv = TEST_CIPHER_IV.pack('c*')
    decipher.update(data) + decipher.final
  end

end
