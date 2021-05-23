class Api::V1::ChoicesController < ApplicationController



private
  def choice_params
    params.require(:choice).permit(:content, :winner, :survey_id)
  end

end
