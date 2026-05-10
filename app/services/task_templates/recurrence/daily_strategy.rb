# frozen_string_literal: true

module TaskTemplates
  module Recurrence
    class DailyStrategy < Strategy
      def call
        occurrences = []
        date = anchor
        while date <= range.end.to_date
          candidate = combine(date)
          occurrences << candidate if applicable?(candidate)
          date += interval
        end
        occurrences
      end

      private

      def anchor
        template.created_at.to_date
      end

      def interval
        template.interval
      end
    end
  end
end
