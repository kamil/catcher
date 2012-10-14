require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'json/pure'

Mongoid.load!("config/mongoid.yml")

disable :protection
set :show_exceptions, true

configure :production do
end

class Request
  include Mongoid::Document
  field :m, type: String # REQUEST_METHOD
  field :a, type: String # HTTP_USER_AGENT,
  field :r, type: String # REMOTE_ADDR
  field :t, type: DateTime # Time.now
  field :q, type: Hash # rack.request.query_hash
  field :c, type: Hash # rack.request.cookie_hash"
  field :p, type: String # REQUEST_PATH
  field :h, type: String # HTTP_HOST
  field :e, type: Hash
  field :x, type: Hash # Http Headers
end

def catcher(path, opts={}, &block)
  post(path, opts, &block)
  put(path, opts, &block)
  get(path, opts, &block)
  delete(path, opts, &block)
  head(path, opts, &block)
end

catcher '*' do

  attrib = {
    t: Time.now,
    m: request.env["REQUEST_METHOD"],
    a: request.env["HTTP_USER_AGENT"],
    r: request.env["REMOTE_ADDR"],
    q: request.env["rack.request.query_hash"],
    c: request.env["rack.request.cookie_hash"],
    p: request.env["REQUEST_PATH"],
    h: request.env["HTTP_HOST"],
    b: request.env["rack.request.form_vars"],
    x: {}
  }

  begin
    attrib[:j] = JSON.parse(request.env["rack.request.form_vars"])
  rescue
  end

  request.env.select do |k,v|
    attrib[:x][k[5..-1]] = v if k.start_with?("HTTP_") and not ["COOKIE","HTTP_ACCEPT","HTTP_HOST","HTTP_USER_AGENT","HTTP_VERSION"].include?(k)
  end

  Request.create(attrib)

  {
    "text/xml" => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<request>saved</request>\n",
    "application/javascript" => "{\"request\":\"saved\"}"
  }.each do |content,resp|
    if request.accept? content
      content_type content
      return resp
    end
  end

  return "saved"

end
