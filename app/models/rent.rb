module DB
   class Rent < ActiveRecord::Base
      belongs_to :facility
      belongs_to :user
      has_many :spans
   end
end
