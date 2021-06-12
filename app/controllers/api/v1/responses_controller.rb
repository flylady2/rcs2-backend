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
    #new code to generate salt
    salt = ""
    prng = Random.new(1234)
    count = 1
    while count < 33
      number = prng.rand(9)
      salt.concat(number.to_s)
      count += 1
    end
    #salt = rand(9999999999).to_s.center(32, rand(9).to_s)
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
    if email == params[:respondent_email] && params[:survey_id] && @survey = Survey.find_by_id(params[:survey_id].to_i)

      @response = @survey.responses.new(response_params)

    end
    @response.save

    if @response
      @rankings = @response.rankings.build(rankings)

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



private

  def response_params
    params.require(:response).permit(:token, :survey_id, rankings_attributes: [:value, :response_id, :choice_id])
  end
end
