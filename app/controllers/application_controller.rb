class ApplicationController < ActionController::Base
  before_action :load_gallery_state  # session state load
  after_action  :save_gallery_state  # session state save

  helper_method :gallery_state

  private

  def load_gallery_state
    @gallery_state = Gallery::Environ::SessionState.load(session)
  end

  def save_gallery_state
    @gallery_state.persist!(session) if @gallery_state
  end

  def gallery_state
    @gallery_state
  end
end
