module TaskTemplates
  module Recurrence
    class EvenDaysStrategy < Strategy
      def call
        occurrences = []
        date = range.begin.to_date
        while date <= range.end.to_date
          if date.day.even?
            candidate = combine(date)
            occurrences << candidate if applicable?(candidate)
          end
          date += 1
        end
        occurrences
      end
    end
  end
end
