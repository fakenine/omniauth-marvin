require "spec_helper"
require "omniauth-marvin"

describe OmniAuth::Strategies::Marvin do
  let(:request) { double('Request', params: {}, cookies: {}, env: {}) }

  subject do
    OmniAuth::Strategies::Marvin.new('appid', 'secret', @options || {}).tap do |strategy|
      allow(strategy).to receive(:request) {
        request
      }
    end
  end

  describe 'client options' do
    it 'has the correct name' do
      expect(subject.options.name).to eq("marvin")
    end

    it 'has the correct site' do
      expect(subject.options.client_options.site).to eq("https://api.intrav2.42.fr")
    end

    it 'has the correct auth url' do
      expect(subject.options.client_options.authorize_path).to eq("v2/oauth/authorize")
    end
  end

  describe 'callback path' do
    it 'has the correct callback path' do
      expect(subject.callback_path).to eq('/auth/marvin/callback')
    end
  end

  describe 'uid' do
    before :each do
      allow(subject).to receive(:raw_info) { {} }
    end

    it 'returns the uid' do
      expect(subject.uid).to eq(:raw_info['id'])
    end
  end

  describe 'info' do
    before :each do
      allow(subject).to receive(:raw_info) { {} }
    end

    it 'has the name key' do
      expect(subject.info).to have_key :name
    end

    it 'has the email key' do
      expect(subject.info).to have_key :email
    end

    it 'has the nickname key' do
      expect(subject.info).to have_key :nickname
    end

    it 'has the location key' do
      expect(subject.info).to have_key :location
    end

    it 'has the phone key' do
      expect(subject.info).to have_key :phone
    end

    it 'has the image key' do
      expect(subject.info).to have_key :image
    end

    it 'has the urls key' do
      expect(subject.info).to have_key :urls
    end

    it 'returns the name' do
      expect(subject.info[:name]).to eq(:raw_info['displayname'])
    end

    it 'returns the email' do
      expect(subject.info[:email]).to eq(:raw_info['email'])
    end

    it 'returns the nickname' do
      expect(subject.info[:nickname]).to eq(:raw_info['login'])
    end

    it 'returns the location' do
      expect(subject.info[:location]).to eq(:raw_info['location'])
    end

    it 'returns the phone' do
      expect(subject.info[:phone]).to eq(:raw_info['mobile'])
    end

    it 'returns the image' do
      expect(subject.info[:image]).to eq(:raw_info['image'])
    end

    it 'returns the profile' do
      expect(subject.info[:urls]["Profile"]).to eq(:raw_info['url'])
    end
  end
end
