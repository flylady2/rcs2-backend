# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  def announce_winner
    UserMailer.with(survey: Survey.first, choice: Choice.first, user_email: Survey.first.user_email).announce_winner
  end


end
#(survey: Survey.first, choice: Choice.first, user_email: Survey.first.user_email)
