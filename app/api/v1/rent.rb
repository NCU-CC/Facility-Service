module Facility
   module Rent
      module V1
         def load_rent
            resource :rent do
               route_param :id do
                  desc 'Returns a rent.' do
                     detail 'Bearer token is also available if the rent or the namespace is yours.'
                     success Entities::Rent
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
                     rent = Entities::Rent.represent(rent).as_json
                     rent[:creator].delete :id if @type == :api
                     rent
                  end

                  desc 'Updates a rent.' do
                     detail 'Only the owner of the namespace can modify the rent.'
                     success Entities::Rent
                     failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
                     headers Authorization: {
                        description: 'NCU bearer token',
                        required: true
                     }
                  end
                  params do
                     requires :id, type: Integer, desc: 'identifier'
                     requires :name, type: String, desc: 'name'
                     requires :spans, type: Array[JSON] do
                        requires :start, type: DateTime, desc: 'start time'
                        requires :end, type: DateTime, desc: 'end time'
                     end
                  end
                  put do
                     @scope = [NCU::OAuth::MANAGE]
                     find_token :access
                     not_found! 'Rent' unless rent = DB::Rent.find_by(id: params[:id])
                     user = DB::User.find_by(uid: @token['user'])
                     forbidden! unless rent.facility.namespace.users.include?(user)
                     rent.update!(name: params[:name])
                     spans = rent.spans
                     new_spans = []
                     params[:spans].each do |time|
                        new_spans << DB::Span.new(start: time[:start], 'end': time[:end])
                     end
                     spans, new_spans = spans - new_spans, new_spans - spans
                     spans.each do |span|
                        span.destroy!
                     end
                     new_spans.each do |span|
                        span.save!
                        rent.spans << span
                     end
                     Entities::Rent.represent rent
                  end

                  desc 'Deletes a rent.' do
                     detail 'The owner can\'t delete the rent if it is verified, but the owner of the namespace can delete it no matter whether it is verified or not.'
                     success Entities::Rent
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
                        forbidden! if rent.verified
                     end
                     Entities::Rent.represent rent.destroy!
                  end

                  desc 'Verifies or unverifies a rent.' do
                     detail 'Only the owner of the namespace can verify of unverify the rent'
                     success Entities::Rent
                     failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Not Found']]
                     headers Authorization: {
                        description: 'NCU bearer token',
                        required: true
                     }
                  end
                  params do
                     requires :id, type: Integer, desc: 'identifier'
                     requires :verify, type: Virtus::Attribute::Boolean, default: 'true', desc: 'true to verify or false to unverify'
                  end
                  put :verify do
                     @scope = [NCU::OAuth::MANAGE]
                     find_token :access
                     not_found! 'Rent' unless rent = DB::Rent.find_by(id: params[:id])
                     user = DB::User.find_by(uid: @token['user'])
                     forbidden! unless rent.facility.namespace.users.include? user
                     rent.verified = params[:verify]
                     rent.save!
                     Entities::Rent.represent rent
                  end
               end
            end
         end
      end
   end
end
