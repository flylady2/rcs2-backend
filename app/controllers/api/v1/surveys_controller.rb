class Api::V1::SurveysController < ApplicationController

  def trigger

    id = params["id"]
    @survey = Survey.find(id)
    @survey.collect_choice_rankings
  end

  def index
    @surveys = Survey.all

    options = {
      include: [:choices, :responses]
    }
    render json: { surveys: SurveySerializer.new(@surveys, options)}

  end

  def create


    choices = []
    count = 0
    while count < params[:choices].count
      choices.push({content: params[:choices][count]["content"], winner: false})
      count += 1
    end


    @survey = Survey.new(survey_params)

    if @survey.save
      @choices = @survey.choices.build(choices)

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



  def destroy
    @survey = Survey.find(params[:id])
    @survey.destroy
    render json: SurveySerializer.new(@survey), status: :accepted

  end

  private
    def survey_params
      params.require(:survey).permit(:name, :user_email, :threshold,  choices_attributes: [:content, :winner, :survey_id])
    end

end
