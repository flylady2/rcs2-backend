class UserMailer < ApplicationMailer

  def announce_winner
    @choice = params[:winning_choice]
    @survey = params[:survey]
    user_email = params[:user_email]
    #byebug
    mail(to: user_email, subject: 'Winning Choice')

  end

  def invite_response
  #byebug
    @survey_name = params[:survey_name]
    @respondent_email = params[:respondent_email]
    @response_link = params[:response_link]
    @token = params[:token]
    mail(to: @respondent_email, subject: "Survey Response Needed")
  end

end
