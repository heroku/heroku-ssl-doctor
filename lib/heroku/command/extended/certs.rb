require "rest-client"
require "json"
require "heroku/command/certs" unless defined? Heroku::Command::Certs

SSL_DOCTOR_URL = ENV["SSL_DOCTOR_URL"] || "https://ssl-doctor.herokuapp.com/"
SSL_DOCTOR     = RestClient::Resource.new SSL_DOCTOR_URL

class Heroku::Command::Certs
  class UsageError < StandardError; end

  # certs:chain PEM [PEM ...]
  #
  # Print the ordered and complete chain for the given certificate.
  #
  # Optional intermediates certificates may be given too, and will
  # be used during chain resolution.
  #
  def chain
    puts read_crt_through_ssl_doctor
  rescue UsageError
    fail("Usage: heroku certs:chain PEM [PEM ...]\nMust specify at least one certificate file.")
  end

  # certs:key PEM KEY [KEY ...]
  #
  # Print the correct key for the given certificate.
  #
  # You must pass one single certificate, and one or more keys.
  # The first key that signs the certificate will be printed back.
  #
  def key
    crt, key = read_crt_and_key_through_ssl_doctor("Testing for signing key")
    puts key
  rescue UsageError
    fail("Usage: heroku certs:key PEM KEY [KEY ...]\nMust specify one certificate file and at least one key file.")
  end

  # certs:add PEM KEY
  #
  # Add an ssl endpoint to an app.
  #
  #   --bypass  # bypass the trust chain completion step
  #
  def add
    crt, key = read_crt_and_key
    endpoint = action("Adding SSL Endpoint to #{app}") { heroku.ssl_endpoint_add(app, crt, key) }
    display_warnings(endpoint)
    display "#{app} now served by #{endpoint['cname']}"
    display "Certificate details:"
    display_certificate_info(endpoint)
  rescue UsageError
    fail("Usage: heroku certs:add PEM KEY\nMust specify PEM and KEY to add cert.")
  end

  # certs:update PEM KEY
  #
  # Update an SSL Endpoint on an app.
  #
  #   --bypass  # bypass the trust chain completion step
  #
  def update
    crt, key = read_crt_and_key
    cname    = options[:endpoint] || current_endpoint
    endpoint = action("Updating SSL Endpoint #{cname} for #{app}") { heroku.ssl_endpoint_update(app, cname, crt, key) }
    display_warnings(endpoint)
    display "Updated certificate details:"
    display_certificate_info(endpoint)
  rescue UsageError
    fail("Usage: heroku certs:update PEM KEY\nMust specify PEM and KEY to update cert.")
  end


  private

  def post_to_ssl_doctor(path, action_text = nil)
    raise UsageError if args.size < 1
    action_text ||= "Resolving trust chain"
    action(action_text) do
      input = args.map { |arg| File.read(arg) rescue error("Unable to read #{args[0]} file") }.join("\n")
      SSL_DOCTOR[path].post(input)
    end
  rescue RestClient::BadRequest, RestClient::UnprocessableEntity => e
    error(e.response.body)
  end

  def read_crt_and_key_through_ssl_doctor(action_text = nil)
    crt_and_key = post_to_ssl_doctor("resolve-chain-and-key", action_text)
    JSON.parse(crt_and_key).values_at("crt", "key")
  end

  def read_crt_through_ssl_doctor(action_text = nil)
    post_to_ssl_doctor("resolve-chain", action_text).body
  end

  def read_crt_and_key_bypassing_ssl_doctor
    raise UsageError if args.size != 2
    crt = File.read(args[0]) rescue error("Unable to read #{args[0]} PEM")
    key = File.read(args[1]) rescue error("Unable to read #{args[1]} KEY")
    [crt, key]
  end

  def read_crt_and_key
    options[:bypass] ? read_crt_and_key_bypassing_ssl_doctor : read_crt_and_key_through_ssl_doctor
  end

end
