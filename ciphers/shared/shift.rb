module Ciphers
  module Shift
    LETTER = /[A-Za-z]/

    def self.shift_char(ch, shift)
      base = ch.ord < 97 ? 65 : 97
      ((ch.ord - base + shift) % 26 + base).chr
    end
  end
end
