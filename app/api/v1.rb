module Facility
   class V1 < Grape::API
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

      resource :namespace do
         desc 'Return namespaces.' do
            detail 'api token for all or bearer token for yours'
            success Facility::Entities::Namespace
            failure [[401, 'Unauthorized'], [404, 'Not Found']]
            headers 'X-NCU-API-TOKEN': {
               description: 'NCU api token',
               required: false
            }, Authorization: {
               description: 'NCU bearer token',
               required: false
            }
         end
         params do
            optional :order_by, type: String, values: ['created_at', 'updated_at'], default: 'created_at', desc: 'the order in the result'
         end
         get do
            @scope = [NCU::OAuth::MANAGE]
            find_token
            case @type
            when :api
               not_found! 'Namespaces' unless nss = DB::Namespace.order(params[:order_by]).all
            when :access
               not_found! 'Namespaces' unless nss = DB::User.find_by(uid: @token['user']).namespaces.order(params[:order_by])
            end
            Facility::Entities::Namespace.represent nss
         end

         route_param :id do
            desc 'Returns namespace.' do
               detail 'Bearer token is also available if the namespace is yours.'
               success Facility::Entities::Namespace
               failure [[401, 'Unauthorized'], [404, 'Not Found']]
               headers 'X-NCU-API-TOKEN': {
                  description: 'NCU api token',
                  required: false
               }, Authorization: {
                  description: 'NCU bearer token',
                  required: false
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
            end
            get do
               @scope = [NCU::OAuth::MANAGE]
               find_token
               case @type
               when :api
                  not_found! 'Namespace' unless ns = DB::Namespace.find_by(id: params[:id])
               when :access
                  not_found! 'Namespace' unless ns = DB::User.find_by(uid: @token['user']).namespaces.find_by(id: params[:id])
               end
               Facility::Entities::Namespace.represent ns
            end

            desc 'Updates namespace.' do
               detail 'Only description is modifiable.'
               success Facility::Entities::Namespace
               failure [[401, 'Unauthorized'], [404, 'Not Found']]
               headers Authorization: {
                  description: 'NCU bearer token',
                  required: true
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
               requires :description, type: String, desc: 'description'
            end
            put do
               @scope = [NCU::OAuth::MANAGE]
               find_token :access
               if ns = DB::User.find_by(uid: @token['user']).namespaces.find_by(id: params[:id])
                  ns.description = params[:description]
                  ns.save!
               else
                  not_found! 'Namespace'
               end
               Facility::Entities::Namespace.represent ns
            end

            resource :facility do
               desc 'Return facilities.' do
                  detail 'Bearer token is also available if the namespace is yours.'
                  success Facility::Entities::Facilities
                  failure [[401, 'Unauthorized'], [404, 'Not Found']]
                  headers 'X-NCU-API-TOKEN': {
                     description: 'NCU api token',
                     required: false
                  }, Authorization: {
                     description: 'NCU bearer token',
                     required: false
                  }
               end
               params do
                  requires :id, type: Integer, desc: 'namespace identifier'
                  optional :limit, type: Integer, default: 10, desc: 'maximum number of facilities returned on one result page'
                  optional :page, type: Integer, default: 1, desc: 'which result page to return'
                  optional :order_by, type: String, values: ['created_at', 'updated_at'], default: 'created_at', desc: 'the order in the result'
               end
               get do
                  @scope = [NCU::OAuth::MANAGE]
                  find_token
                  case @type
                  when :api
                     not_found! 'Namespace' unless ns = DB::Namespace.find_by(id: params[:id])
                  when :access
                     not_found! 'Namespace' unless ns = DB::User.find_by(uid: @token['user']).namespaces.find_by(id: params[:id])
                  end
                  not_found! 'Facilities' unless facilities = ns.facilities.order(params[:order_by]).page(params[:page]).per(params[:limit])
                  Facility::Entities::Facility.represent facilities
               end

               desc 'Creates a facility.' do
                  success Facility::Entities::Facility
                  failure [[401, 'Unauthorized']]
                  headers Authorization: {
                     description: 'NCU bearer token',
                     required: true
                  }
               end
               params do
                  requires :id, type: Integer, desc: 'namespace identifier'
                  requires :name, type: String, desc: 'name'
                  requires :description, type: String, desc: 'description'
               end
               post do
                  @scope = [NCU::OAuth::MANAGE]
                  find_token :access
                  not_found! 'Namespace' unless ns = DB::User.find_by(uid: @token['user']).namespaces.find_by(id: params[:id]) 
                  facility = DB::Facility.create!(name: params[:name], description: params[:description])
                  ns.facilities << facility
                  Facility::Entities::Facility.represent facility
               end
            end
         end
      end

      resource :facility do
         route_param :id do
            desc 'Returns a facility.' do
               detail 'Bearer token is also available if the facility is in your namespace.'
               success Facility::Entities::Facility
               failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
               headers 'X-NCU-API-TOKEN': {
                  description: 'NCU api token',
                  required: false
               }, Authorization: {
                  description: 'NCU bearer token',
                  required: false
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
            end
            get do
               @scope = [NCU::OAuth::MANAGE]
               find_token
               not_found! 'facility' unless facility = DB::Facility.find_by(id: params[:id])
               forbidden! unless @type == :api || facility.namespace.users.find_by(uid: @token['user'])
               Facility::Entities::Facility.represent facility
            end

            desc 'Updates a facility.' do
               success Facility::Entities::Facility
               failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
               headers Authorization: {
                  description: 'NCU bearer token',
                  required: true
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
               requires :name, type: String, desc: 'name'
               requires :description, type: String, desc: 'description'
            end
            put do
               @scope = [NCU::OAuth::MANAGE]
               find_token :access
               not_found! 'facility' unless facility = DB::Facility.find_by(id: params[:id])
               forbidden! unless facility.namespace.users.find_by(uid: @token['user'])
               facility.name = params[:name]
               facility.description = params[:description]
               facility.save!
               Facility::Entities::Facility.represent facility
            end

            desc 'Deletes a facility.' do
               success Facility::Entities::Facility
               failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
               headers Authorization: {
                  description: 'NCU bearer token',
                  required: true
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
            end
            delete do
               @scope = [NCU::OAuth::MANAGE]
               find_token :access
               not_found! 'facility' unless facility = DB::Facility.find_by(id: params[:id])
               forbidden! unless facility.namespace.users.find_by(uid: @token['user'])
               Facility::Entities::Facility.represent facility.destroy!
            end

            resource :rent do
               desc 'Return rents.' do
                  detail 'api token for all or bearer token for yours'
                  success Facility::Entities::Rents
                  failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
                  headers 'X-NCU-API-TOKEN': {
                     description: 'NCU api token',
                     required: false
                  }, Authorization: {
                     description: 'NCU bearer token',
                     required: false
                  }
               end
               params do
                  requires :id, type: Integer, desc: 'facility identifier'
                  requires :from, type: DateTime, desc: 'lower bound (inclusive) to filter by'
                  requires :to, type: DateTime, desc: 'upper bound (exclusive) to filter by'
                  optional :verified, type: String, values: ['verified', 'unverified', 'both'], default: 'both', desc: 'verified, not or both'
                  optional :limit, type: Integer, default: 10, desc: 'maximum number of facilities returned on one result page'
                  optional :page, type: Integer, default: 1, desc: 'which result page to return'
                  optional :order_by, type: String, values: ['start', 'end', 'created_at', 'updated_at'], default: 'start', desc: 'the order in the result and filter by'
               end
               get do
                  @scope = [NCU::OAuth::MANAGE, NCU::OAuth::READ]
                  find_token
                  not_found! 'Facility' unless facility = DB::Facility.find_by(id: params[:id])
                  case params[:verified]
                  when 'verified'
                     verified = [true]
                  when 'unverified'
                     verified = [false]
                  else 'both'
                     verified = [true, false]
                  end
                  error! 'Not Implemented', 501 if ['start', 'end'].include? params[:order_by]
                  case @type
                  when :api
                     not_found! 'Rents' unless rents = facility.rents.order(params[:order_by]).where(verified: verified).where(params[:order_by] => params[:from]...params[:to]).page(params[:page]).per(params[:limit])
                  when :access
                     user = DB::User.find_by(uid: @token['user'])
                     if @token['scope'].include? NCU::OAuth::MANAGE
                        forbidden! unless facility.namespace.users.include? user
                        not_found! 'Rents' unless rents = facility.rents.order(params[:order_by]).where(verified: verified).where(params[:order_by] => params[:from]...params[:to]).page(params[:page]).per(params[:limit])
                     else
                        not_found! 'Rents' unless rents = facility.rents.order(params[:order_by]).where(user: user).where(verified: verified).where(params[:order_by] => params[:from]...params[:to]).page(params[:page]).per(params[:limit])
                     end
                  end
                  rents = Facility::Entities::Rent.represent(rents).as_json
                  if @type == :api
                     rents.each { |rent| rent[:creator].delete :id }
                  end
                  {rents: rents, count: rents.size, page: params[:page]}
               end

               desc 'Creates a rent.' do
                  success Facility::Entities::Rent
                  failure [[401, 'Unauthorized']]
                  headers Authorization: {
                     description: 'NCU bearer token',
                     required: true
                  }
               end
               params do
                  requires :id, type: Integer, desc: 'facility identifier'
                  requires :name, type: String, desc: 'name'
                  requires :spans, type: Array[JSON] do
                     requires :start, type: DateTime, desc: 'start time'
                     requires :end, type: DateTime, desc: 'end time'
                  end
               end
               post do
                  @scope = [NCU::OAuth::WRITE]
                  find_token :access
                  not_found! 'Facility' unless facility = DB::Facility.find_by(id: params[:id])
                  rent = DB::Rent.create!(name: params[:name], verified: false)
                  facility.rents << rent
                  DB::User.find_by(uid: @token['user']).rents << rent
                  params[:spans].each do |time|
                     span = DB::Span.create!(start: time[:start], 'end': time[:end])
                     rent.spans << span
                  end
                  Facility::Entities::Rent.represent rent
               end
            end
         end
      end

      resource :rent do
         route_param :id do
            desc 'Returns a rent.' do
               detail 'Bearer token is also available if the rent or the namespace is yours.'
               success Facility::Entities::Rent
               failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
               headers 'X-NCU-API-TOKEN': {
                  description: 'NCU api token',
                  required: false
               }, Authorization: {
                  description: 'NCU bearer token',
                  required: false
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
            end
            get do
               @scope = [NCU::OAuth::READ, NCU::OAuth::MANAGE]
               find_token
               case @type
               when :api
                  not_found! 'Rent' unless rent = DB::Rent.find_by(id: params[:id])
               when :access
                  not_found! 'Rent' unless rent = DB::Rent.find_by(id: params[:id])
                  user = DB::User.find_by(uid: @token['user'])
                  forbidden! unless @token['scope'].include?(NCU::OAuth::READ) && rent.user == user || @token['scope'].include?(NCU::OAuth::MANAGE) && rent.facility.namespace.users.include?(user)
               end
               rent = Facility::Entities::Rent.represent(rent).as_json
               rent[:creator].delete :id
               rent
            end

            desc 'Updates a rent.' do
               detail 'Only the owner of the namespace can modify the rent.'
               success Facility::Entities::Rent
               failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
               headers Authorization: {
                  description: 'NCU bearer token',
                  required: true
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
               requires :name, type: String, desc: 'name'
               requires :spans, type: Array do
                  requires :start, type: DateTime, desc: 'start time'
                  requires :end, type: DateTime, desc: 'end time'
               end
            end
            put do
               @scope = [NCU::OAuth::MANAGE]
               find_token :access
               error! 'Not Implemented', 501
            end

            desc 'Deletes a rent.' do
               detail 'The owner can\'t delete the rent if it is verified, but the owner of the namespace can delete it no matter whether it is verified or not.'
               success Facility::Entities::Rent
               failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
               headers Authorization: {
                  description: 'NCU bearer token',
                  required: true
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
            end
            delete do
               @scope = [NCU::OAuth::WRITE, NCU::OAuth::MANAGE]
               find_token :access
               not_found! 'Rent' unless rent = DB::Rent.find_by(id: params[:id])
               user = DB::User.find_by(uid: @token['user'])
               if @token['scope'].include? NCU::OAuth::MANAGE
                  forbidden! unless rent.facility.namespace.users.include? user
               else
                  forbidden! unless rent.user == user
               end
               Facility::Entities::Rent.represent rent.destroy!
            end

            desc 'Verifies or unverifies a rent.' do
               detail 'Only the owner of the namespace can verify of unverify the rent'
               success Facility::Entities::Rent
               failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
               headers Authorization: {
                  description: 'NCU bearer token',
                  required: true
               }
            end
            params do
               requires :id, type: Integer, desc: 'identifier'
               requires :verify, type: Boolean, default: 'true', desc: 'true to verify or false to unverify'
            end
            put :verify do
               @scope = [NCU::OAuth::MANAGE]
               find_token :access
               not_found! 'Rent' unless rent = DB::Rent.find_by(id: params[:id])
               user = DB::User.find_by(uid: @token['user'])
               forbidden! unless rent.facility.namespace.users.include? user
               rent.verified = params[:verify]
               rent.save!
               Facility::Entities::Rent.represent rent
            end
         end
      end

      add_swagger_documentation api_version: 'v1',
         hide_documentation_path: true,
         hide_format: true,
         mount_path: '/doc',
         base_path: "#{Settings::API_URL}/facility/v1"
   end
end
