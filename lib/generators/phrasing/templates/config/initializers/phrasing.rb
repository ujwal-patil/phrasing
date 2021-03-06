Phrasing.setup do |config|
  config.route = 'phrasing'

  # List all the model attributes you wish to edit with Phrasing, example:
  # config.whitelist = ["Post.title", "Post.description"]
  config.whitelist = []

  # You can whitelist all models, but it's not recommended.
  # Read here: https://github.com/infinum/phrasing#security
  config.allow_update_on_all_models_and_attributes = false

  # search_directory_path - Codebase Directory path where
  # script will look for keys are in use or not?
  config.search_directory_path = 'app'

  # locale_file_path - Where the root locales file are located
  config.locale_file_path = 'config/locales'

  # blacklisted_file_names - The keys generated by spacified file names will be ignored,
  # i.e. the keys are not supported for inline edit
  config.blacklisted_file_names = %w()

  # The keys starting with following will not support for inline edit
  config.blacklisted_keys_for_inline_edit = %w()

  #keep_recent_release_count - spcifying value 3, will keep recent 3 locale file versions
  config.keep_recent_release_count = 3

  # whitelisted_keys_section_for_remover - The keys starting with specified strings
  # will not considered as useless keys, remover script will keep such keys as it is
  config.whitelisted_keys_section_for_remover = %w(activerecord)

  # Enable meta editing
  config.editable_meta_enable = false

  # add your meta section key here <locale_name(en|fr)>.<root_meta_key>.<controller_name>.<action_name>.<meta_key>
  config.meta_section_root_key = 'meta'

  # While inline edit, you will see a previous text popover
  config.previous_text_popover = true

  # Add your site_title name here if you wants to enable dyanabmic brand site title
  config.branding_site_title = 'Scalefusion'
end