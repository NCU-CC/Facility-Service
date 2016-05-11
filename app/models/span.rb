module DB
   class Span < ActiveRecord::Base
      belongs_to :rent

      def eql? span
         span.kind_of?(Span) && self.start == span.start && self.end == span.end
      end

      def hash
         [self.start, self.end].hash
      end

      before_create do |span|
         rent = span.rent
         facility = rent.facility
         calendar_id = rent.verified ? facility.rent_calendar_id : facility.verify_calendar_id
         self.event_id = Gcap.event.insert(calendar_id, {
            summary: rent.name,
            description: "#{rent.user.unit}-#{rent.user.name}",
            start: {date_time: span.start},
            'end': {date_time: span.end}
         }).id
      end

      before_destroy do |span|
         rent = span.rent
         facility = rent.facility
         calendar_id = rent.verified ? facility.rent_calendar_id : facility.verify_calendar_id
         Gcap.event.delete calendar_id, self.event_id
      end
   end
end
