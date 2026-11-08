require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, ENV.fetch('PORT', 4567).to_i

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
end

get '/' do
  redirect '/capabilities'
end

get '/capabilities' do
  {
    name: "Classical Cipher API",
    version: "1.0.0",
    ciphers: ["base64"],
    endpoints: {
      base64_encode: "/encode/base64",
      base64_decode: "/decode/base64"
    }
  }.to_json
end

get '/health' do
  content_type :text
  "ok"
end

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
