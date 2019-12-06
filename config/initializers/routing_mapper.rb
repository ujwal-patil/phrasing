class ActionDispatch::Routing::Mapper

  def phrasing_configure
    if Phrasing.editable_meta_enable
      match '/meta/*path', to: 'phrasing_phrases#meta', via: :all

      scope "(:meta)" do
        yield
      end
    else
      yield
    end
  end
end