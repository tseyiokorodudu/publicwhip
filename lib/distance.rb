class Distance
  # What this means is that 5 absent votes is as important as one aye or no vote
  ABSENT_FACTOR = 5

  STRONG_FACTOR = 5

  attr_reader :same, :samestrong, :differ, :differstrong, :absent, :absentstrong

  def initialize(same, samestrong, differ, differstrong, absent, absentstrong)
    @same, @samestrong, @differ, @differstrong, @absent, @absentstrong =
      same, samestrong, differ, differstrong, absent, absentstrong
  end

  def distance
    1 - agreement
  end

  # Points system is picked to ensure it has the properties we want and that the points
  # are the smallest they can be while still all being integers
  def points
    {
      same:         2 * ABSENT_FACTOR,
      differ:       0,
      absent:       1,
      samestrong:   2 * STRONG_FACTOR * ABSENT_FACTOR,
      differstrong: 0,
      absentstrong: 1 * STRONG_FACTOR * ABSENT_FACTOR
    }
  end

  def possible_points
    {
      same:         2 * ABSENT_FACTOR,
      differ:       2 * ABSENT_FACTOR,
      absent:       2,
      samestrong:   2 * STRONG_FACTOR * ABSENT_FACTOR,
      differstrong: 2 * STRONG_FACTOR * ABSENT_FACTOR,
      absentstrong: 2 * STRONG_FACTOR * ABSENT_FACTOR
    }
  end

  def no_votes
    {
      same: same,
      differ: differ,
      absent: absent,
      samestrong: samestrong,
      differstrong: differstrong,
      absentstrong: absentstrong
    }
  end

  def attributes
    no_votes.keys
  end

  def votes_points(a)
    no_votes[a] * points[a]
  end

  def possible_votes_points(a)
    no_votes[a] * possible_points[a]
  end

  def total_points
    attributes.sum {|a| votes_points(a) }
  end

  def possible_total_points
    attributes.sum {|a| possible_votes_points(a) }
  end

  def agreement
    if possible_total_points > 0
      total_points.to_f / possible_total_points
    else
      2.0
    end
  end

  def self.distance_a(same, diff, absent)
    Distance.new(same, 0, diff, 0, absent, 0).distance
  end

  def self.distance_b(same, diff)
    distance_a(same, diff, 0)
  end
end