require 'faraday'
require 'json'

module  AdLeads
  class Client
    PROMOTABLE_TYPES = [:promotion]

    attr_accessor *Configuration::VALID_CONFIG_KEYS

    def initialize(options={})
      merged_options = AdLeads.options.merge(options)
      Configuration::VALID_CONFIG_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end
    end

    def configure_campaign_signups(ad_campaign_id, etag, params)
      path = "/campaigns/#{ad_campaign_id}/signupdelivery"
      connection_with_etag_match(etag).send(:post, path) do |request|
        request.body = params if params
      end
    end

    def create_ad(creative_group_id, type)
      post("/creativegroups/#{creative_group_id}/creatives", type)
    end

    def create_campaign(params)
      post('/campaigns', params)
    end

    def create_content_holder(ids, type)
      path = "/creativegroups/#{ids[:group]}/creatives/#{ids[:creative]}/images"
      post(path, type)
    end

    def create_creative_group(params)
      post('/creativegroups', params)
    end

    def get_campaign_etag(ad_campaign_id)
      response = get("/campaigns/#{ad_campaign_id}")
      response.headers['ETag']
    end

    def get_campaign_status(ad_campaign_id)
      response = get("/campaigns/#{ad_campaign_id}")
      JSON.parse(response.body)['status']
    end

    def get_content_etag(ids)
      get("/creativegroups/#{ids[:group]}/creatives/#{ids[:creative]}/images/#{ids[:image]}")
    end

    def get_reports(params)
      get("/reports/campaign/report", params)
    end

    def launch_campaign(ad_campaign_id, etag, params = nil)
      path = "/campaigns/#{ad_campaign_id}/launch"
      connection_with_etag_match(etag).send(:post, path) do |request|
        request.body = params if params
      end
    end

    # def pause_campaign(ad_campaign_id, etag)
    #   path = "/campaigns/#{ad_campaign_id}/pause"
    #   connection_with_etag_match(etag).send(:post, path)
    # end

    def update_campaign(ad_campaign_id, params = {})
      post("/campaigns/#{ad_campaign_id}", params)
    end

    def upload_image(ids, etag, file)
      path = "/creativegroups/#{ids[:group]}/creatives/#{ids[:creative]}/images/#{ids[:image]}/file"
      image_payload = {
        file: Faraday::UploadIO.new(file, 'image/jpeg')
      }
      connection_with_etag_match(etag).post(path, image_payload)
    end

    def verify_campaign(ad_campaign_id)
      get("/campaigns/#{ad_campaign_id}/plan")
    end

    def get(path, params = {})
      request(:get, path, params)
    end

    def post(path, params = {})
      request(:post, path, params)
    end

    private

    def connection
      @connection ||= Faraday.new(url: endpoint) do |faraday|
        faraday.headers['Accept'] = 'application/json'
        faraday.request  :url_encoded
        faraday.authorization :Bearer, token
        faraday.adapter  :httpclient  # make requests with Net::HTTP
        faraday.request :url_encoded
      end
    end

    def token
      @token ||= AdLeads::Token.new(client_id: client_id, principle: principle).token
    end

    def connection_with_etag_match(etag)
      Faraday.new(:url => endpoint) do |faraday|
        faraday.headers['If-Match'] = etag
        faraday.request  :multipart
        faraday.request  :url_encoded
        faraday.authorization :Bearer, token
        faraday.adapter  :net_http
      end
    end

    def request(method, path, params = {})
      connection.send(method, path) do |request|
        request.params = params if method == :get
        request.body = params if method == :post
      end
      # rescue Faraday::Error::TimeoutError, Timeout::Error => error
      # rescue Faraday::Error::ClientError, JSON::ParserError => error
    end

  end
end
