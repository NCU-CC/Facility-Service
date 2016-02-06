module HTTP
   module Error
      module Helpers
         def not_found! thing = nil
            if thing
               error! "#{thing} Not Found", 404
            else
               error! 'Not Found', 404
            end
         end

         def forbidden!
            error! 'Forbidden', 403
         end
         
         def tokens_missing!
            error! 'api_token or access_token is missing', 400
         end

         def token_missing! type
            error! "#{type}_token is missing", 400
         end

         def token_error! code
            case code
            when 401
               error! 'invalid_token', 401
            when 403
               error! 'insufficient_scope', 403
            end
         end
      end
   end
end
