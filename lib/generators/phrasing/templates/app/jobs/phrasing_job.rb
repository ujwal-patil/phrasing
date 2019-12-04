class PhrasingJob < PhrasingBaseJob
  queue_as :default

  def perform(*args)
    request_script do |command|
      # command["<First Terminal command>", progress_percentage]
      # .
      # command["<Second Terminal command>", progress_percentage]
      # .
      
      command["phrasing_do_update:#{args.first}", 100]

      # .
      # .
      # command["<Last Terminal command>", 100]

      # Pull latest code
      # Example: command["git pull origin #{ENV['GIT_LOCALE_BRANCH']}", 100]
      # The command will be anything which run on terminal
    end
  end

  # You can use this message as commit message
  def commit_message(locale)
    added_words = Phrasing.job_status_for('WordCounter:added_words')
    removed_words = Phrasing.job_status_for('WordCounter:removed_words')

    "VERSION UPGRADE(#{locale}.yml), INFO: Added Words: #{added_words}, Removed Words: #{removed_words}"
  end
end
