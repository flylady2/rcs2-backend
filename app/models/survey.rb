class Survey < ApplicationRecord


  has_many :choices, dependent: :destroy
  has_many :responses, dependent: :destroy
  has_many :rankings, through: :responses
  has_many :rankings, through: :choices

  accepts_nested_attributes_for :choices

  def collect_choice_rankings
    survey = self

    #if there are more than one choice
    if survey.choices.length > 1
      choice_rankings = []
      survey.choices.each { |choice|
        choice_rankings.push(choice.rankings)}
      extracting_firsts(choice_rankings, survey)
    else
      #if only one choice remains
      choice_id = survey.choices[0]["id"]
      declare_winner(choice_id, survey)
    end
  end

  def extracting_firsts(choice_rankings, survey)
    first_choice_rankings = []
    choice_rankings.each { |choice_ranking|
      first_choice_rankings.push(choice_ranking.where(value: 1))}

     test_for_majority(first_choice_rankings, survey)
  end

  def test_for_majority(first_choice_rankings, survey)
    winning_array = []
    first_choice_rankings.each { |first_choice_ranking|
      if first_choice_ranking.length > 0.5 * self.responses.count
        winning_array.push(first_choice_ranking[0])
      end
    }
    if winning_array.length == 0
      identify_choices_with_first_place_votes(first_choice_rankings, survey)
    else
      choice_id = winning_array[0]["choice_id"]
      declare_winner(choice_id, survey)
    end
  end

  def identify_choices_with_first_place_votes(first_choice_rankings, survey)


    choices_with_first_place_votes = []
    first_choice_rankings.each { |ranking|
      if ranking.count != 0
        choices_with_first_place_votes.push(ranking)
      end
    }

  #  if choices_with_no_first_place_votes.length == 0
  #    identify_choices_with_fewest_first_place_votes(first_choice_rankings, survey)
    destroy_choice_with_no_first_choices(choices_with_first_place_votes, survey)
  #  end
    identify_choices_with_fewest_first_place_votes(choices_with_first_place_votes, survey)

  end

  def identify_choices_with_fewest_first_place_votes(choices_with_first_place_votes, survey)

    first_choice_rankings_lengths = []
    choices_with_first_place_votes.each { |choice_ranking|
      first_choice_rankings_lengths.push(choice_ranking.length)}

    rankings_with_minimum_value_length = []

    minimum_value = first_choice_rankings_lengths.min

    choices_with_first_place_votes.each { |ranking|
      if ranking.length == minimum_value
        rankings_with_minimum_value_length.push(ranking)
      end
    }

    if rankings_with_minimum_value_length.count > 1
      #need to identify the choices
      choices_with_minimum_value_first_place_votes = []
      rankings_with_minimum_value_length.each { |ranking|
        choices_with_minimum_value_first_place_votes.push(Choice.find(ranking[0].choice_id))}

      calculate_scores(choices_with_minimum_value_first_place_votes, survey)
    else
      choice = Choice.find(rankings_with_minimum_value_length[0][0].choice_id)
      remove_least_popular_choice_and_update_rankings(choice)

    end


  end

  def calculate_scores(choices, survey)



    choice_rankings = []
    choices.each { |choice|
      choice_rankings.push(choice.rankings)}


    ranking_values = choice_rankings.map {|choice_ranking|
      choice_ranking.map {|ranking|
        ranking.value}}

    summed_values = ranking_values.map {|values|
      values.sum}

    highest_score = summed_values.max

    position = summed_values.index(highest_score)

    choice_to_be_deleted = choices[position]

    remove_least_popular_choice_and_update_rankings(choice_to_be_deleted)

  #  last_place = survey.choices.count

  #  fourth_place_choice_rankings = []
  #  choice_rankings.each { |choice_ranking|
  #    fourth_place_choice_rankings.push(choice_ranking.where(value: #last_place))}

    #fourth_place_choice_rankings_lengths = []
  #  fourth_place_choice_rankings.each { |choice_ranking|
    #  fourth_place_choice_rankings_lengths.push(choice_ranking.length)}

  #  maximum_value = fourth_place_choice_rankings_lengths.max
  #  index = fourth_place_choice_rankings_lengths.index(maximum_value)
  #  least_popular_choice = choices[index]
    #remove_least_popular_choice_and_update_rankings(least_popular_choice)
    #byebug


  end

  def remove_least_popular_choice_and_update_rankings(choice)
    #byebug
    rankings_to_be_updated = choice.rankings.where(value: 1)

    #byebug
    ids_of_responses_to_be_updated = []
    rankings_to_be_updated.each {|ranking|
      ids_of_responses_to_be_updated.push(ranking.response_id)}

    choice.destroy
    create_params(ids_of_responses_to_be_updated)

  end

  #need to compare survey.choices with first_choice_rankings
  #process of elimination
  def destroy_choice_with_no_first_choices(choices_with_first_place_votes, survey)



    first_choice_ids = []
    choice_ids = []
    #first_choice_rankings only have choices with first choices
    choices_with_first_place_votes.each { |ranking|
      if ranking[0]
        #extracting choid_id
        first_choice_ids.push(ranking[0]["choice_id"])
      end}

    survey.choices.each { |choice|
        choice_ids.push(choice.id)}

    #remove choices with first place votes
    choices_with_no_first_place_votes_ids = choice_ids - first_choice_ids
    #choice = Choice.find(least_popular_choice_id[0])
    choices_with_no_first_place_votes_ids.each { |id|
      choice = Choice.find(id)
      survey_id = choice.survey_id
      choice.destroy
      #@survey = Survey.find(survey_id)
      #@survey.calculate_winner
    }


  end

  #def identify_and_destroy_choice_with_minimum_value_first_choices(ranking, survey)
    #byebug
    #ids_of_responses_to_be_updated = []
    #rankings_for_least_popular_choice.each { |ranking|
    #  response_id = ranking.response_id
    #  ids_of_responses_to_be_updated.push(response_id)}

    #identify and delete choice and associated rankings
    #byebug
  #  ids_of_responses_to_be_updated = []
  #  ranking.each {|ranking|
#      ids_of_responses_to_be_updated.push(ranking.response_id)}
#    choice_id = ranking[0].choice_id
#    @choice = Choice.find(choice_id)

#    @choice.destroy
#    create_params(ids_of_responses_to_be_updated, survey)

    #previous code
  #  ids_of_responses_to_be_updated.each { |id|
  #    response = Response.find(id)
  #    responses_to_be_updated.push(response)}
  #  create_params(responses_to_be_updated)
#  end

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
    @survey.collect_choice_rankings
  end


  def declare_winner(choice_id, survey)
    #byebug
    #choice_id = winning_array[0]["choice_id"]
    @choice = Choice.find(choice_id)
    params = { winner: true}
    @choice.update(params)
    @survey = survey
    choice = @choice
    @survey.send_message(choice)

  end

#  def last_man_standing(survey)

#    choice_id = survey.choices[0]["id"]
#    @choice = Choice.find(choice_id)


#    params = { winner: true}
#    @choice.update(params)
#    choice = @choice
#    @survey = survey
#    @survey.send_message(choice)
#  end


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
