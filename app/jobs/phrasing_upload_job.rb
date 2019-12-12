class PhrasingUploadJob < ApplicationJob
	queue_as :default

  def perform(*args)
  	unless File.exist?(args.first)
  		Rails.logger.info("PhrasingUploadJob : no file exist : #{args.first}")
  		return 
  	end

  	file = File.new(args.first)
    number_of_changes = 0
    hash = YAML.load(file)

    hash.each do |locale, data|
    	flatten_hash = flatten_the_hash(data)
      flatten_hash.each_with_index do |(key, value), index|

        phrase = PhrasingPhrase.where(key: key, locale: locale).first || PhrasingPhrase.new(key: key, locale: locale)
        if phrase.value != value
          phrase.value = value
          number_of_changes += 1
          phrase.save
        end
	   
	      percentage = ((index + 1).to_f / flatten_hash.length * 100).to_i
	      in_progress_status!(percentage, number_of_changes)
      end
    end

    FileUtils.rm(args.first, force: true)
  end

  def in_progress_status!(percentage, number_of_changes)
  	$redis.with do |conn|
	    conn.lpush('PhrasingUploadJobPercentage', percentage)
	    conn.ltrim('PhrasingUploadJobPercentage', 0, 0)

	    conn.lpush('PhrasingUploadJobChanges', number_of_changes)
	    conn.ltrim('PhrasingUploadJobChanges', 0, 0)
	  end
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
end

