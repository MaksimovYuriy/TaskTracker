module TaskTemplates
  module Recurrence
    class MonthlyStrategy < Strategy
      def call
        occurrences = []
        month = range.begin.beginning_of_month.to_date
        while month <= range.end.to_date
          candidate = candidate_for(month)
          occurrences << candidate if candidate && applicable?(candidate)
          month = month.next_month
        end
        occurrences
      end

      private

      def candidate_for(month)
        return nil unless Date.valid_date?(month.year, month.month, day_of_month)
        combine(Date.new(month.year, month.month, day_of_month))
      end

      def day_of_month
        template.day_of_month
      end
    end
  end
end
