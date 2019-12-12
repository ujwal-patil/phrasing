module Phrasing
  module Serializer
    class << self

      def import_yaml(yaml)
        number_of_changes = 0
        hash = YAML.load(yaml)

        hash.each do |locale, data|
          flatten_the_hash(data).each do |key, value|
            phrase = PhrasingPhrase.where(key: key, locale: locale).first || PhrasingPhrase.new(key: key, locale: locale)
            if phrase.value != value
              phrase.value = value
              number_of_changes += 1
              phrase.save
            end
          end
        end

        number_of_changes
      end

      def flatten_the_hash(hash)
        new_hash = {}
        hash.each do |key, value|
          if value.is_a? Hash
            flatten_the_hash(value).each do |k,v|
              new_hash["#{key}.#{k}"] = v
            end
          else
            new_hash[key] = value
          end
        end
        new_hash
      end

      def export_yaml(phrasing_phrases, file_name)
        hash = {}
        phrasing_phrases.each do |phrase|
          hash[phrase.locale] ||= {}
          hash[phrase.locale][phrase.key] = phrase.value
        end

        file = Tempfile.new([file_name])
        File.open(file.path, 'w') do |f| 
          f.write hash.to_yaml 
        end

        file
      end

      def export_delta_yaml(locale, file_name)
        file = Tempfile.new([file_name])
        File.open(file.path, 'w') do |f| 
          f.write Phrasing::UselessRemover.new(locale).extract.to_yaml 
        end

        file
      end
    end
  end
end

