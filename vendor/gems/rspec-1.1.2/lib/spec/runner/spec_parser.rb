module Spec
  module Runner
    # Parses a spec file and finds the nearest example for a given line number.
    class SpecParser
      def spec_name_for(io, line_number)
        source  = io.read
        example_group, example_group_line = example_group_at_line(source, line_number)
        example, example_line = example_at_line(source, line_number)
        if example_group && example && (example_group_line < example_line)
          "#{example_group} #{example}"
        elsif example_group
          example_group
        else
          nil
        end
      end

    protected

      def example_group_at_line(source, line_number)
        find_above(source, line_number, /^\s*(context|describe)\s+(.*)\s+do/)
      end

      def example_at_line(source, line_number)
        find_above(source, line_number, /^\s*(specify|it)\s+(.*)\s+do/)
      end

      # Returns the context/describe or specify/it name and the line number
      def find_above(source, line_number, pattern)
        lines_above_reversed(source, line_number).each_with_index do |line, n|
          return [parse_description($2), line_number-n] if line =~ pattern
        end
        nil
      end

      def lines_above_reversed(source, line_number)
        lines = source.split("\n")
        lines[0...line_number].reverse
      end
      
      def parse_description(str)
        return str[1..-2] if str =~ /^['"].*['"]$/
        if matches = /^['"](.*)['"](,.*)?$/.match(str)
          return ::Spec::Example::ExampleGroupMethods.description_text(matches[1])
        end
        if matches = /^(.*)\s*,\s*['"](.*)['"](,.*)?$/.match(str)
          return ::Spec::Example::ExampleGroupMethods.description_text(matches[1], matches[2])
        end
        return str
      end
    end
  end
end
