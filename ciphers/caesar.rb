require_relative 'registry'
require_relative 'shared/shift'

module Caesar
  def self.encode(text, key: 3, preserve_case: true) = run(text, key, preserve_case)
  def self.decode(text, key: 3, preserve_case: true) = run(text, -key, preserve_case)

  def self.run(text, shift, preserve_case)
    text.gsub(Ciphers::Shift::LETTER) do |ch|
      out = Ciphers::Shift.shift_char(ch, shift)
      preserve_case ? out : out.upcase
    end
  end
  private_class_method :run
end

Ciphers.register "caesar", mod: Caesar, category: "substitution",
  notes: "ASCII letters only. Shifts wrap modulo 26.",
  knobs: {
    text:          { type: "string",  required: true },
    key:           { type: "integer", default: 3, description: "Shift amount" },
    preserve_case: { type: "boolean", default: true, description: "Keep upper and lower case (false returns uppercase)" }
  }
