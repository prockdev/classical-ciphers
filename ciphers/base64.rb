require_relative 'registry'

module Base64Cipher
  def self.encode(text)
    [text].pack('m0')
  end

  def self.decode(text)
    text.unpack1('m0').force_encoding('UTF-8')
  end
end

Ciphers.register "base64", mod: Base64Cipher, category: "encoding",
  notes: "Standard Base64 with padding. Input and output are UTF-8 text.",
  knobs: {
    text: { type: "string", required: true }
  }
