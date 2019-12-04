class PhrasingBaseJob < ApplicationJob

  def request_script
    add_status('phrasing_in_progress_status', 0)
    add_status('phrasing_in_progress', true)

  	command = lambda do |cmd, percentage|
  		puts "command=================#{cmd}, percentage: #{percentage}"

  		if cmd.start_with?('phrasing_do_update')
        updator_status = Phrasing::Updator.new(cmd.split(':').last).update_files
  			if updator_status == false
          add_status('phrasing_in_progress_status', 100)
          add_status('phrasing_in_progress', false)
          raise StandardError.new("Terminated as no change detected")
        else
          add_status('phrasing_in_progress_status', percentage)
        end
  		else
    		if system(cmd)
          add_status('phrasing_in_progress_status', percentage)
    		else
    			raise StandardError.new("command failed : #{cmd}")
    		end
        
        add_status('phrasing_in_progress', percentage != 100)
  		end
  	end

  	yield(command)
  rescue Exception => e
    add_status('phrasing_in_progress', false)

    Rails.logger.error("PhrasingBaseJob :: request_script :: Exception : #{e.message}")
  end

  def add_status(key, value)
  	$redis.with do |conn|
	    conn.lpush(key, value)
	    conn.ltrim(key, 0, 0)
	  end
  end

end

