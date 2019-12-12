class PhrasingPhrase < ActiveRecord::Base

  validates_presence_of :key, :locale
  # validate :uniqueness_of_key_on_locale_scope, on: :create
  validates_uniqueness_of :key, scope: [:locale]

  has_many :versions, dependent: :destroy, class_name: 'PhrasingPhraseVersion'

  after_update :version_it

  scope :locale, ->(locale_code = 'en'){
    where(locale: locale_code)
  }

  def yml_value
    if Phrasing.branding_site_title.present?
      value.gsub(/#{Phrasing.branding_site_title}/, "%{site_title}")
      .gsub(/#{Phrasing.branding_site_title.downcase}/, "%{site_title_downcase}")
    else
      value
    end
  end

  def value=(val)
    if Phrasing.branding_site_title.present?
      val = val.gsub(/%{site_title}/, Phrasing.branding_site_title)
        .gsub(/%{site_title_downcase}/, Phrasing.branding_site_title.downcase)
    end

    super(val)
  end

  def self.find_phrase(key)
    where(key: key, locale: I18n.locale.to_s).first || search_i18n_and_create_phrase(key)
  end

  def self.fuzzy_search(search_term, locale, meta_term = nil)
    query = order(:key)
    query = query.where(locale: locale) if locale.present?
    if search_term.present?
      key_like   = PhrasingPhrase.arel_table[:key].matches("%#{search_term}%")
      value_like = PhrasingPhrase.arel_table[:value].matches("%#{search_term}%")
      query = query.where(key_like.or(value_like))
    end

    if meta_term.present?
      meta_like = PhrasingPhrase.arel_table[:key].matches("#{meta_term}%")
      query = query.where(meta_like)
    end

    query
  end

  private

    def self.search_i18n_and_create_phrase(key)
      begin
        RequestStore.store[:locale_keys_and_values] ||= load_locale_file
        value = RequestStore.store[:locale_keys_and_values]["#{I18n.locale}.#{key}"]

        raise I18n::MissingTranslationData.new(I18n.locale, key) if value.nil?

        create_phrase(key, value)
      rescue I18n::MissingTranslationData
        create_phrase(key)
      end
    end

    def self.create_phrase(key, value=nil)
      phrasing_phrase = PhrasingPhrase.new
      phrasing_phrase.locale = I18n.locale.to_s
      phrasing_phrase.key    = key.to_s
      phrasing_phrase.value  = value || key.to_s
      phrasing_phrase.save
      phrasing_phrase
    end

    def uniqueness_of_key_on_locale_scope
      if PhrasingPhrase.where(key: key, locale: locale).any?
        errors.add(:key, "Duplicate entry #{key} for locale #{locale}")
      end
    end

    def version_it
      PhrasingPhraseVersion.create_version(id, value_was) if value_was != value
    end

    def self.load_locale_file
      file_path = Dir[File.join(Phrasing.locale_file_path, "*root.#{I18n.locale}.yml")].last

      return {} unless File.exist?(file_path)

      keys_and_values = {}
      traverse(YAML.load_file(file_path)) do |keys, value|
        keys_and_values[keys * '.'] = value
      end

      keys_and_values
    end

    def self.traverse(obj, keys = [], &block)
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
