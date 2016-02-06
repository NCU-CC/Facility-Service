module DB
   class Facility < ActiveRecord::Base
      belongs_to :namespace
      has_many :rents
   end
end
