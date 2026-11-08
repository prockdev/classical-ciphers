require_relative 'registry'

# ... your Caesar module ...

Ciphers.register "caesar", mod: Caesar, category: "substitution",
  notes: "ASCII letters only. Shifts wrap modulo 26.",
  knobs: {
    text:          { type: "string",  required: true },
    key:           { type: "integer", default: 3, description: "Starting shift" },
    step:          { type: "integer", default: 0, description: "Added to the shift for each letter" },
    count_all:     { type: "boolean", default: false, description: "Count spaces and punctuation when positioning" },
    preserve_case: { type: "boolean", default: true, description: "Keep upper and lower case" }
  }
