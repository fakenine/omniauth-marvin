require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Marvin < OmniAuth::Strategies::OAuth2
      option :name, 'marvin'

      option :client_options, {
        site: 'https://api.intra.42.fr',
        authorize_url: 'v2/oauth/authorize'
      }

      option :pkce, true

      uid { raw_info['id'] }


      # set name with usual_full_name.
      # usual_full_name is the name student wants to be called/named/displayed.
      info do
        {
          first_name: raw_info['first_name'],
          last_name: raw_info['last_name'],
          name: raw_info['usual_full_name'],
          email: raw_info['email'],
          login: raw_info['login'],
          image: raw_info['image_url'],
          urls: {
            profile: raw_info['url']
          }
        }
      end

      extra do
        {
          'raw_info': raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('v2/me').parsed
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
