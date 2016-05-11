module DB
   class Facility < ActiveRecord::Base
      VERIFY = '審核中'
      RENT = '已借出'
      TIME_ZONE = 'Asia/Taipei'
      belongs_to :namespace
      has_many :rents

      before_create do |facility|
         self.verify_calendar_id = Gcap.calendar.insert({
            summary: "#{facility.name} #{VERIFY}",
            description: facility.description,
            time_zone: TIME_ZONE
         }).id
         self.rent_calendar_id = Gcap.calendar.insert({
            summary: "#{facility.name} #{RENT}",
            description: facility.description,
            time_zone: TIME_ZONE
         }).id
      end

      before_update do |facility|
         if facility.name_changed? || facility.description_changed?
            Gcap.calendar.update({
               id: facility.verify_calendar_id,
               summary: "#{facility.name} #{VERIFY}",
               description: facility.description,
               time_zone: TIME_ZONE
            })
            Gcap.calendar.update({
               id: facility.rent_calendar_id,
               summary: "#{facility.name} #{RENT}",
               description: facility.description,
               time_zone: TIME_ZONE
            })
         end
      end

      before_destroy do |facility|
         Gcap.calendar.delete facility.verify_calendar_id
         Gcap.calendar.delete facility.rent_calendar_id
      end
   end
end
