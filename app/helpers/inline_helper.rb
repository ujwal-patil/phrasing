module InlineHelper

  # Normal phrase
  # phrase("headline", url: www.infinum.co/yabadaba, inverse: true, scope: "models.errors")
  # Data model phrase
  # phrase(record, :title, inverse: true, class: phrase-record-title)
  def phrase(*args)
    if args[0].class.in? [String, Symbol]
      key, options = args[0].to_s, (args[1] || {})
      inline(phrasing_extract_record(key, options), :value, options, key)
    else
      record, attribute, options = args[0], args[1], args[2]
      inline(record, attribute, options || {}, key)
    end
  end

  def phrasing_include_tag
    render('phrasing/phrasing_initializer')
  end

  def edit_meta_path
    if request.path == '/'
      '/meta'
    elsif params[:locale].nil?
      "/meta#{request.path}"
    else
      lregex = Regexp.new(I18n.available_locales.excluding(:en).map{|m| "\/#{m}\/|\/#{m}"}.join('|'))
      request.path.sub(lregex, '/meta/')
    end
  end

  def t(key)
    if can_edit_phrases? && !blacklisted_file_keys.include?("#{I18n.locale}.#{key}") && !Phrasing.blacklisted_keys_for_inline_edit.any?{|m| key.start_with?(m)}
      phrase(key)
    else
      I18n.t(key)
    end
  end

  def blacklisted_file_keys
    @blacklisted_phrases_keys ||= Phrasing::Updator.new(I18n.locale).blacklisted_phrases_keys
  end

  def phrasing_preview_links(links)
    return "-" if links.blank?
    links.map.with_index(1) do |path, i|
      %Q( <a href="#{path}" target="_blank" style="color: blue;font-weight: 600;">Preview-#{i}</a> )
    end.join(', ').html_safe
  end

  private

  def inline(record, attribute, options = {}, key = nil)
    return uneditable_phrase(record, attribute) unless can_edit_phrases?

    klass  = 'phrasable'
    klass += ' inverse' if options[:inverse]
    klass += ' ' + options[:class] if options[:class]

    url = phrasing_polymorphic_url(record, attribute)
    phrase_html_id = "phrase-#{record.id}"

    tag_options = {class: klass, spellcheck: false, 'data-url' => url,  onclick: "resetPhrasableEvent(event)", id: phrase_html_id}
   
    # Add Previous Text popover
    if Phrasing.previous_text_popover
      add_previous_text_popover(key, tag_options)
    end

    # Add Preview Link
    update_preview_links(record, phrase_html_id)

    content_tag(:i, tag_options) do
      (record.send(attribute) || record.try(:key)).to_s.html_safe
    end
  end

  def add_previous_text_popover(key, tag_options)
    unless key.blank?
      locale_text = I18n.t(key, raise: true) rescue nil
      unless locale_text.nil?
        tag_options.merge!({'data-toggle' => "popover", 'data-content' => locale_text, title: "User View Previous Text"})
      end
    end
  end

  def update_preview_links(record, phrase_html_id)
    record.preview_links << "#{request.path}##{phrase_html_id}"
    record.preview_links.uniq!
    record.save
  end

  def phrasing_extract_record(key, options = {})
    key = options[:scope] ? "#{options[:scope]}.#{key}" : key
    PhrasingPhrase.find_phrase(key)
  end

  def uneditable_phrase(record, attribute)
    record.public_send(attribute).to_s.html_safe
  end

  def phrasing_polymorphic_url(record, attribute)
    phrasing_phrase_path(record.id, klass: record.class.to_s, attribute: attribute)
  end

end