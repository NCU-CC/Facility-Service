module NCU
   module OAuth
      READ = 'facility.rent.read'
      WRITE = 'facility.rent.write'
      VERIFY = 'facility.rent.verify'
      MANAGE = 'facility.manage'

      module Helpers
         def api_token
            return @api_token unless @api_token.nil?
            if headers.has_key?('X-Ncu-Api-Token') && this_token_string = headers['X-Ncu-Api-Token']
               RestClient.get Settings::OAUTH_API_TOKEN_URL + this_token_string + oauth_params, {x_ncu_api_token: Settings::NCU_API_TOKEN} do |response, request, result, &block|
                  if response.code == 200
                     @api_token = JSON.parse response.body
                  else
                     @api_token = 401
                  end  
               end
            else
               @api_token = 400
            end
            @api_token
         end

         def access_token
            return @access_token unless @access_token.nil?
            this_token_string = token_string
            return @access_token = 400 if this_token_string.nil?
            RestClient.get Settings::OAUTH_ACCESS_TOKEN_URL + this_token_string + oauth_params, {x_ncu_api_token: Settings::NCU_API_TOKEN} do |response, request, result, &block|
               if response.code == 200
                  res = JSON.parse response.body
                  return @access_token = res.merge(token_info this_token_string) unless (res['scope'] & @scope).empty?
                  @access_token = 403
               else
                  @access_token = 401
               end
            end
            @access_token
         end

         def api_or_access_token type
            return @api_or_access_token unless @api_or_access_token.nil?
            return [@api_or_access_token = api_token, :api] if type == :api
            return [@api_or_access_token = access_token, :access] if type == :access
            if access_token.kind_of? Fixnum 
               if api_token.kind_of? Fixnum
                  if access_token == 400 && api_token == 400
                     [400, :both]
                  elsif access_token != 400
                     [access_token, :access]
                  else
                     [api_token, :api]
                  end
               else
                  [api_token, :api]
               end
            else
               [access_token, :access]
            end
         end

         def token_info this_token_string
            response = RestClient.get Settings::PERSONNEL_INFO_URL, {authorization: "Bearer #{this_token_string}"}
            res = JSON.parse response.body
         end

         def token_string
            token_string_from_header || token_string_from_request_params
         end

         def token_string_from_header
            Rack::Auth::AbstractRequest::AUTHORIZATION_KEYS.each do |key|
               if env.has_key?(key) && token_string = env[key][/^Bearer (.*)/, 1]
                  return token_string
               end
            end
            nil
         end

         def token_string_from_request_params
            params[:access_token]
         end

         def oauth_params
            '?ip=' + headers['X-Forwarded-For'] + (!header['Referer'].nil? ? '&referer=' + CGI.escape(headers['Referer']) : '' )
         end

      end
   end
end
