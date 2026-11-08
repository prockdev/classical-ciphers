require_relative 'registry'
require_relative 'shared/shift'

module Rot13
  def self.encode(text)
    text.gsub(Ciphers::Shift::LETTER) { |ch| Ciphers::Shift.shift_char(ch, 13) }
  end

  def self.decode(text) = encode(text)
end

Ciphers.register "rot13", mod: Rot13, category: "substitution",
  notes: "Caesar fixed at 13. Encoding and decoding are the same operation.",
  knobs: { text: { type: "string", required: true } }
