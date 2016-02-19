module Facility
   module Entities
      class User < Grape::Entity
         expose :uid, as: :id, documentation: {type: 'string', desc: 'identifier', required: true}
         expose :name, documentation: {type: 'string', desc: 'name', required: true}
         expose :unit, documentation: {type: 'string', desc: 'unit', required: true}
      end

      class Namespace < Grape::Entity
         expose :id, documentation: {type: 'integer', desc: 'identifier', required: true}
         expose :name, documentation: {type: 'string', desc: 'name', required: true}
         expose :description, documentation: {type: 'string', desc: 'description', required: true}
      end

      class Facility < Grape::Entity
         expose :id, documentation: {type: 'integer', desc: 'identifier', required: true}
         expose :name, documentation: {type: 'string', desc: 'name', required: true}
         expose :description, documentation: {type: 'string', desc: 'description', required: true}
         expose :verify_calendar_id, documentation: {type: 'string', desc: 'calender identifier for unverified rents', required: true}
         expose :rent_calendar_id, documentation: {type: 'string', desc: 'calender identifier for rents', required: true}
      end

      class Facilities < Grape::Entity
         expose :facilities, using: Facility, documentation: {is_array: true, required: true}
         expose :count, documentation: {type: 'integer', desc: 'number of facilities', required: true}
         expose :page, documentation: {type: 'integer', desc: 'page number'}
      end

      class Span < Grape::Entity
         expose :event_id, as: :id, documentation: {type: 'string', desc: 'identifier', required: true}
         expose :start, documentation: {type: 'string', format: 'date-time', desc: 'start time', required: true}
         expose :end, documentation: {type: 'string', format: 'date-time', desc: 'end time', required: true}
      end

      class Rent < Grape::Entity
         expose :id, documentation: {type: 'integer', desc: 'identifier', required: true}
         expose :user, as: :creator, using: User, documentation: {desc: 'creator', required: true}
         expose :name, documentation: {type: 'string', desc: 'name', required: true}
         expose :created_at, documentation: {type: 'string', format: 'date-time', desc: 'creation time'}
         expose :updated_at, documentation: {type: 'string', format: 'date-time', desc: 'last modification time'}
         expose :verified, documentation: {type: 'boolean', desc: 'true if verified'}
         expose :spans, as: :span, using: Span, documentation: {is_array: true, required: true}
      end

      class Rents < Grape::Entity
         expose :rents, using: Rent, documentation: {is_array: true, required: true}
         expose :count, documentation: {type: 'integer', desc: 'number of rents', required: true}
         expose :page, documentation: {type: 'integer', desc: 'page number'}
      end
   end
end
