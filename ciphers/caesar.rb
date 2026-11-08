require_relative 'registry'

module Caesar
  LETTER = /[A-Za-z]/

  def self.encode(text, **opts) = transform(text, 1, **opts)
  def self.decode(text, **opts) = transform(text, -1, **opts)

  def self.transform(text, direction, key: nil, step: nil, cycle: nil, block: nil,
                     keys: nil, count_all: false, preserve_case: true)
    validate!(key, step, cycle, block, keys)

    base_key = key || 3
    # With cycle or block, a step of 0 would do nothing, so default it to 1 like the CLI does
    step_by = step || ((cycle || block) ? 1 : 0)

    pos = 0
    out = text.each_char.map do |ch|
      is_letter = ch.match?(LETTER)
      shifted = ch

      if is_letter
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

        base = ch.ord < 97 ? 65 : 97
        shifted = ((ch.ord - base + shift * direction) % 26 + base).chr
        shifted = shifted.upcase unless preserve_case
      end

      pos += 1 if is_letter || count_all
      shifted
    end
    out.join
  end

  def self.validate!(key, step, cycle, block, keys)
    if keys && (key || step || cycle || block)
      raise ArgumentError, "keys cannot be combined with key, step, cycle or block"
    end
    raise ArgumentError, "use either cycle or block, not both" if cycle && block
    raise ArgumentError, "cycle must be 1 or greater" if cycle && cycle < 1
    raise ArgumentError, "block must be 1 or greater" if block && block < 1
  end

  private_class_method :transform, :validate!
end

Ciphers.register "caesar", mod: Caesar, category: "substitution",
  notes: "ASCII letters only. Shifts wrap modulo 26. Decode with the same settings used to encode. " \
         "Use keys alone, or key/step with at most one of cycle or block.",
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
