module Facility
   module Facility
      module V1
         def load_facility
            resource :facility do
               route_param :id do
                  desc 'Returns a facility.' do
                     detail 'Bearer token is also available if the facility is in your namespace.'
                     success Entities::Facility
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
                     Entities::Facility.represent facility
                  end

                  desc 'Updates a facility.' do
                     success Entities::Facility
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
                     Entities::Facility.represent facility
                  end

                  desc 'Deletes a facility.' do
                     success Entities::Facility
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
                     Entities::Facility.represent facility.destroy!
                  end

                  resource :rent do
                     desc 'Return rents.' do
                        detail 'api token for all or bearer token for yours'
                        success Entities::Rents
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
                        case @type
                        when :api
                           if ['start', 'end'].include? params[:order_by]
                              not_found! 'Rents' unless rents = facility.rents.joins(:spans).order("spans.#{params[:order_by]}").where(verified: verified).where(:spans => {params[:order_by] => params[:from]...params[:to]}).page(params[:page]).per(params[:limit]).uniq
                           else
                              not_found! 'Rents' unless rents = facility.rents.order(params[:order_by]).where(verified: verified).where(params[:order_by] => params[:from]...params[:to]).page(params[:page]).per(params[:limit])
                           end
                        when :access
                           user = DB::User.find_by(uid: @token['user'])
                           if @token['scope'].include? NCU::OAuth::MANAGE
                              forbidden! unless facility.namespace.users.include? user
                              if ['start', 'end'].include? params[:order_by]
                                 not_found! 'Rents' unless rents = facility.rents.joins(:spans).order("spans.#{params[:order_by]}").where(verified: verified).where(:spans => {params[:order_by] => params[:from]...params[:to]}).page(params[:page]).per(params[:limit]).uniq
                              else
                                 not_found! 'Rents' unless rents = facility.rents.order(params[:order_by]).where(verified: verified).where(params[:order_by] => params[:from]...params[:to]).page(params[:page]).per(params[:limit])
                              end
                           else
                              if ['start', 'end'].include? params[:order_by]
                                 not_found! 'Rents' unless rents = facility.rents.joins(:spans).order("spans.#{params[:order_by]}").where(user: user).where(verified: verified).where(:spans => {params[:order_by] => params[:from]...params[:to]}).page(params[:page]).per(params[:limit]).uniq
                              else
                                 not_found! 'Rents' unless rents = facility.rents.order(params[:order_by]).where(user: user).where(verified: verified).where(params[:order_by] => params[:from]...params[:to]).page(params[:page]).per(params[:limit])
                              end
                           end
                        end
                        rents = Entities::Rent.represent(rents).as_json
                        if @type == :api
                           rents.each { |rent| rent[:creator].delete :id }
                        end
                        {rents: rents, count: rents.size, page: params[:page]}
                     end

                     desc 'Creates a rent.' do
                        success Entities::Rent
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
                        params[:spans].each do |time|
                           rent.spans << DB::Span.create!(start: time[:start], 'end': time[:end])
                        end
                        DB::User.find_by(uid: @token['user']).rents << rent
                        facility.rents << rent
                        Entities::Rent.represent rent
                     end
                  end
               end
            end
         end
      end
   end
end


