require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, ENV.fetch('PORT', 4567).to_i

# Each cipher lives in ciphers/<name>.rb as a module with the same name
Dir[File.join(__dir__, 'ciphers', '*.rb')].sort.each { |f| require f }

CIPHERS = {
  "base64" => {
    category: "encoding",
    knobs: {
      text: { type: "string", required: true }
    }
  },
  "caesar" => {
    category: "substitution",
    notes: "ASCII letters only. Shifts wrap modulo 26.",
    knobs: {
      text:          { type: "string",  required: true },
      key:           { type: "integer", default: 3, description: "Starting shift" },
      step:          { type: "integer", default: 0, description: "Added to the shift for each letter" },
      count_all:     { type: "boolean", default: false, description: "Count spaces and punctuation when positioning" },
      preserve_case: { type: "boolean", default: true, description: "Keep upper and lower case" }
    }
  }
}.freeze

TYPE_CHECKS = {
  "string"  => ->(v) { v.is_a?(String) },
  "integer" => ->(v) { v.is_a?(Integer) },
  "boolean" => ->(v) { v == true || v == false }
}.freeze

before { content_type :json }

helpers do
  def json_body
    data = JSON.parse(request.body.read(65536).to_s)
    halt 400, { error: "JSON object required" }.to_json unless data.is_a?(Hash)
    data
  rescue JSON::ParserError
    halt 400, { error: "Invalid JSON payload" }.to_json
  end

  def text_param
    text = json_body['text']
    halt 400, { error: "text (string) is required" }.to_json unless text.is_a?(String)
    text
  end

  # Checks the optional fields against the cipher's knobs; returns keyword options
  def knob_options(knobs, data)
    unknown = data.keys - knobs.keys.map(&:to_s)
    halt 400, { error: "unknown field(s): #{unknown.join(', ')}" }.to_json unless unknown.empty?

    knobs.each_with_object({}) do |(name, spec), opts|
      next if name == :text
      value = data.fetch(name.to_s, spec[:default])
      next if value.nil?
      unless TYPE_CHECKS[spec[:type]].call(value)
        halt 400, { error: "#{name} must be of type #{spec[:type]}" }.to_json
      end
      opts[name] = value
    end
  end
end

get '/' do
  redirect '/capabilities'
end

get '/capabilities' do
  {
    name: "Classic Ciphers API",
    version: "1.0.0",
    path_template: "/{action}/{cipher}",
    method: "POST",
    actions: %w[encode decode],
    ciphers: CIPHERS.map { |id, c| { id: id }.merge(c) }
  }.to_json
end

get '/health' do
  content_type :text
  "ok"
end

# --- Base64 (kept as is) ---
post '/encode/base64' do
  { result: [text_param].pack('m0') }.to_json
end

post '/decode/base64' do
  decoded =
    begin
      text_param.unpack1('m0')
    rescue ArgumentError
      halt 400, { error: "Invalid base64 string" }.to_json
    end

  decoded.force_encoding('UTF-8')
  halt 422, { error: "Decoded data is not valid UTF-8 text" }.to_json unless decoded.valid_encoding?
  { result: decoded }.to_json
end

# --- Every other cipher in CIPHERS (Caesar and later ones) ---
post '/:action/:cipher' do
  halt 404, { error: "unknown action" }.to_json unless %w[encode decode].include?(params[:action])
  meta = CIPHERS[params[:cipher]] or halt 404, { error: "unknown cipher" }.to_json

  mod_name = params[:cipher].capitalize
  unless Object.const_defined?(mod_name)
    halt 501, { error: "#{params[:cipher]} is listed but not implemented yet" }.to_json
  end

  data = json_body
  text = data['text']
  halt 400, { error: "text (string) is required" }.to_json unless text.is_a?(String)
  opts = knob_options(meta[:knobs], data)

  result =
    begin
      Object.const_get(mod_name).public_send(params[:action], text, **opts)
    rescue ArgumentError => e
      halt 400, { error: e.message }.to_json
    end

  halt 422, { error: "Result is not valid UTF-8 text" }.to_json unless result.valid_encoding?
  { result: result, cipher: params[:cipher], action: params[:action], used: opts }.to_json
end
