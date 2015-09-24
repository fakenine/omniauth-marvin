require "spec_helper"
require "omniauth-marvin"

describe OmniAuth::Strategies::Marvin do
  let(:request) { double('Request', :params => {}, :cookies => {}, :env => {}) }

  subject do
    OmniAuth::Strategies::Marvin.new('appid', 'secret', @options || {}).tap do |strategy|
      allow(strategy).to receive(:request) {
        request
      }
    end
  end

  describe "client options" do
    it 'has a the correct name' do
      expect(subject.options.name).to eq("marvin")
    end

    it 'has the correct site' do
      expect(subject.options.client_options.site).to eq("https://api.intrav2.42.fr")
    end

    it "has the correct auth url" do
      expect(subject.options.client_options.authorize_path).to eq("v2/oauth/authorize")
    end
  end

  describe 'callback path' do
    it 'has the correct callback path' do
      expect(subject.callback_path).to eq('/auth/marvin/callback')
    end
  end
end
