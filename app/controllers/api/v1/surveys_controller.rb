class Api::V1::SurveysController < ApplicationController

  def trigger

    id = params["id"]
    @survey = Survey.find(id)
    @survey.calculate_winner
  end

  def index
    @surveys = Survey.all

    options = {
      include: [:choices, :responses]
    }
    render json: { surveys: SurveySerializer.new(@surveys, options)}

  end

  def create
    #params[:choices][0]["content"] => adzuki
    #byebug
    choices = []
    count = 0
    while count < params[:choices].count
      choices.push({content: params[:choices][count]["content"], winner: false})
      count += 1
    end
    


    @survey = Survey.new(survey_params)

    if @survey.save
      @choices = @survey.choices.build(choices)


      #@choices = @survey.choices.build([{content: params[:choices][0]["content"], winner: false}, {content: params[:choices][1]["content"], winner: false}, {content: params[:choices][2]["content"], winner: false}, {content: params[:choices][3]["content"], winner: false}])
      #byebug
      @choices.each {|choice|
        choice.save}
      #byebug
      options = {
        include: [:choices]
      }
      render json: SurveySerializer.new(@survey, options), status: :accepted
    else
      render json: { errors: @survey.errors.full_messages}, status: :unprocessable_entity
    end
  end

  private
    def survey_params
      params.require(:survey).permit(:name, :user_email, :threshold,  choices_attributes: [:content, :winner, :survey_id])
    end

end
