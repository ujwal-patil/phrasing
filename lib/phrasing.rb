require 'phrasing'
require 'phrasing/serializer'
require 'phrasing/rails/engine'
require 'jquery-rails'
require 'haml'

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
end
