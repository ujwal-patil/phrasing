module PhrasingInternalHelper


  #  meta_content(:og_type, :keywords)
  def meta_content(*meta_keys)
    meta_keys.each do |meta_key|
      if meta_keys.length > 1
        text = (find_key(meta_key) rescue nil)
        return text unless text.blank?
      else
        return find_key(meta_key)
      end
    end
  end

  def find_key(meta_key)
    begin
      if params[:page].present?
        I18n.t("#{Phrasing.meta_section_root_key}.#{controller_name}.#{action_name}.#{params[:page]}.#{meta_key}", raise: true)
      else
        I18n.t("#{Phrasing.meta_section_root_key}.#{controller_name}.#{action_name}.#{meta_key}", raise: true)
      end
    rescue I18n::MissingTranslationData => e
      if Rails.env.development?
        Rails.logger.error(ActiveSupport::LogSubscriber.new.send(:color, "Meta Missing : #{e.message}", :red))
      end

      I18n.t("#{Phrasing.meta_section_root_key}.#{meta_key}")
    end
  end

   # meta:
   #  title:
   #  description:
   #  keywords:
   #  #
   #  action_name:
   #    title:
   #    description:
   #    keywords:
   #    og_type:
   #    og_url:

end
