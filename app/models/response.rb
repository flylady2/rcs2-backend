class Response < ApplicationRecord

  belongs_to :survey
  has_many :rankings, dependent: :destroy
  has_many :choices, through: :rankings

  validates :token, uniqueness: true

  accepts_nested_attributes_for :rankings




  def response_count
    @survey = self.survey

    number_of_responses = @survey.responses.count
    if number_of_responses >= @survey.threshold
      @survey.collect_choice_rankings
    end
  end




end
