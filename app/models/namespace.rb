module DB
   class Namespace < ActiveRecord::Base
      has_and_belongs_to_many :users
      has_many :facilities
   end
end
