class PhrasingPhrasesController < Phrasing.parent_controller.constantize

  layout 'phrasing'

  protect_from_forgery

  include PhrasingHelper

  before_action :authorize_editor

  def import_export
  end

  def help
  end

  def index
    params[:locale] ||= I18n.default_locale
    @phrasing_phrases = phrasing_phrases
    @locale_names = PhrasingPhrase.distinct.pluck(:locale)
  end

  def edit
    @phrasing_phrase = PhrasingPhrase.find(params[:id])
  end

  def update
    request.xhr? ? xhr_phrase_update : phrase_update
  end

  def download
    time = Time.now.strftime('%Y_%m_%d_%H_%M_%S')

    filename = "Scalefusion_locale_#{time}.#{params[:locale]}.yml"
    file = Phrasing::Serializer.export_yaml(PhrasingPhrase.fuzzy_search(params[:search], params[:locale]), filename)
    send_file file, filename: filename
  end

  def upload
    respond_to do |format|
      format.js do
        begin
          if authorize_upload_access?
            PhrasingUploadJob.perform_later(@temp_locale_path)
          else
            @message = "You can only upload #{accessible_edit_locales.map(&:to_s).join(', ')} .yml files"
          end
        rescue => e
          message = params[:file].nil? ? 'Please choose a file.' : 'Please upload a valid YAML file.'
          @message = "There was an error processing your upload! #{message}"
        end
      end
      
      format.html { redirect_to import_export_phrasing_phrases_path, notice: 'Wrong URL entered' }
    end    
  end

  def upload_status
    PhrasingPhrase.where(locale: params[:locale]).count
    render json: {progress: Phrasing.job_status_for('PhrasingUploadJobPercentage'), no_of_changes: Phrasing.job_status_for('PhrasingUploadJobChanges')}
  end

  def destroy
    phrasing_phrase = PhrasingPhrase.find(params[:id])
    phrasing_phrase.destroy
    redirect_to phrasing_phrases_path, notice: "#{phrasing_phrase.key} deleted!"
  end

  def request_go_live
    PhrasingJob.perform_later(params[:locale])
    head :ok
  end

  def go_live_status
    render json: {
      in_progress: Phrasing.job_status_for('phrasing_in_progress'), 
      progress: Phrasing.job_status_for('phrasing_in_progress_status'),
      removed_words: Phrasing.job_status_for('WordCounter:removed_words'),
      added_words: Phrasing.job_status_for('WordCounter:added_words')
    }
  end

  private

  def authorize_upload_access?
    @temp_locale_path = Rails.root.join('tmp/temp_locale.yml').to_s
    File.open(@temp_locale_path, "wb+") do |file|
      file.puts params["file"].tempfile.read
    end

    hash = YAML.load(File.new(@temp_locale_path))
    @being_upload = (accessible_edit_locales.map(&:to_s) & hash.keys)
    @being_upload == hash.keys
  end

  def authorize_editor
    redirect_to root_path unless can_edit_phrases?
  end

  def xhr_phrase_update
    klass, attribute = params[:klass], params[:attribute]

    return render status: 403, text: 'Phrase not whitelisted' unless Phrasing.whitelisted?(klass, attribute)

    record = klass.classify.constantize.find(params[:id])

    if record.update(attribute => params[:new_value])
      render json: record
    else
      render status: 403, json: record.error.full_messages
    end
  end

  def phrase_update
    phrase = PhrasingPhrase.find(params[:id])
    phrase.value = params[:phrasing_phrase][:value]
    phrase.save!

    redirect_to phrasing_phrases_path, notice: "#{phrase.key} updated!"
  end

  def phrasing_phrases
    PhrasingPhrase.fuzzy_search(params[:search], params[:locale]).page(params[:page]).per(params[:per_page] || 100)
  end

end