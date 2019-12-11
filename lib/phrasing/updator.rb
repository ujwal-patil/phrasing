module Phrasing
  class Updator

    def initialize(locale)
      if I18n.available_locales.include?(locale.to_sym)
        @locale = locale
        @word_counter = Phrasing::WordCounter.new
        @current_file_version = fetch_current_file_version
        @current_file_path = current_locale_file_path
      else
        raise I18n::InvalidLocale.new(locale)
      end
    end

    attr_reader :current_file_version

    # Phrasing::Updator.new(:en).update_files
    # This will update the spacified locale file by the values present in database
    def update_files
      PhrasingPhrase.transaction do
        # 1) Get file contents as keys and values
        keys_and_values = yml_to_keys_and_values
        old_version_keys_and_values = keys_and_values.clone

        # 2) Update all translated values in keys_and_values
        puts "Updating.."
        phrasing_phrases.each do |phrase|
          print "."
          next if phrase.key == phrase.value

          @word_counter.update(keys_and_values["#{phrase.locale}.#{phrase.key}"], phrase.yml_value)

          keys_and_values["#{phrase.locale}.#{phrase.key}"] = phrase.yml_value
        end

        # 3) Update keys_and_values to same yml file
        if @word_counter.has_change?
          # Create last version file entry in releases
          create_to_recent_version_entry_for(old_version_keys_and_values)
          # Update root file to new version
          update_as_next_root_version(keys_and_values)
        end

        # 4) Delete All Database Records for lang
        # phrasing_phrases.delete_all

        display_word_count

        # Return true for successfull execution
        return @word_counter.has_change?
      end
    end

    # Phrasing::Updator.new(:en).create_phrases
    # Create active records for all root file keys
    # Created records will be shown on all keys list views
    # This will not create records for keys start with whitelisted sections(Phrasing.whitelisted_keys_section_for_remover)
    def create_phrases
      pinwheel = %w{ | / - \\ }
      puts "Creating keys for locale : #{@locale}"
      _keys_and_values = yml_to_keys_and_values
      _keys_and_values.each_with_index do |(key, value), index|
        percentage = ((index + 1).to_f / _keys_and_values.length * 100).to_i
        print "\b" * 50, "Progress: #{percentage}% - #{index + 1}/#{_keys_and_values.length} ", pinwheel.rotate!.first

        _key = key.to_s.split('.')[1..-1] * '.'
        next if whitelisted?(_key)
        phrasing_phrases.find_or_initialize_by(key:  _key).tap do |pp|
          pp.value = value
          pp.save
        end
      end
      puts 'Done.'
    end

    def whitelisted?(key)
      Phrasing.whitelisted_keys_section_for_remover.any?{|m| key.start_with?(m)}
    end

    def update_as_next_root_version(keys_and_values)
      # create new file with next root file version
      keys_and_values_to_yml(keys_and_values, next_root_version_path)
      # remove existing root file
      remove_invalid_files
    end

    def create_to_recent_version_entry_for(keys_and_values)
      keys_and_values_to_yml(keys_and_values, recent_version_path)
    end

    def display_word_count
      puts "\n"
      puts <<-Translator
        ========================================================================
            Added Word Count : #{@word_counter.added_words}
          Removed Word Count : #{@word_counter.removed_words}
        ========================================================================
      Translator
    end

    def yml_to_keys_and_values
      load_locale_file(@current_file_path)
    end

    def blacklisted_phrases_keys
      Phrasing.blacklisted_file_names.map do |file_name|
        _file = File.join(Phrasing.locale_file_path, "#{file_name}.#{@locale}.yml")
        next unless File.exist?(_file)

        load_locale_file(_file).keys
      end.flatten.compact
    end

    def remove_invalid_files
      FileUtils.rm_f(@current_file_path)

      blacklisted_file_paths = Phrasing.blacklisted_file_names.map do |file_name|
        File.join(Phrasing.locale_file_path, "#{file_name}.#{@locale}.yml")
      end

      # Check for invalid files
      invalid_files = Dir[File.join(Phrasing.locale_file_path, "*.#{@locale}.yml")] - [blacklisted_file_paths, current_locale_file_path].flatten

      # Remove old release file for current locale
      invalid_files << (current_locale_releases - current_locale_releases.sort.last(Phrasing.keep_recent_release_count))

      invalid_files.flatten.each do |file_path|
        FileUtils.rm_f(file_path)
        puts "\n\e[31mRemoved invalid file: #{file_path}\e[0m"
      end
    end

    def current_locale_releases
      Dir[File.join(Phrasing.locale_file_path, 'releases', "*.#{@locale}.yml")]
    end

    private

    def next_root_version_path
      # <latest_version>.root.fr.yml
      File.join(Phrasing.locale_file_path, "v#{next_file_version}.root.#{@locale}.yml")
    end

    def recent_version_path
      #<previous_version>.<Current Time stamp>.root.fr.yml
      File.join(Phrasing.locale_file_path, "releases", "#{current_file_version}.#{Time.now.to_i}.#{@locale}.yml")
    end

    def next_file_version
      current_file_version.sub('v', '').to_i + 1
    end

    def fetch_current_file_version
      current_locale_file_path.gsub(Phrasing.locale_file_path.to_s, '').scan(/v[0-9]*/).first || 'v1'
    end

    def load_locale_file(file_path)
      return {} unless File.exist?(file_path)

      keys_and_values = {}
      traverse(YAML.load_file(file_path)) do |keys, value|
        keys_and_values[keys * '.'] = value
      end

      keys_and_values
    end

    def current_locale_file_path
      Dir[File.join(Phrasing.locale_file_path, "*root.#{@locale}.yml")].last
    end

    def phrasing_phrases
      PhrasingPhrase.where(locale: @locale)
    end

    def keys_and_values_to_yml(keys_and_values, version_file_path)
      result = {}
      keys_and_values.each do |dot_key, value|
        h = result
        keys = dot_key.split(".")
        keys.each_with_index do |key, index|
          h[key] = {} unless h.has_key?(key)

          if index == keys.length - 1
            h[key] = value
          else
            h = h[key]
          end
        end
      end

      yaml_contents = YAML.dump(result)
      File.open(version_file_path, "w+") do |f|
        f.write(yaml_contents)
      end
    end

    def traverse(obj, keys = [], &block)
      case obj
      when Hash
        obj.each do |k,v|
          keys << k
          traverse(v, keys, &block)
          keys.pop
        end
      when Array
        obj.each { |v| traverse(v, keys, &block) }
      else
        yield keys, obj
      end
    end

  end
end
