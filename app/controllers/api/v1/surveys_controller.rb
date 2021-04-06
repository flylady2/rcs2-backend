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
    
    @survey = Survey.new(survey_params)

    if @survey.save

      @choices = @survey.choices.build([{content: params["choiceAContent"], winner: params["choiceAWinnerValue"]}, {content: params["choiceBContent"], winner: params["choiceBWinnerValue"]}, {content: params["choiceCContent"], winner: params["choiceCWinnerValue"]}, {content: params["choiceDContent"], winner: params["choiceDWinnerValue"]}])
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
