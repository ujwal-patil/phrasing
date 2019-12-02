namespace :phrasing do
  desc "Update the translations for given locale"
  task :update, [:locale]  => :environment  do |t, args|
    Phrasing::Updator.new(args.locale).update_files
    puts "\n\e[32m Locales file updated successfully for #{args.locale}. \e[0m"
  end

  desc "Remove the useless keys for given locale"
  task :remove, [:locale]  => :environment  do |t, args|
    Phrasing::UselessRemover.new(args.locale).remove
    puts "\n\e[32m Locales file updated successfully for #{args.locale}. \e[0m"
  end

end
