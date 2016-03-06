ENV['RACK_ENV'] ||= 'test'
$no_log = true

require 'spec_helper'
require 'airborne'
require './environment'
require './app'
require './spec/data.rb'

RSpec.configure do |config|
   config.color = true
   config.formatter = :documentation
   config.mock_with :rspec
   config.raise_errors_for_deprecations!
end

Airborne.configure do |config|
   config.rack_app = Facility::API
   config.headers = {'X-Forwarded-For' => '127.0.0.1'}
end

def refresh token
   JSON.parse(RestClient.post(TestData::REFRESH_TOKEN_URL, {grant_type: 'refresh_token', refresh_token: token, client_id: TestData::CLIENT_ID, client_secret: TestData::CLIENT_SECRET}))['access_token']
end

describe Facility::API do

   base_url = '/facility/v1'

   let(:manage_token) {refresh TestData::REFRESH_TOKEN_MANAGE}

   context 'GET /namespace' do
      context 'with api token' do
         it 'returns all namespaces' do
            get base_url + '/namespace', {'X-NCU-API-TOKEN' => TestData::API_TOKEN}
            expect_status 200
            expect_json_types :array
            namespace = json_body.first
            expect(namespace).to eq({id: 1, name: '測試', description: '這是測試'})
         end
      end

      context 'with access token' do
         it 'returns all your namespaces' do
            get base_url + '/namespace', {'Authorization' => "Bearer #{manage_token}"}
            expect_status 200
            expect_json_types :array
            namespace = json_body.first
            expect(namespace).to eq({id: 1, name: '測試', description: '這是測試'})
         end
      end
   end

   context 'GET /namespace' do
      context 'with api token' do
         it 'returns a namespace' do
            get base_url + '/namespace/1', {'X-NCU-API-TOKEN' => TestData::API_TOKEN}
            expect_status 200
            expect_json({id: 1, name: '測試', description: '這是測試'})
         end
      end

      context 'with access token' do
         it 'returns a namespace of yours' do
            get base_url + '/namespace/1', {'Authorization' => "Bearer #{manage_token}"}
            expect_status 200
            expect_json({id: 1, name: '測試', description: '這是測試'})
         end
      end
   end

   context 'PUT /namespace' do
      it 'updates description of the namespace' do
         put base_url + '/namespace/1', {description: '餓死抬頭'}, {'Authorization' => "Bearer #{manage_token}"}
         expect_status 200
         expect_json({id: 1, name: '測試', description: '餓死抬頭'})
         put base_url + '/namespace/1', {description: '這是測試'}, {'Authorization' => "Bearer #{manage_token}"}
         expect_status 200
         expect_json({id: 1, name: '測試', description: '這是測試'})
      end
   end

   context 'GET /namespace/:id/facility' do
      context 'with api token' do
         it 'returns all facilities in the namespace' do
            get base_url + '/namespace/1/facility', {'X-NCU-API-TOKEN' => TestData::API_TOKEN}
            expect_status 200
            expect_json_types :array
            facility = json_body.first
            expect(facility).to eq({id: 1, name: 'test', description: 'testing', verify_calendar_id: nil, rent_calendar_id: nil})
         end
      end

      context 'with access token' do
         it 'returns all facilities in your namespace' do
            get base_url + '/namespace/1/facility', {'Authorization' => "Bearer #{manage_token}"}
            expect_status 200
            expect_json_types :array
            facility = json_body.first
            expect(facility).to eq({id: 1, name: 'test', description: 'testing', verify_calendar_id: nil, rent_calendar_id: nil})
         end
      end
   end
end
