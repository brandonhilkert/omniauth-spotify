require 'omniauth/strategies/oauth2'
require 'date'

module OmniAuth
  module Strategies
    class Spotify < OmniAuth::Strategies::OAuth2
      option :name, 'spotify'

      option :authorize_options, %w[show_dialog]
      option :client_options, {
        :site          => 'https://api.spotify.com/v1',
        :authorize_url => 'https://accounts.spotify.com/authorize',
        :token_url     => 'https://accounts.spotify.com/api/token',
      }

      uid { raw_info['id'] }

      info do
        {
          # Unless the 'user-read-private' scope is included, the birthdate, country, image, and product fields may be nil,
          # and the name field will be set to the username/nickname instead of the display name.
          # The email field will be nil if the 'user-read-email' scope isn't included.
          #
          :name => raw_info['display_name'] || raw_info['id'],
          :nickname => raw_info['id'],
          :email => raw_info['email'],
          :urls => raw_info['external_urls'],
          :image => image_url,
          :birthdate => raw_info['birthdate'] && Date.parse(raw_info['birthdate']),
          :country_code => raw_info['country'],
          :product => raw_info['product'],
          :follower_count => raw_info['followers']['total']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def image_url
        if images = raw_info['images']
          if first = images.first
            first['url']
          end
        end
      end

      def raw_info
        @raw_info ||= access_token.get('me').parsed
      end

      def authorize_params
        super.tap do |params|
          options[:authorize_options].each do |k|
            params[k] = request.params[k.to_s] unless [nil, ''].include?(request.params[k.to_s])
          end
        end
      end

      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end
    end
  end
end
