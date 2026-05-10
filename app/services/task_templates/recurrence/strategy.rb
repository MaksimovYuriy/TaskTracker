module TaskTemplates
  module Recurrence
    class Strategy
      def self.call(template, range:)
        new(template, range: range).call
      end

      def initialize(template, range:)
        @template = template
        @range = range
      end

      private

      attr_reader :template, :range

      def combine(date)
        time = template.time_of_day
        Time.zone.local(date.year, date.month, date.day, time.hour, time.min, time.sec)
      end

      def applicable?(time)
        in_range?(time) && within_ends_at?(time)
      end

      def in_range?(time)
        time >= range.begin && time <= range.end
      end

      def within_ends_at?(time)
        template.ends_at.nil? || time.to_date <= template.ends_at
      end
    end
  end
end
