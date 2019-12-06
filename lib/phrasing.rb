require 'phrasing'
require 'phrasing/serializer'
require 'phrasing/rails/engine'
require 'jquery-rails'
require 'haml'

require 'phrasing/word_counter'
require 'phrasing/updator'
require 'phrasing/useless_remover'


module Phrasing
  mattr_accessor :allow_update_on_all_models_and_attributes
  @@allow_update_on_all_models_and_attributes = false

  mattr_accessor :route
  @@route = 'phrasing'

  mattr_accessor :parent_controller
  @@parent_controller = "ApplicationController"

  mattr_accessor :previous_text_popover
  @@previous_text_popover = true

  mattr_accessor :overriden_style
  @@overriden_style = 'phrasing_engine_overidden'

  mattr_accessor :locale_file_directory

  mattr_accessor :search_directory_path
  @@search_directory_path = 'app'

  mattr_accessor :locale_file_path
  @@locale_file_path = 'config/locales'

  mattr_accessor :blacklisted_file_names
  @@blacklisted_file_names = %w()

  mattr_accessor :blacklisted_keys_for_inline_edit
  @@blacklisted_keys_for_inline_edit = %w()

  mattr_accessor :keep_recent_release_count
  @@keep_recent_release_count = 3

  mattr_accessor :whitelisted_keys_section_for_remover
  @@whitelisted_keys_section_for_remover = %w()

  mattr_accessor :editable_meta_enable
  @@editable_meta_enable = true

  mattr_accessor :meta_section_root_key
  @@meta_section_root_key = 'meta'

  def self.setup
    yield self
  end

  WHITELIST = "PhrasingPhrase.value"

  def self.whitelist
    if defined? @@whitelist
      @@whitelist + [WHITELIST]
    else
      [WHITELIST]
    end
  end

  def self.whitelist=(whitelist)
    @@whitelist = whitelist
  end

  def self.whitelisted?(klass, attribute)
    allow_update_on_all_models_and_attributes == true || whitelist.include?("#{klass}.#{attribute}")
  end

  def self.job_status_for(key)
    redis_with_try([]) do
      $redis.with {|conn| conn.lrange(key, 0 , 0)}
    end.first
  end

  def self.redis_with_try(default_val = nil, &block)
    yield
  rescue Exception => e
    Rails.logger.error("redis_with_try :: Exception : #{e.message}")
    return default_val
  end
end
