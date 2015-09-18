require "omniauth/strategies/oauth2"

module OmniAuth
  module Strategies
    class Marvin < OmniAuth::Strategies::OAuth2
      option :name, :marvin

      option :client_options, {
        site: "https://api.intrav2.42.fr",
        authorize_path: "v2/oauth/authorize"
      }

      uid do
        raw_info['id']
      end

      info do
        {
          email: raw_info["email"],
          login: raw_info["login"],
          name: raw_info["displayname"]
        }
      end

      def raw_info
        @raw_info ||= access_token.get('v2/me').parsed
      end
    end
  end
end
