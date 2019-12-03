
  def can_edit_phrases?
    return @has_edit_access unless @has_edit_access.nil?
    @has_edit_access = !!(current_user && current_user.has_edit_access?)
  end

  def accessible_edit_locales
    current_user.present? ? current_user.editable_locales.map(&:to_s) : []
  end

  def available_locales
    if accessible_edit_locales.blank?
      I18n.available_locales.map(&:to_s)
    else
      I18n.available_locales.map(&:to_s) & accessible_edit_locales
    end
  end