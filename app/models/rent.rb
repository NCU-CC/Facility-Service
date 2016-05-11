module DB
   class Rent < ActiveRecord::Base
      belongs_to :facility
      belongs_to :user
      has_many :spans

      before_update do |rent|
         if rent.verified_changed?
            facility = rent.facility
            calendar_id = rent.verified_was ? facility.rent_calendar_id : facility.verify_calendar_id
            new_calendar_id = rent.verified ? facility.rent_calendar_id : facility.verify_calendar_id
            rent.spans.each do |span|
               Gcap.event.move calendar_id, span.event_id, new_calendar_id
            end
         end
      end
   end
end
