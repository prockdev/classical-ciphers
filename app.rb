require 'sinatra'
require 'json'
require 'base64'

set :bind, '0.0.0.0'
set :port, ENV['PORT'] || 4567

# --- Discovery Endpoint ---
get '/capabilities' do
  content_type :json
  status 200
  
  {
    name: "Classical Cipher API",
    version: "1.0.0",
    ciphers: ["base64"], # We will add "caesar" and "vigenere" here later!
    endpoints: {
      base64_encode: "/encode/base64",
      base64_decode: "/decode/base64"
    }
  }.to_json
end

# --- Health Check ---
get '/health' do
  status 200
  "ok"
end

# --- Base64 Encode ---
post '/encode/base64' do
  content_type :json
  request.body.rewind
  body = request.body.read(65536) # 64KB limit
  
  begin
    data = JSON.parse(body)
    text = data['text']
    return [400, { error: "text is required" }.to_json] if text.nil?

    [200, { result: Base64.strict_encode64(text) }.to_json]
  rescue JSON::ParserError
    [400, { error: "Invalid JSON payload" }.to_json]
  end
end

# --- Base64 Decode ---
post '/decode/base64' do
  content_type :json
  request.body.rewind
  body = request.body.read(65536)

  begin
    data = JSON.parse(body)
    text = data['text']
    return [400, { error: "text is required" }.to_json] if text.nil?

    [200, { result: Base64.strict_decode64(text) }.to_json]
  rescue JSON::ParserError
    [400, { error: "Invalid JSON payload" }.to_json]
  rescue ArgumentError
    [400, { error: "Invalid base64 string" }.to_json]
  end
end
