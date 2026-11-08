require_relative 'registry'
require_relative 'shared/shift'

module Vigenere
  def self.encode(text, key:, count_all: false) = run(text, key, count_all, 1)
  def self.decode(text, key:, count_all: false) = run(text, key, count_all, -1)

  def self.run(text, key, count_all, direction)
    raise ArgumentError, "key must contain only letters A-Z" unless key.match?(/\A[A-Za-z]+\z/)

    shifts = key.downcase.bytes.map { |b| b - 97 }
    pos = 0
    text.gsub(/./m) do |ch|
      if ch.match?(Ciphers::Shift::LETTER)
        out = Ciphers::Shift.shift_char(ch, shifts[pos % shifts.length] * direction)
        pos += 1
        out
      else
        pos += 1 if count_all
        ch
      end
    end
  end
  private_class_method :run
end

Ciphers.register "vigenere", mod: Vigenere, category: "polyalphabetic",
  notes: "Keyword cipher. Key is letters only. Case is preserved.",
  knobs: {
    text:      { type: "string",  required: true },
    key:       { type: "string",  required: true, description: "Keyword, letters only, e.g. lemon" },
    count_all: { type: "boolean", default: false, description: "Count spaces and punctuation when positioning" }
  }
