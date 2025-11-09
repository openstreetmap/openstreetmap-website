require 'yaml'

desc 'Tally occurrences of "OHM" vs "OSM" across locales.'

namespace :ohm do
  task :tally do
    PLURALIZATION_KEYS = %w[
      zero
      one
      two
      few
      many
      other
    ]

    def locale
      @locale
    end

    def tally
      @tally ||= {}
    end

    def locales_to_keys
      @locales_to_keys ||= {}
    end

    def get_flat_keys(hash, path = [])
      hash.map do |k, v|

        new_path = path + [ k ]

        # Ignore any pluralization differences.
        if v.is_a?(Hash) && looks_like_plural?(v)
          v = "Pretend it's a leaf."
        end

        case v
        when Hash
          get_flat_keys(v, new_path)
        when String
          counts = [
            v.scan(/OpenHistoricalMap/i).count,
            v.scan(/OpenStreetMap/i).count,
            v.scan(/\bOHM\b/i).count,
            v.scan(/\bOSM\b/i).count
          ]
          if (counts.any? { |n| n != 0 }) then
            tally[@locale].store(new_path.join("."), counts)
          end
          # new_path.join(".")
        else
          raise "wtf? #{ v }"
        end
      end.flatten
    end

    def looks_like_plural?(hash)
      hash.keys.length > 1 && hash.keys.all? { |k| PLURALIZATION_KEYS.include?(k) }
    end

    i18n_files = Dir["config/locales/*.yml"].select { |x| File.basename(x).match(/\b.*.yml/) }
    i18n_files.each do |file|
      @locale = File.basename(file, ".*")
      hash = YAML.load_file(file)[@locale]
      tally[@locale] = {}
      locales_to_keys[@locale] = get_flat_keys(hash)
    end

    tally.each do |k, v|
      unless k === 'en' then
        # iterate through objects, comparing numbers against 'en'
        # if the key does not exist in 'en', print & flag it
        # if the key does exist in 'en' and the array differs, print it
        #
        printf("\n\nlocale: %s\n", k)
        printf("%84s %8s %5s %8s\n", '*Historical*', '*Street*', 'OHM', 'OSM')
        v.each_with_object([]) do |l, w|
          begin
            ref = tally['en'][l[0]]
            unless ref == l[1] then
              printf("%66s (en) %8d %8d %8d %8d\n", l[0], ref[0], ref[1], ref[2], ref[3])
              printf("%66s (%s) %8d %8d %8d %8d\n", l[0], k, l[1][0], l[1][1], l[1][2], l[1][3])
            end
          rescue NoMethodError
            printf("\n\nen has no key %s found in locale %s\n\n", l[0], k)
          end
        end
      end
    end

  end
end
