module Ciphers
  REGISTRY = {}

  TYPE_CHECKS = {
    "string"  => ->(v) { v.is_a?(String) },
    "integer" => ->(v) { v.is_a?(Integer) },
    "boolean" => ->(v) { v == true || v == false }
  }.freeze

  def self.register(id, mod:, category:, knobs:, notes: nil)
    REGISTRY[id] = { mod: mod, category: category, knobs: knobs, notes: notes }
  end

  def self.describe
    REGISTRY.map do |id, c|
      { id: id, category: c[:category], notes: c[:notes], knobs: c[:knobs] }.compact
    end
  end

  # Returns the keyword options for a cipher, applying defaults.
  # Raises ArgumentError with a clear message on bad input.
  def self.options(cipher, data)
    knobs = cipher[:knobs]
    unknown = data.keys - knobs.keys.map(&:to_s)
    raise ArgumentError, "unknown field(s): #{unknown.join(', ')}" unless unknown.empty?

    knobs.each_with_object({}) do |(name, spec), opts|
      next if name == :text
      value = data.fetch(name.to_s, spec[:default])
      next if value.nil?
      raise ArgumentError, "#{name} must be of type #{spec[:type]}" unless TYPE_CHECKS[spec[:type]].call(value)
      opts[name] = value
    end
  end
end
