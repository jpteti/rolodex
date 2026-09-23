class SessionTerminator < ApplicationService
  def terminate_session(session)
    session.destroy!
    Result.new(terminated: true, session:)
  end
  
  private
  
  class Result < Literal::Object
    prop :terminated, _Boolean, default: :false
    prop :session, _Nilable(Session), reader: :public
    
    def terminated? = @terminated
  end
end