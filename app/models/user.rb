module DB
   class User < ActiveRecord::Base
      has_and_belongs_to_many :namespaces
      has_many :rents
   end
end
