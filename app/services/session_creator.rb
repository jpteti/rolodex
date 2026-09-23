class SessionCreator < ApplicationService
  def create_session(user:, request:)
    session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
    Result.new(created: true, session:) 
  end
  
  private
  
  class Result < Literal::Object
    prop :created, _Boolean, default: :false
    prop :session, _Nilable(Session), reader: :public
    
    def created? = @created
  end
end