class PhrasingGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def create_initializer_file
    initializer_location = "config/initializers/phrasing.rb"
    copy_file initializer_location, initializer_location
  end

  def create_helper_file
    helper_location = "app/helpers/phrasing_helper.rb"
    copy_file helper_location, helper_location
  end

  def create_job_file
    job_location = "app/jobs/phrasing_job.rb"
    copy_file job_location, job_location
  end

  def create_migrations
    phrasing_phrase_migration = "db/migrate/create_phrasing_phrases.rb"
    migration_template phrasing_phrase_migration, phrasing_phrase_migration
    phrase_versions_migration = "db/migrate/create_phrasing_phrase_versions.rb"
    migration_template phrase_versions_migration, phrase_versions_migration
  end

  def add_methods_to_class
    inject_into_class "app/controllers/application_controller.rb", ApplicationController do
      <<-'RUBY'
  helper_method :can_edit_phrases?, :accessible_edit_locales

  def can_edit_phrases?
  # Example current_user.has_edit_access?
  # Return boolean if user can access current locale edit mode
  end

  def accessible_edit_locales
  # current_user.editable_locales
  # Provide locales array which are accessible for edit mode
  end
      RUBY
    end
  end

  def self.next_migration_number(path)
    sleep 1 # migration numbers should differentiate
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def migration_version
    "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]" if rails_major_version >= 5
  end

  def rails_major_version
    Rails.version.first.to_i
  end
end
