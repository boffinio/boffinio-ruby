require 'cgi'
require 'set'
require 'json'
#Version
require_relative "boffinio/version"

#API Operations
require_relative 'boffinio/api_operations/list'
require_relative 'boffinio/api_operations/create'
require_relative 'boffinio/api_operations/delete'
require_relative 'boffinio/api_operations/update'

#Resources
require_relative 'boffinio/util'
require_relative 'boffinio/boffinio_object'
require_relative 'boffinio/api_resource'
require_relative "boffinio/list_object"
require_relative "boffinio/customer"
require_relative "boffinio/subscription"
require_relative "boffinio/plan"

#Errors
require_relative 'boffinio/errors/boffinio_error'
require_relative 'boffinio/errors/api_error'
require_relative 'boffinio/errors/authentication_error'
require_relative 'boffinio/errors/invalid_request_error'

require 'rest-client'

module BoffinIO

 @api_base = 'https://api.boffin.io'
 @api_version = "v1"

 class << self
    attr_accessor :api_key, :api_base, :verify_ssl_certs, :api_version
  end

  def self.api_url(url='')
    @api_base+url
  end

  def self.request(method, url, api_key, params={}, headers={})
    unless api_key ||= @api_key
      raise AuthenticationError.new('No API key provided. ' +
        'Set your API key using "BoffinIO.api_key = <API-KEY>". ' +
        'You can generate API keys from the Boffin web interface. ')
    end

    if api_key =~ /\s/
      raise AuthenticationError.new('Your API key is invalid, as it contains ' +
        'whitespace. (HINT: You can double-check your API key from the ' +
        'Boffin web interface. See https://boffion.io/api for details, or ' +
        'email support@boffin.io if you have any questions.)')
    end

    request_opts = { :verify_ssl => false }

    params = Util.objects_to_ids(params)
    url = api_url(url)

    case method.to_s.downcase.to_sym
    when :get, :head, :delete
      # Make params into GET parameters
      url += "#{URI.parse(url).query ? '&' : '?'}#{uri_encode(params)}" if params && params.any?
      payload = nil
    else
      payload = uri_encode(params)
    end
    request_opts.update(:headers => request_headers(api_key).update(headers),
                        :method => method, :open_timeout => 30,
                        :payload => payload, :url => url, :timeout => 80)

    begin
      response = execute_request(request_opts)
    rescue SocketError => e
      handle_restclient_error(e)
    rescue NoMethodError => e
      # Work around RestClient bug
      if e.message =~ /\WRequestFailed\W/
        e = APIConnectionError.new('Unexpected HTTP response code')
        handle_restclient_error(e)
      else
        raise
      end
    rescue RestClient::ExceptionWithResponse => e
      if rcode = e.http_code and rbody = e.http_body
        handle_api_error(rcode, rbody)
      else
        handle_restclient_error(e)
      end
    rescue RestClient::Exception, Errno::ECONNREFUSED => e
      handle_restclient_error(e)
    end

    [parse(response), api_key]
  end

    def self.user_agent
    @uname ||= get_uname
    lang_version = "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})"

    {
      :bindings_version => BoffinIO::VERSION,
      :lang => 'ruby',
      :lang_version => lang_version,
      :platform => RUBY_PLATFORM,
      :publisher => 'boffinio',
      :uname => @uname
    }

  end

  def self.get_uname
    `uname -a 2>/dev/null`.strip if RUBY_PLATFORM =~ /linux|darwin/i
  rescue Errno::ENOMEM => ex # couldn't create subprocess
    "uname lookup failed"
  end

  def self.request_headers(api_key)
    headers = {
      :user_agent => "Boffin/v1 RubyBindings/#{BoffinIO::VERSION}",
      :authorization => "Token token=#{api_key}",
      :content_type => 'application/x-www-form-urlencoded'
    }

    headers[:boffinio_version] = api_version if api_version

    begin
      headers.update(:x_boffinio_client_user_agent => JSON.generate(user_agent))
    rescue => e
      headers.update(:x_boffinio_client_raw_user_agent => user_agent.inspect,
                     :error => "#{e} (#{e.class})")
    end
  end

 def self.uri_encode(params)
    Util.flatten_params(params).
      map { |k,v| "#{k}=#{Util.url_encode(v)}" }.join('&')
  end

  def self.execute_request(opts)
    RestClient::Request.execute(opts)
  end

  def self.parse(response)
    begin
      # Would use :symbolize_names => true, but apparently there is
      # some library out there that makes symbolize_names not work.
      response = JSON.parse(response.body)
    rescue JSON::ParserError
      raise general_api_error(response.code, response.body)
    end

    Util.symbolize_names(response)
  end

  def self.handle_api_error(rcode, rbody)
    begin
      error_obj = JSON.parse(rbody)
      error_obj = Util.symbolize_names(error_obj)
      error = error_obj[:error] or raise BoffinIOError.new # escape from parsing

    rescue JSON::ParserError, BoffinIOError
      raise general_api_error(rcode, rbody)
    end

    case rcode
    when 400, 404
      raise invalid_request_error error, rcode, rbody, error_obj
    when 401
      raise authentication_error error, rcode, rbody, error_obj
    else
      raise api_error error, rcode, rbody, error_obj
    end

  end

  def self.invalid_request_error(error, rcode, rbody, error_obj)
    InvalidRequestError.new(error[:message], error[:param], rcode,
                            rbody, error_obj)
  end

  def self.authentication_error(error, rcode, rbody, error_obj)
    AuthenticationError.new(error[:message], rcode, rbody, error_obj)
  end

  def self.api_error(error, rcode, rbody, error_obj)
    APIError.new(error[:message], rcode, rbody, error_obj)
  end

  def self.general_api_error(rcode, rbody)
    BoffinIOError.new("Invalid response object from API: #{rbody.inspect} " +
                 "(HTTP response code was #{rcode})", rcode, rbody)
  end

  def self.handle_restclient_error(e)
    connection_message = "Please check your internet connection and try again. " \
        "If this problem persists, you should check Boffin's service status at " \
        "https://twitter.com/boffinio, or let us know at support@boffin.io."

    case e
    when RestClient::RequestTimeout
      message = "Could not connect to Boffin (#{@api_base}). #{connection_message}"

    when RestClient::ServerBrokeConnection
      message = "The connection to the server (#{@api_base}) broke before the " \
        "request completed. #{connection_message}"

    when RestClient::SSLCertificateNotVerified
      message = "Could not verify Boffin's SSL certificate. " \
        "Please make sure that your network is not intercepting certificates. " \
        "(Try going to https://api.boffin.com/v1 in your browser.) " \
        "If this problem persists, let us know at support@boffin.io."

    when SocketError
      message = "Unexpected error communicating when trying to connect to Boffin. " \
        "You may be seeing this message because your DNS is not working. " \
        "To check, try running 'host boffin.io' from the command line."

    else
      message = "Unexpected error communicating with Boffin. " \
        "If this problem persists, let us know at support@boffin.io."

    end

    raise BoffinIOError.new(message + "\n\n(Network error: #{e.message})")
  end
end
