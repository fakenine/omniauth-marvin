require "omniauth/strategies/oauth2"

module OmniAuth
  module Strategies
    class Marvin < OmniAuth::Strategies::OAuth2
      option :name, :marvin

      option :client_options, {
        site: "https://api.intrav2.42.fr",
        authorize_path: "v2/oauth/authorize"
      }

      uid { raw_info['id'] }

      info do
        {
          email: raw_info["email"],
          login: raw_info["login"],
          url: raw_info["url"],
          name: raw_info["displayname"],
          image: raw_info["image_url"],
          staff?: raw_info["staff?"],
          correction_point: raw_info["correction_point"],
          wallet: raw_info["wallet"],
          level: raw_info["cursus"]["level"],
          grade: raw_info["cursus"]["grade"]
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('v2/me').parsed
      end
    end
  end
end
