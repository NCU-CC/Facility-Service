module Facility
   class V1 < Grape::API

      class << self
         include Namespace::V1
         include Facility::V1
         include Rent::V1
      end

      format :json
      content_type :json, 'application/json;charset=UTF-8'

      helpers HTTP::Error::Helpers
      helpers NCU::OAuth::Helpers
      helpers do
         def request
            @request ||= ::Rack::Request.new(env)
         end

         def error! message, error_code, headers = nil
            V1.logger.error "{:path=>#{request.path}, :params=>#{request.params.to_hash}, :method=>#{request.request_method}, :message=>#{message}, :status=>#{error_code}}"
            super message, error_code, headers
         end

         def find_token type = :both
            token, type = api_or_access_token type
            tokens_missing! if type == :both && token == 400
            token_missing! type if token == 400
            token_error! token if token.kind_of? Fixnum
            DB::User.create!(uid: token['user'], name: token['name'], unit: token['unit']) unless type == :api || DB::User.exists?(uid: token['user'])
            @type = type
            @token = token
         end
      end

      rescue_from RuntimeError do |e|
         V1.logger.error e
         error! 'Internal Server Error', 500
      end
      
      load_namespace
      load_facility
      load_rent

      add_swagger_documentation api_version: 'v1',
         hide_documentation_path: true,
         hide_format: true,
         mount_path: '/doc',
         base_path: "#{Settings::API_URL}/facility/v1"
   end
end
