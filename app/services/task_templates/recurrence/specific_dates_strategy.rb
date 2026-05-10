module TaskTemplates
  module Recurrence
    class SpecificDatesStrategy < Strategy
      def call
        template.specific_dates.map { |date| combine(date) }
                               .select { |t| applicable?(t) }
      end
    end
  end
end
