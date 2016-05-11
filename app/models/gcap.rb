module Gcap
   extend self
   APPLICATION_NAME = 'FacilityService'
   SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

   attr_reader :client, :calendar, :event

   def self.initialize
      @client = Google::Apis::CalendarV3::CalendarService.new
      @client.client_options.application_name = APPLICATION_NAME
      @client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: File.new(Settings::GOOGLE_JSON_PATH), scope: SCOPE)
      @event = Event.new @client
      @calendar = Calendar.new @client
   end

   class Calendar
      def initialize client
         @client = client
      end

      def list
         calendars = []
         @client.list_calendar_lists do |calendar_list, err|
            raise err unless err.nil?
            calendar_list.items.each do |entry|
               calendars << get(entry.id)
            end
         end
         calendars
      end

      # requires: [:summary, :description]
      def insert calendar
         @client.insert_calendar Google::Apis::CalendarV3::Calendar.new(calendar) do |calendar, err|
            raise err unless err.nil?
            @client.insert_acl(calendar.id, Google::Apis::CalendarV3::AclRule.new({role: 'reader', scope: {type: 'default'}}))
         end
      end

      # requires: [:id, :summary, description]
      def update calendar
         @client.update_calendar calendar[:id], Google::Apis::CalendarV3::Calendar.new(calendar) do |calendar, err|
            raise err unless err.nil?
         end
      end

      def delete calendar_id
         @client.delete_calendar calendar_id do |calendar, err|
            raise err unless err.nil?
         end
      end

      def get calendar_id
         @client.get_calendar calendar_id do |calendar, err|
            raise err unless err.nil?
         end
      end
   end

   class Event
      def initialize client
         @client = client
      end

      def insert calendar_id, event
         @client.insert_event(calendar_id, Google::Apis::CalendarV3::Event.new(event)) do |event, err|
            raise err unless err.nil?
         end
      end

      def update calendar_id, event
         @client.update_event(calendar_id, event['id'], Google::Apis::CalendarV3::Event.new(event)) do |event, err|
            raise err unless err.nil?
         end
      end

      def delete calendar_id, event_id
         @client.delete_event calendar_id, event_id do |event, err|
            raise err unless err.nil?
         end
      end

      def get calendar_id, event_id
         @client.get_event calendar_id, event_id do |event, err|
            raise err unless err.nil?
         end
      end

      def move calendar_id, event_id, new_calendar_id
         @client.move_event calendar_id, event_id, new_calendar_id do |event, err|
            raise err unless err.nil?
         end
      end
   end
   initialize
end

