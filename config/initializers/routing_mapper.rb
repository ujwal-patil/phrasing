class ActionDispatch::Routing::Mapper

  def phrasing_configure
    if Phrasing.editable_meta_enable
      match '/meta/*path', to: 'phrasing_phrases#meta', via: :all
      get '/meta' => 'phrasing_phrases#meta'
      get  "/#{Phrasing.route}/download" => 'phrasing_phrases#download'

      scope "(:meta)", meta: /meta/ do
        yield
      end
    else
      yield
    end
  end
end