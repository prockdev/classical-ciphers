require_relative 'registry'

module Caesar
  LETTER = /[A-Za-z]/

  def self.encode(text, key: 3, step: 0, count_all: false, preserve_case: true)
    transform(text, key, step, count_all, preserve_case, 1)
  end

  def self.decode(text, key: 3, step: 0, count_all: false, preserve_case: true)
    transform(text, key, step, count_all, preserve_case, -1)
  end

  def self.transform(text, key, step, count_all, preserve_case, direction)
    pos = 0
    out = text.each_char.map do |ch|
      is_letter = ch.match?(LETTER)
      shifted = ch

      if is_letter
        shift = (key + pos * step) * direction
        base = ch.ord < 97 ? 65 : 97
        shifted = ((ch.ord - base + shift) % 26 + base).chr
        shifted = shifted.upcase unless preserve_case
      end

      pos += 1 if is_letter || count_all
      shifted
    end
    out.join
  end
  private_class_method :transform
end

Ciphers.register "caesar", mod: Caesar, category: "substitution",
  notes: "ASCII letters only. Shifts wrap modulo 26. Decode with the same settings used to encode.",
  knobs: {
    text:          { type: "string",  required: true },
    key:           { type: "integer", default: 3, description: "Starting shift" },
    step:          { type: "integer", default: 0, description: "Added to the shift for each letter" },
    count_all:     { type: "boolean", default: false, description: "Count spaces and punctuation when positioning" },
    preserve_case: { type: "boolean", default: true, description: "Keep upper and lower case (false returns uppercase)" }
  }
