class Api::V1::ResponsesController < ApplicationController




  def emails

    token = encrypt(params[:email])
    count = 0
    while count < params["_json"].count
      token = encrypt(params["_json"][count]["email"])
      UserMailer.with(survey_name: params["_json"][count]["survey_name"], respondent_email: params["_json"][count]["email"], response_link: params["_json"][count]["response_link"], token: token).invite_response.deliver_now
      count += 1
    end
  end

  def encrypt(email)
    len = ActiveSupport::MessageEncryptor.key_len
    salt = rand(9999999999).to_s.center(32, rand(9).to_s)
    key = ActiveSupport::KeyGenerator.new('password').generate_key(salt, len)
    crypt = ActiveSupport::MessageEncryptor.new(key)
    encrypted_email = crypt.encrypt_and_sign(email)
    token= "#{salt}$$#{encrypted_email}"




  end

  def decrypt(token)

    salt2, data = token.split("$$")

    len = ActiveSupport::MessageEncryptor.key_len
    key2 = ActiveSupport::KeyGenerator.new('password').generate_key(salt2, len)
    crypt2 = ActiveSupport::MessageEncryptor.new(key2)

    email = crypt2.decrypt_and_verify(data)
  end



  def index
    @responses = Response.all
    options = {
      include: [:choices, :rankings]
    }
    render json: { responses: ResponseSerializer.new(@responses, options)}
    #byebug
  end

  def create

    email = decrypt(params[:token])
    if params[:survey_id] && @survey = Survey.find_by_id(params[:survey_id].to_i)


      len = @survey.choices.count
      rankings = []
      count = 1
      while count <= len
        rankings.push({choice_id: params["rankedChoice#{count}"], value: count})
        count += 1
      end
    end
    if email == params[:respondent_email] && params[:survey_id] && @survey = Survey.find_by_id(params[:survey_id].to_i)#nested uner responses
      @response = @survey.responses.new(response_params)

    end
    @response.save

    if @response
      @rankings = @response.rankings.build(rankings)

      #([{value: params["ranking1"].to_i, choice_id: params["ranking1_choiceId"].to_i}, {value: params["ranking2"].to_i, choice_id: params["ranking2_choiceId"].to_i}, {value: params["ranking3"].to_i, choice_id: params["ranking3_choiceId"].to_i}, {value: params["ranking4"].to_i, choice_id: params["ranking4_choiceId"].to_i}])


      @rankings.each {|ranking|
        ranking.save}
      @response.response_count
      #byebug
      options = {
        include: [:rankings]
      }

      render json: ResponseSerializer.new(@response, options), status: :accepted

    else
      render json: { errors: @response.errors.full_messages}, status: :unprocessable_entity
    end



  end

  def update

  end


private

  def response_params
    params.require(:response).permit(:token, :survey_id, rankings_attributes: [:value, :response_id, :choice_id])
  end
end
