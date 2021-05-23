class Survey < ApplicationRecord


  has_many :choices, dependent: :destroy
  has_many :responses, dependent: :destroy
  has_many :rankings, through: :responses
  has_many :rankings, through: :choices
  validates :name, uniqueness: true
  accepts_nested_attributes_for :choices

  def collect_choice_rankings


    #if there is more than one choice
    if self.choices.length > 1
      choice_rankings = []
      self.choices.each { |choice|
        choice_rankings.push(choice.rankings)}
      self.extract_firsts(choice_rankings)
    else
      #if only one choice remains
      choice_id = self.choices[0]["id"]
      self.declare_winner(choice_id)
    end
  end

  def extract_firsts(choice_rankings)
    first_choice_rankings = []
    choice_rankings.each { |choice_ranking|
      first_choice_rankings.push(choice_ranking.where(value: 1))}

    self.test_for_majority(first_choice_rankings)
  end

  def test_for_majority(first_choice_rankings)
    winning_array = []
    first_choice_rankings.each { |first_choice_ranking|
      if first_choice_ranking.length > 0.5 * self.responses.count
        winning_array.push(first_choice_ranking[0])
      end
    }
    if winning_array.length == 0
      self.identify_choices_with_first_place_votes(first_choice_rankings)
    else
      choice_id = winning_array[0]["choice_id"]
      self.declare_winner(choice_id)
    end
  end

  def identify_choices_with_first_place_votes(first_choice_rankings)


    choices_with_first_place_votes = []
    first_choice_rankings.each { |ranking|
      if ranking.count != 0
        choices_with_first_place_votes.push(ranking)
      end
    }

    self.identify_and_destroy_choices_with_no_first_place_votes(choices_with_first_place_votes)

    self.identify_choices_with_fewest_first_place_votes(choices_with_first_place_votes)

  end

  def identify_choices_with_fewest_first_place_votes(choices_with_first_place_votes)

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

      self.calculate_scores(choices_with_minimum_value_first_place_votes)
    else
      choice = Choice.find(rankings_with_minimum_value_length[0][0].choice_id)
      destroy_choice(choice)

    end
  end

  def calculate_scores(choices)

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

    destroy_choice(choice_to_be_deleted)

  end

  def destroy_choice(choice)

    rankings_to_be_updated = choice.rankings.where(value: 1)

    ids_of_responses_to_be_updated = []
    rankings_to_be_updated.each {|ranking|
      ids_of_responses_to_be_updated.push(ranking.response_id)}

    choice.destroy
    update_responses(ids_of_responses_to_be_updated)

  end

  #need to compare survey.choices with first_choice_rankings
  #process of elimination
  def identify_and_destroy_choices_with_no_first_place_votes(choices_with_first_place_votes)

    first_choice_ids = []
    choice_ids = []
    #first_choice_rankings only have choices with first choices
    choices_with_first_place_votes.each { |ranking|
      if ranking[0]
        #extracting choice_id
        first_choice_ids.push(ranking[0]["choice_id"])
      end}

    self.choices.each { |choice|
        choice_ids.push(choice.id)}

    #remove choices with first place votes
    choices_with_no_first_place_votes_ids = choice_ids - first_choice_ids
    #
    choices_with_no_first_place_votes_ids.each { |id|
      choice = Choice.find(id)

      choice.destroy

    }
  end


  def update_responses(ids_of_responses_to_be_updated)

      responses_to_be_updated = []
      ids_of_responses_to_be_updated.each {|id|
        responses_to_be_updated.push(Response.find(id))}

      #rankings_to_be_updated = []
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


  def declare_winner(choice_id)

    @choice = Choice.find(choice_id)
    params = { winner: true}
    @choice.update(params)
    #@survey = survey
    choice = @choice
    self.send_message(choice)

  end

  def send_message(choice)

    UserMailer.with(survey: self, winning_choice: choice, user_email: self.user_email).announce_winner.deliver_now
  end



end
