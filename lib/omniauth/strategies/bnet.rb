require 'omniauth-oauth2'
require 'base64'

module OmniAuth
  module Strategies
    class Bnet < OmniAuth::Strategies::OAuth2
      option :region, 'us'
      option :client_options, {
        :scope => 'wow.profile sc2.profile'
      }

      def client
        # Setup urls based on region option
        if !options.client_options.has_key(:authorize_url)
          options.client_options[:authorize_url] = "https://#{getHost(options.region)}/oauth/authorize"
        end
        if !options.client_options.has_key(:token_url)
          options.client_options[:token_url] = "https://#{getHost(options.region)}/oauth/token"
        end
        if !options.client_options.has_key(:site)
          options.client_options[:site] = "https://#{getHost(options.region)}/"
        end

        super
      end

      def request_phase
        super
      end

      def authorize_params
        super.tap do |params|
          %w[scope client_options].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

      uid { raw_info['id'].to_s }

      info do
        raw_info
      end

      def raw_info(tries = 3)
        return @raw_info if @raw_info

        access_token.options[:mode] = :query

        @raw_info = access_token.get('oauth/userinfo').parsed
      rescue Faraday::ConnectionFailed => e
        tries -= 1

        if tries <= 0
          raise
        else
          sleep(1)
          raw_info(tries)
        end
      end

      private

      def build_access_token
        @access_token_tries ||= 3
        super
      rescue Faraday::ConnectionFailed => e
        @access_token_tries -= 1

        if @access_token_tries <= 0
          @access_token_tries = nil
          raise
        else
          sleep(1)
          retry
        end
      end

      def callback_url
        full_host + script_name + callback_path
      end

      def getHost(region)
        case region
        when "cn"
          "www.battlenet.com.cn"
        else
          "#{region}.battle.net"
        end
      end
    end
  end
end
