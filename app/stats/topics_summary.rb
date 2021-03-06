class TopicsSummary
  include TopicsQueries, SharedStatsMethods

  # TODO: Test whether one of these methods works noticeably faster.
  # attr_reader :sixth_stats, :final_stats
  attr_reader :stats

  def initialize(user, play_types)
    # @sixths = ActiveRecord::Base.connection
    #                             .select_all(topic_sixths_query(user)).to_hash
    # @finals = ActiveRecord::Base.connection
    #                             .select_all(topic_finals_query(user)).to_hash

    data = ActiveRecord::Base.connection
                             .select_all(topics_query(user, play_types))
                             .to_hash

    crunch_numbers(data)
    # crunch_numbers_each(@sixths, @finals)
  end

  private

  def crunch_numbers(data)
    @stats = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    data.each do |cat_hash|
      if cat_hash['sixth_type']
        add_sixth_to_stats(cat_hash)
      else
        add_final_to_stats(cat_hash)
      end
    end

    add_calculated_stats
  end

  # def crunch_numbers_each(sixths_data, final_data)
  #   @sixth_stats = Hash.new { |hash, key| hash[key] = Hash.new(0) }
  #   @final_stats = Hash.new { |hash, key| hash[key] = Hash.new(0) }

  #   sixths_data.each { |sixth| add_sixth_to_stats(sixth, @sixth_stats) }
  #   final_data.each { |final| add_final_to_stats(final, @final_stats) }

  #   add_efficiency(@sixth_stats)
  #   add_final_rate(@final_stats)
  # end

  def add_sixth_to_stats(cat_hash)
    topic_stats = @stats[cat_hash['topic']]
    topic_stats[:sixths_count] += 1

    trv = top_row_value(cat_hash)
    1.upto(5) do |row|
      add_clue_to_stats(topic_stats, cat_hash['result' + row.to_s], trv * row)
    end
  end

  def add_final_to_stats(final_hash)
    topic_stats = @stats[final_hash['topic']]
    topic_stats[:finals_count] += 1

    case final_hash['final_result'].to_i
    when 1 then topic_stats[:finals_wrong] += 1
    when 3 then topic_stats[:finals_right] += 1
    end
  end

  def add_calculated_stats
    @stats.each_value do |topic_hash|
      topic_hash[:efficiency] = quotient(topic_hash[:score],
                                         topic_hash[:possible_score])

      topic_hash[:dds] = topic_hash[:dd_right] + topic_hash[:dd_wrong]
    end
  end

  # def add_efficiency(stats)
  #   stats.each_value do |topic_hash|
  #     topic_hash[:efficiency] = quotient(topic_hash[:score],
  #                                        topic_hash[:possible_score])
  #   end
  # end

  # def add_final_rate(stats)
  #   stats.each_value do |topic_hash|
  #     topic_hash[:final_rate] = quotient(topic_hash[:finals_right],
  #                                        topic_hash[:finals_count])
  #   end
  # end

  def top_row_value(sixth_hash)
    if sixth_hash['sixth_type'] == 'RoundOneCategory'
      CURRENT_TOP_ROW_VALUES[0]
    else
      CURRENT_TOP_ROW_VALUES[1]
    end
  end
end
