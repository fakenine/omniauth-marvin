require 'spec_helper'
require 'omniauth-marvin'

describe OmniAuth::Strategies::Marvin do
  let(:request) { double('Request', params: {}, cookies: {}, env: {}) }

  subject do
    OmniAuth::Strategies::Marvin.new('FT_ID', 'FT_SECRET', @options || {}).tap do |strategy|
      allow(strategy).to receive(:request) {
        request
      }
    end
  end

  describe 'client options' do
    it 'has the correct name' do
      expect(subject.options.name).to eq('marvin')
    end

    it 'has the correct site' do
      expect(subject.options.client_options.site).to eq('https://api.intra.42.fr')
    end

    it 'has the correct auth url' do
      expect(subject.options.client_options.authorize_url).to eq('v2/oauth/authorize')
    end

    it 'has the pkce to true' do
      expect(subject.options.pkce).to eq(true)
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

    it 'has the login key' do
      expect(subject.info).to have_key :login
    end

    it 'has the first_name key' do
      expect(subject.info).to have_key :first_name
    end

    it 'has the last_name key' do
      expect(subject.info).to have_key :last_name
    end

    it 'has the image key' do
      expect(subject.info).to have_key :image
    end

    it 'has the urls key' do
      expect(subject.info).to have_key :urls
    end

    it 'has the profile key in urls' do
      expect(subject.info[:urls]).to have_key :profile
    end

    it 'returns the email' do
      expect(subject.info[:email]).to eq(:raw_info['email'])
    end

    it 'returns the login' do
      expect(subject.info[:login]).to eq(:raw_info['login'])
    end

    it 'returns the first_name' do
      expect(subject.info[:first_name]).to eq(:raw_info['first_name'])
    end

    it 'returns the last_name' do
      expect(subject.info[:last_name]).to eq(:raw_info['last_name'])
    end

    it 'returns the name with usual_full_name' do
      expect(subject.info[:name]).to eq(:raw_info['usual_full_name'])
    end

    it 'returns the image' do
      expect(subject.info[:image]).to eq(:raw_info['image'])
    end

    it 'returns the profile' do
      expect(subject.info[:urls][:profile]).to eq(:raw_info['url'])
    end
  end
end
