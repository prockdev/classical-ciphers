require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, ENV.fetch('PORT', 4567).to_i

require_relative 'ciphers/registry'
Dir[File.join(__dir__, 'ciphers', '*.rb')].sort.each { |f| require f }

before { content_type :json }

helpers do
  def json_body
    data = JSON.parse(request.body.read(65536).to_s)
    halt 400, { error: "JSON object required" }.to_json unless data.is_a?(Hash)
    data
  rescue JSON::ParserError
    halt 400, { error: "Invalid JSON payload" }.to_json
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
    ciphers: Ciphers.describe
  }.to_json
end

get '/health' do
  content_type :text
  "ok"
end

post '/:action/:cipher' do
  halt 404, { error: "unknown action" }.to_json unless %w[encode decode].include?(params[:action])
  cipher = Ciphers::REGISTRY[params[:cipher]] or halt 404, { error: "unknown cipher" }.to_json

  data = json_body
  text = data['text']
  halt 400, { error: "text (string) is required" }.to_json unless text.is_a?(String)

  begin
    opts = Ciphers.options(cipher, data)
    result = cipher[:mod].public_send(params[:action], text, **opts)
  rescue ArgumentError => e
    halt 400, { error: e.message }.to_json
  end

  halt 422, { error: "Result is not valid UTF-8 text" }.to_json unless result.valid_encoding?
  { result: result, cipher: params[:cipher], action: params[:action], used: opts }.to_json
end
