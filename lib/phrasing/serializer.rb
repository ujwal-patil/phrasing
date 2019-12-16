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
          next if (phrase.locale.to_s != 'en' && phrase.key == phrase.value)
          hash[phrase.locale][phrase.key] = phrase.value
        end

        file = Tempfile.new([file_name])
        File.open(file.path, 'w') do |f| 
          f.write hash.to_yaml 
        end

        file
      end

      def export_delta_yaml(locale, file_name)
        hash = {}
        other_phrases = PhrasingPhrase.locale(locale).where("key != value").pluck(:key, :value).to_h
        
        PhrasingPhrase.locale.each do |en_phrase|
          if other_phrases[en_phrase.key].nil? || other_phrases[en_phrase.key] == en_phrase.value
            hash[locale] ||= {}
            hash[locale][en_phrase.key] = en_phrase.value
          end
        end

        file = Tempfile.new([file_name])
        File.open(file.path, 'w') do |f| 
          f.write hash.to_yaml
        end

        file
      end
    end
  end
end

