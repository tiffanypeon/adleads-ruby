require 'faraday'
require 'json'
module  AdLeads

  class Token
    attr_accessor *Configuration::VALID_CONFIG_KEYS

    def initialize(options={})
      merged_options = AdLeads.options.merge(options)
      Configuration::VALID_CONFIG_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end
    end

    def assertion
      claims = {
        iss: client_id,
        aud: endpoint,
        prn: principle,
        scope: 'campaign_read,campaign_write,reports',
        exp: Time.now.utc.to_i + (5*60),
      }
      JWT.encode(claims, private_key, 'RS256')
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new File.read('private_key.pem')
    end

    def token
      unless @token
        response = token_connection.post('/oauth/token') do |conn|
          conn.params = token_request_params
        end
        @token = JSON.parse(response.body)['access_token']
      end
      @token
    end

    def token_connection
      @token_connection ||= Faraday.new(url: token_endpoint) do |faraday|
        faraday.headers['Accept'] = 'application/json'
        faraday.adapter :httpclient  # make requests with Net::HTTP
        faraday.request :url_encoded
      end
    end

    def token_request_params
      {
        grant_type: 'jwt-bearer',
        assertion: assertion,
      }
    end
  end
end
