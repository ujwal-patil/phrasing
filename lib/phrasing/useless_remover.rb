module Phrasing
  class UselessRemover
    def initialize(locale)
      @locale = locale.to_s
      @detector = WhatLanguage.new(:all)
    end

    # Phrasing::UselessRemover.new(:fr).extract
    # This will extract the values which are not yet translated
    # This will usefull to get only keys and values where you need to work on
    # Phrasing::UselessRemover.new(:fr).extract this will create extracted.fr.yml
    # where all keys are not yet translated in french, you can translate it and merge it by import
    def extract
      _keys_and_values = {}
      pinwheel = %w{ | / - \\ }

      full_keys_and_values = load_locale_file
      puts "Checking #{full_keys_and_values.length} keys..."

      full_keys_and_values.each_with_index do |(key, value), index|
        percentage = ((index + 1).to_f / full_keys_and_values.length * 100).to_i
        print "\b" * 50, "Progress: #{percentage}% - #{index + 1}/#{full_keys_and_values.length} ", pinwheel.rotate!.first

        if non_english?(value)
          _keys_and_values[key] = value
        end
      end

      keys_and_values_to_yml(_keys_and_values, File.join(Phrasing.locale_file_path, "extracted.#{@locale}.yml"))
      puts 'Done.'
    end

    # Phrasing::UselessRemover.new(:fr).remove
    # This will remove all keys which are not in use, based on the lookup result in your specified Phrasing.search_directory_path
    # Also update the root.fr.yml file by removing useless keys
    def remove
      _keys_and_values = {}
      pinwheel = %w{ | / - \\ }

      full_keys_and_values = load_locale_file
      puts "Checking #{full_keys_and_values.length} keys..."

      full_keys_and_values.each_with_index do |(key, value), index|
        percentage = ((index + 1).to_f / full_keys_and_values.length * 100).to_i
        print "\b" * 50, "Progress: #{percentage}% - #{index + 1}/#{full_keys_and_values.length} ", pinwheel.rotate!.first

        if whitelisted?(key) || grep_result_exist?(key)
          _keys_and_values[key] = value
        end
      end

      keys_and_values_to_yml(_keys_and_values)
      puts 'Done.'
    end

    private

    def non_english?(value)
      !['english', ''].include?(@detector.language(value).to_s)
    end

    def whitelisted?(key)
      _key = key.gsub("#{@locale}.", "")

      (Phrasing.whitelisted_keys_section_for_remover + iterated_section_keys).any?{|m| _key.start_with?(m)}
    end

    def grep_result_exist?(key)
      _key = key.gsub("#{@locale}.", "")

      return true if `grep -ohr 't("#{_key}"' #{Phrasing.search_directory_path}`.present?
      return true if `grep -ohr "t('#{_key}'" #{Phrasing.search_directory_path}`.present?
      return true if `grep -ohr 't(:"#{_key}"' #{Phrasing.search_directory_path}`.present?
      return true if `grep -ohr "t(:'#{_key}'" #{Phrasing.search_directory_path}`.present?
      return true if `grep -ohr "t(:#{_key}" #{Phrasing.search_directory_path}`.present?
      return false
    end

    def iterated_section_keys
      return @iterated_section_keys unless @iterated_section_keys.blank?

      str_grep_by_method = ['keys', 'each'].map do |method|
        `grep -orh ".t([:a-zA-Z_.-'\\"]*).#{method}" app`
      end.join

      @iterated_section_keys = str_grep_by_method.scan(Regexp.union(/'[a-zA-Z_.-]*'/, /"[a-zA-Z_.-]*"/)).map{|m| m.gsub(/"|'/, '')}
    end

    def keys_and_values_to_yml(keys_and_values, file_path = nil)
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

      file_path = file_path || current_locale_file_path
      yaml_contents = YAML.dump(result)
      File.open(file_path, "w+") do |f|
        f.write(yaml_contents)
      end
    end

    def load_locale_file
      return {} unless File.exist?(current_locale_file_path)

      keys_and_values = {}
      traverse(YAML.load_file(current_locale_file_path)) do |keys, value|
        keys_and_values[keys * '.'] = value
      end

      keys_and_values
    end

    def current_locale_file_path
      @file ||= Dir[File.join(Phrasing.locale_file_path, "*root.#{@locale}.yml")].last
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
