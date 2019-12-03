class PhrasingBaseJob < ApplicationJob

  def request_script
  	command = lambda do |cmd, percentage|
  		puts "command=================#{cmd}, percentage: #{percentage}"

  		cmd_status = if cmd.start_with?('phrasing_do_update')
  			Phrasing::Updator.new(cmd.split(':').last).update_files rescue false
  		else
  			system(cmd)
  		end

  		if cmd_status
  			in_progress_status!(percentage) 
  		else
  			raise StandardError.new("command failed : #{cmd}")
  		end
  		
  		in_progress!(percentage != 100)
  	end

  	yield(command)
  rescue Exception => e
  	in_progress!(false)
    Rails.logger.error("PhrasingBaseJob :: request_script :: Exception : #{e.message}")
  end

  def in_progress!(status)
  	$redis.with do |conn|
	    conn.lpush('phrasing_in_progress', status)
	    conn.ltrim('phrasing_in_progress', 0, 0)
	  end
  end

  def in_progress_status!(percentage)
  	$redis.with do |conn|
	    conn.lpush('phrasing_in_progress_status', percentage)
	    conn.ltrim('phrasing_in_progress_status', 0, 0)
	  end
  end

end

