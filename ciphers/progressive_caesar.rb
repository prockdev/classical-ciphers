require_relative 'registry'
require_relative 'shared/shift'

module ProgressiveCaesar
  def self.encode(text, **opts) = run(text, 1, **opts)
  def self.decode(text, **opts) = run(text, -1, **opts)

  def self.run(text, direction, key: nil, step: nil, cycle: nil, block: nil,
               keys: nil, count_all: false, preserve_case: true)
    validate!(key, step, cycle, block, keys)

    base_key = key || 3
    # With cycle or block, a step of 0 would do nothing, so default it to 1 like the CLI does
    step_by = step || ((cycle || block) ? 1 : 0)

    pos = 0
    text.gsub(/./m) do |ch|
      if ch.match?(Ciphers::Shift::LETTER)
        shift =
          if keys
            keys[pos % keys.length]
          else
            index = if cycle then pos % cycle
                    elsif block then pos / block
                    else pos
                    end
            base_key + index * step_by
          end

        out = Ciphers::Shift.shift_char(ch, shift * direction)
        out = out.upcase unless preserve_case
        pos += 1
        out
      else
        pos += 1 if count_all
        ch
      end
    end
  end

  def self.validate!(key, step, cycle, block, keys)
    if keys && (key || step || cycle || block)
      raise ArgumentError, "keys cannot be combined with key, step, cycle or block"
    end
    raise ArgumentError, "use either cycle or block, not both" if cycle && block
    raise ArgumentError, "cycle must be 1 or greater" if cycle && cycle < 1
    raise ArgumentError, "block must be 1 or greater" if block && block < 1
  end

  private_class_method :run, :validate!
end

Ciphers.register "progressive_caesar", mod: ProgressiveCaesar, category: "polyalphabetic",
  notes: "Caesar with a changing shift. Use keys alone, or key/step with at most one of cycle or block. " \
         "Decode with the same settings used to encode.",
  knobs: {
    text:          { type: "string",        required: true },
    key:           { type: "integer",       description: "Starting shift (default 3)" },
    step:          { type: "integer",       description: "Added to the shift per letter (default 0, or 1 when cycle or block is used)" },
    cycle:         { type: "integer",       description: "Restart the shift sequence every N letters" },
    block:         { type: "integer",       description: "Keep the same shift for N letters before stepping" },
    keys:          { type: "integer_array", description: "Custom repeating sequence of shifts, e.g. [7, 3, 9]" },
    count_all:     { type: "boolean", default: false, description: "Count spaces and punctuation when positioning" },
    preserve_case: { type: "boolean", default: true, description: "Keep upper and lower case (false returns uppercase)" }
  }
