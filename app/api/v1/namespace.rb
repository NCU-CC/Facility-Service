module Facility
   module Namespace
      module V1
         def load_namespace
            resource :namespace do
               desc 'Return namespaces.' do
                  detail 'api token for all or bearer token for yours'
                  success Entities::Namespace
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
                  Entities::Namespace.represent nss
               end

               route_param :id do
                  desc 'Returns namespace.' do
                     detail 'Bearer token is also available if the namespace is yours.'
                     success Entities::Namespace
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
                     Entities::Namespace.represent ns
                  end

                  desc 'Updates namespace.' do
                     detail 'Only description is modifiable.'
                     success Entities::Namespace
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
                     Entities::Namespace.represent ns
                  end

                  resource :facility do
                     desc 'Return facilities.' do
                        detail 'Bearer token is also available if the namespace is yours.'
                        success Entities::Facilities
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
                        Entities::Facility.represent facilities
                     end

                     desc 'Creates a facility.' do
                        success Entities::Facility
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
                        facility = DB::Facility.create!(name: params[:name], description: params[:description], namespace: ns)
                        Entities::Facility.represent facility
                     end
                  end
               end
            end
         end
      end
   end
end
