class Survey < ApplicationRecord


  has_many :choices, dependent: :destroy
  has_many :responses, dependent: :destroy
  has_many :rankings, through: :responses
  #not sure about this one:
  has_many :rankings, through: :choices

  accepts_nested_attributes_for :choices



  def calculate_winner
    survey = self
    if survey.choices.length > 1
      choice_rankings = []
      self.choices.each { |choice|
        choice_rankings.push(choice.rankings)}
      extracting_firsts(choice_rankings, survey)
    else
      last_man_standing(survey)
    end
  end

  def extracting_firsts(choice_rankings, survey)
    first_choice_rankings = []
    choice_rankings.each { |choice_ranking|
      first_choice_rankings.push(choice_ranking.where(value: 1))}
     test_for_majority(first_choice_rankings, choice_rankings, survey)
  end

  def test_for_majority(first_choice_rankings, choice_rankings, survey)
    winning_array = []
    first_choice_rankings.each { |first_choice_ranking|
    if first_choice_ranking.length > 0.5 * self.responses.count
      winning_array.push(first_choice_ranking[0])
    end}
    if winning_array.length == 0
      remove_least_popular_choice(first_choice_rankings, choice_rankings, survey)
    else
      declare_winner(winning_array, survey)
    end
  end

  def remove_least_popular_choice(first_choice_rankings, choice_rankings, survey)
    first_choice_rankings_lengths = []
    first_choice_rankings.each { |choice_ranking|
      first_choice_rankings_lengths.push(choice_ranking.length)}
    #byebug
    #code to deal with more than one having minimum value
    minimum_value = first_choice_rankings_lengths.min
    #old code (aas of 2.26.21)
  #  first_choice_rankings.each { |ranking|
  #    if ranking.length == 0
  #      identify_and_destroy_choice_with_no_first_choices(first_choice_rankings, survey)
  #    elsif
  #      ranking.length == minimum_value
  #      identify_and_destroy_choice_with_minimum_value_first_choices(ranking, survey)

    #  if ranking.length == minimum_value
    #    identify_and_destroy_choice_with_minimum_value_first_choices(first_choice_rankings, survey)
    #  end
    #  }
    #new code as of 2.26.21
    rankings_with_minimum_value_length = []
    first_choice_rankings.each { |ranking|
      if ranking.length == 0
        identify_and_destroy_choice_with_no_first_choices(first_choice_rankings, survey)
      elsif
        ranking.length == minimum_value
        rankings_with_minimum_value_length.push(ranking)
      end
    }
    #need to identify the choices
    choices_with_minimum_value_first_place_votes = []
    rankings_with_minimum_value_length.each { |ranking|
      choices_with_minimum_value_first_place_votes.push(Choice.find(ranking[0].choice_id))}
    #byebug
    count_number_of_fourth_place_votes(choices_with_minimum_value_first_place_votes)


  end

  def count_number_of_fourth_place_votes(choices)
    choice_rankings = []
    choices.each { |choice|
      choice_rankings.push(choice.rankings)}

    fourth_place_choice_rankings = []
    choice_rankings.each { |choice_ranking|
      fourth_place_choice_rankings.push(choice_ranking.where(value: 4))}

    fourth_place_choice_rankings_lengths = []
    fourth_place_choice_rankings.each { |choice_ranking|
      fourth_place_choice_rankings_lengths.push(choice_ranking.length)}

    maximum_value = fourth_place_choice_rankings_lengths.max
    index = fourth_place_choice_rankings_lengths.index(maximum_value)
    least_popular_choice = choices[index]
    remove_least_popular_choice_and_update_rankings(least_popular_choice)
    #byebug


  end

  def remove_least_popular_choice_and_update_rankings(choice)
    #byebug
    rankings_to_be_updated = choice.rankings.where(value: 1)

    #byebug
    ids_of_responses_to_be_updated = []
    rankings_to_be_updated.each {|ranking|
      ids_of_responses_to_be_updated.push(ranking.response_id)}
    #byebug
    choice.destroy
    create_params(ids_of_responses_to_be_updated)

  end

  #need to compare survey.choices with first_choice_rankings
  #process of elimination
  def identify_and_destroy_choice_with_no_first_choices(first_choice_rankings, survey)
    #byebug


    first_choice_ids = []
    choice_ids = []
    first_choice_rankings.each { |ranking|
      if ranking[0]
        first_choice_ids.push(ranking[0]["choice_id"])
      end}

    survey.choices.each { |choice|
        choice_ids.push(choice.id)}
    #byebug
    least_popular_choice_id = choice_ids - first_choice_ids
    #choice = Choice.find(least_popular_choice_id[0])
    least_popular_choice_id.each { |id|
      choice = Choice.find(id)
      survey_id = choice.survey_id
      choice.destroy
      @survey = Survey.find(survey_id)
      @survey.calculate_winner}


  end

  def identify_and_destroy_choice_with_minimum_value_first_choices(ranking, survey)
    #byebug
    #ids_of_responses_to_be_updated = []
    #rankings_for_least_popular_choice.each { |ranking|
    #  response_id = ranking.response_id
    #  ids_of_responses_to_be_updated.push(response_id)}

    #identify and delete choice and associated rankings
    #byebug
    ids_of_responses_to_be_updated = []
    ranking.each {|ranking|
      ids_of_responses_to_be_updated.push(ranking.response_id)}
    choice_id = ranking[0].choice_id
    @choice = Choice.find(choice_id)

    @choice.destroy
    create_params(ids_of_responses_to_be_updated, survey)

    #previous code
  #  ids_of_responses_to_be_updated.each { |id|
  #    response = Response.find(id)
  #    responses_to_be_updated.push(response)}
  #  create_params(responses_to_be_updated)
  end

  #create params for updating responses rankings
  def create_params(ids_of_responses_to_be_updated)
      #byebug
      responses_to_be_updated = []
      ids_of_responses_to_be_updated.each {|id|
        responses_to_be_updated.push(Response.find(id))}
      #byebug
      rankings_to_be_updated = []
      responses_to_be_updated.each { |response|
        response.rankings.each { |ranking|
          response_id = ranking.response_id
          response = Response.find(response_id)
          ranking_id = ranking.id
          ranking_value = ranking.value
          params = { rankings_attributes: [{id: "#{ranking_id}", value: "#{ranking_value - 1}"}]}
          response.update(params)}
        }
    response = responses_to_be_updated[0]
    survey_id = response.survey_id
    @survey = Survey.find(survey_id)
    @survey.calculate_winner
    end


  def declare_winner(winning_array, survey)
    #byebug
    choice_id = winning_array[0]["choice_id"]
    @choice = Choice.find(choice_id)
    @survey = survey
    choice = @choice

    @survey.send_message(choice)
    params = { winner: true}
    @choice.update(params)

  end

  def last_man_standing(survey)

    choice_id = survey.choices[0]["id"]
    @choice = Choice.find(choice_id)

    params = { winner: true}
    @choice.update(params)
    choice = @choice
    @survey = survey
    @survey.send_message(choice)
  end


  def send_message(choice)
    #byebug
    survey = self
    UserMailer.with(survey: survey, winning_choice: choice, user_email: survey.user_email).announce_winner.deliver_now
  end



    def response_attributes(response_params)
      response = Response.find(response_params)
      self.response = response if response.valid?
    end





end
