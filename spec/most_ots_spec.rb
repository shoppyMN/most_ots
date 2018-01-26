RSpec.describe MostOts do
  MostOts.logger.level = Logger::DEBUG
  s = MostOts::Service.new(
    most_cert_file: Base64.decode64(ENV['MOST_CERT']), # Random Public key just for test
    cipher_key: ENV['TEST_CIPHER_KEY'],
    cipher_iv: Base64.decode64(ENV['TEST_CIPHER_IV']).unpack('c*'),
    src_inst_id: ENV['SRC_INST_ID'],
    channel: '20',
    lang: '0',
    tran_cur: 'MNT',
    pos_no: '1234',
    payee_id: ENV['PAYEE_ID'],
    qr_account_name: ENV['QR_ACCOUNT_NAME'],
    qr_account_number: ENV['QR_ACCOUNT_NUMBER'],
    qr_bank_code: ENV['QR_BANK_CODE'],
    protocol_version: '05'
  )

  it 'Check Encryption' do
    sample_data = JSON.generate(hello: 'world')
    encrypted_data = s.send(:encrypt, sample_data)
    expect(sample_data).to(eq(decrypt(encrypted_data)))
  end

  it 'Check Purchase QR' do
    resp = s.purchase_qr(
      traceNo: '2017052405430504',
      billId: 'travis-ci',
      tranAmount: 2,
      tranDesc: 'Travis ci unit test'
    )
    expect(resp['traceNo']).to(eq('2017052405430504'))
  end

  def decrypt(encrypted_data)
    data = Base64.decode64(encrypted_data[:SD])
    decipher = OpenSSL::Cipher.new('AES-128-CBC')
    decipher.decrypt
    decipher.key = ENV['TEST_CIPHER_KEY']
    decipher.iv = Base64.decode64(ENV['TEST_CIPHER_IV'])
    decipher.update(data) + decipher.final
  end

end
