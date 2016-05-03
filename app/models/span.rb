module DB
   class Span < ActiveRecord::Base
      belongs_to :rent

      def eql? span
         span.kind_of?(Span) && self.start == span.start && self.end == span.end
      end

      def hash
         [self.start, self.end].hash
      end
   end
end
