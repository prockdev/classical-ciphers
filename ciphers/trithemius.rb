require_relative 'registry'
require_relative 'shared/shift'

module Trithemius
  def self.encode(text, key: 0, step: 1) = run(text, key, step, 1)
  def self.decode(text, key: 0, step: 1) = run(text, key, step, -1)

  def self.run(text, key, step, direction)
    pos = -1
    text.gsub(Ciphers::Shift::LETTER) do |ch|
      pos += 1
      Ciphers::Shift.shift_char(ch, (key + pos * step) * direction)
    end
  end
  private_class_method :run
end

Ciphers.register "trithemius", mod: Trithemius, category: "polyalphabetic",
  notes: "Progressive shift: each letter shifts by key + position * step. Classic form is key 0, step 1.",
  knobs: {
    text: { type: "string",  required: true },
    key:  { type: "integer", default: 0, description: "Starting shift" },
    step: { type: "integer", default: 1, description: "Added to the shift for each letter" }
  }
