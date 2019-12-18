require 'sinatra/activerecord'
require './models/tree.rb'
require './models/user.rb'
require './models/branch.rb'
require 'distribution'

# BEGINNING OF CONSTANTS FOR TREE GROWING
# Trees stop growing after roughly 150 years

TREE_FACTOR_MIN = 500
TREE_FACTOR_MAX = 750
TREE_GROWTH_FAVOR_THRESHOLD = 1500
# when the tree growth favor threshold is reached, there should be a uniform
# chance of rolling anywhere from the min to max

# Model 2 for Tree Growth using cell growth using a logistic model
# P(t) = c/(1+ae^{-bt})
# where c = carrying capacity, a = scaling factor, b = growth factor/speed

LOG_MODEL_CARRYING_CAPACITY = 400 # times scale_base^generation, c value
# Should hit 80% of this height after around 30 years of life
LOG_MODEL_CARRYING_CAPACITY_SCALE_BASE = 0.6
LOG_MODEL_SCALE_FACTOR = 150 # a value, very subject to change
LOG_MODEL_GROWTH_FACTOR = 0.03 # b value, very subject to change

LENGTH_STD_DEV_FACTOR = 0.01
# To make every tree different, the height addition will vary in a normal
# distribution, with LENGTH_STD_DEV_FACTOR*{expected_length} as the deviation
# where {expected_length} is computed above using the logistic model

# Note that when a branch is young, it will favor average branch factors
# Vice versa holds: older branches will favor extreme branch factors
# By doing the above two steps, middle branches are likely to be longer and older.

# Here is our formula!
# Age of the parent branch = t
# the length proportion on which it will grow on its parent branch will be
# STD_DEV(mean = (TREE_FACTOR_MIN+TREE_FACTOR_MAX)/2, deviation = (TREE_FACTOR_MAX-mean)/(FAVOR_THRESHOLD-t)) when t < FAVOR_THRESHOLD
# UNIFORM_DISTRIBUTION(ANGLE_MIN, ANGLE_MAX) when t = FAVOR_THRESHOLD
# otherwise, pick left of mean, right of mean at random
# Then, from new ANGLE_MIN, ANGLE_MAX, pick number p from 0 to 1
# Then, our angle = x^(p*(log_x(ANG_MAX)-log_x(ANG_MIN)) + log_x(ANG_MIN)),
# where x = (e-1) * (FAVOR_THRESHOLD/(FAVOR_THRESHOLD-t)) + 1


TREE_GROWTH_ANGLE_MIN = 30 # In degrees
TREE_GROWTH_ANGLE_MAX = 60 # In degrees

TREE_DEV_ANGLE_MAX_BASE = 75 # In degrees, multiplied by (2-1/2^(gen-1))
# 0, 75, 75*(2-1/2), 75*(2 - 1/4), 75*(2-1/8), 75*(2-1/16), ...
# This value attempts to push MAX_BASE * 2

TREE_SPLIT_ANGLE_MIN = 10 # In degrees
TREE_SPLIT_ANGLE_MAX = 40 # In degrees
TREE_SPLIT_MUTUAL_ANGLE_MIN = 30 # In degrees

TREE_SPLIT_LENGTH_FACTOR_MAX = 0.4
TREE_SPLIT_AGE_MIN = 50 # multiplied by scale_base^generation
TREE_SPLIT_AGE_MIN_SCALE_BASE = 1.5
TREE_SPLIT_GROWTH_PROB_SCALING = 0.5
TREE_SPLIT_GROWTH_RATE = 100
# sum{P(split_age)} = 1-e^(-(x/GROWTH_RATE)^(TREE_SPLIT_GROWTH_PROB_SCALING)), x = min(0,split_age-split_age_min*scale_base^generation);
# Note when x = GROWTH_RATE, the probability will be 1-1/e, roughly 63% chance, always.
# When x = 2*GROWTH_RATE, the probability will be 1-1/sqrt{e} when PROB_SCALING = 0.5, roughly 76% chance.

TREE_GROWTH_AGE_MIN = 90
TREE_GROWTH_AGE_MIN_SCALE_BASE = 1.2


# END OF CONSTANTS FOR TREE GROWING

def comp_angle_max(gen)
  return 10*TREE_DEV_ANGLE_MAX_BASE*(2 - 0.5**(gen-1))
end

def pick_ratio(branch)

  factor_max = TREE_FACTOR_MAX
  factor_min = TREE_FACTOR_MIN

  # if branch.age == TREE_GROWTH_FAVOR_THRESHOLD
  #   random = rand(factor_max-factor_min+1)
  #   return (random.truncate(0) + factor_min)/1000.0
  # elsif branch.age < TREE_GROWTH_FAVOR_THRESHOLD
  #   normal_distrib = Distribution::Normal.rng((factor_min+factor_max)/2, ((TREE_GROWTH_FAVOR_THRESHOLD-branch.age)**(-0.1)) * (factor_max-factor_min)/3)
  #   return (((((normal_distrib.call).truncate(0) - factor_min)%(factor_max-factor_min) + (factor_max-factor_min)) % (factor_max-factor_min)) + factor_min)/1000.0
  # else
  #   p = rand(1)
  #   x = (Math::E - 1) * (TREE_GROWTH_FAVOR_THRESHOLD / (branch.age - TREE_GROWTH_FAVOR_THRESHOLD)) + 1
  #   factor = x**((p * (Math::log((factor_max + factor_min)/2) - Math::log(factor_min)) + Math::log(factor_min))/Math::log(x))
  #
  #   q = rand(1)
  #   if q > 0.5
  #     factor = factor_max+factor_min - factor
  #   end
  #
  #   return factor.truncate(0)/1000.0
  # end

  random = rand(factor_min..factor_max)
  return random/1000.0
end

def pick_angle(branch, is_left)

  angle_min = TREE_GROWTH_ANGLE_MIN*10
  angle_max = TREE_GROWTH_ANGLE_MAX*10

  if is_left == true
    if branch.sumdevx10 < 0
      angle_max = [TREE_GROWTH_ANGLE_MAX*10, comp_angle_max(branch.generation)+branch.sumdevx10].min
      angle_min = angle_max * TREE_GROWTH_ANGLE_MIN/TREE_GROWTH_ANGLE_MAX
    end
  else
    if branch.sumdevx10 > 0
      angle_max = [TREE_GROWTH_ANGLE_MAX*10, comp_angle_max(branch.generation)-branch.sumdevx10].min
      angle_min = angle_max * TREE_GROWTH_ANGLE_MIN/TREE_GROWTH_ANGLE_MAX
    end
  end

  random = rand(angle_max-angle_min+1)
  angle = random.truncate(0) + angle_min
  if is_left
    return -angle
  else
    return angle
  end
end

def comp_prob_true(split_age, age_min, prob_scaling, rate)
  return 1 - Math.exp(0 - (([0.0,split_age-age_min].max)/rate) ** prob_scaling)
end

def should_grow(split_age, age_min, prob_scaling, rate)
  prob = comp_prob_true(split_age,age_min,prob_scaling,rate) - comp_prob_true(split_age-1,age_min,prob_scaling,rate)
  rand_chance = rand(1)
  if rand_chance < prob
    return true
  end
  return false
end

def len_expect(time, gen)
  return LOG_MODEL_CARRYING_CAPACITY*(LOG_MODEL_CARRYING_CAPACITY_SCALE_BASE**gen)/(1+LOG_MODEL_SCALE_FACTOR*(Math::E**(-LOG_MODEL_GROWTH_FACTOR*time)))
end

def generate_random_line()
  String result = '"branch": '
  result = result + 4.times.map{Random.rand(101)}.to_s
  return result
end

def grow_tree(tree)
  tree.branch.each do |b|
    b.age = b.age + 1
    b.time_since_last_split = b.time_since_last_split + 1

    if b.has_split == false
      # Length Increase Mechanic
      newlen = len_expect(b.age,b.generation)
      curexp = len_expect(b.age-1, b.generation)
      curlen = b.length
      normal_distrib = Distribution::Normal.rng(newlen, newlen*LENGTH_STD_DEV_FACTOR)
      b.length = normal_distrib.call
      if b.branch_id == 0
        b.length = b.length + 25.0
      end
      # Outgrowth Mechanic
      if should_grow(b.time_since_last_split, TREE_GROWTH_AGE_MIN*(TREE_GROWTH_AGE_MIN_SCALE_BASE**b.generation), TREE_SPLIT_GROWTH_PROB_SCALING, TREE_SPLIT_GROWTH_RATE)
        b.time_since_last_split = 0
        is_left = true
        if b.num_children == 0
          rand_chance = rand(1)
          if rand_chance < 0.5
            is_left = false
          end
        else
          if b.num_children < 0
            is_left = false
          end
        end

        if is_left == true
          b.num_children = b.num_children-1
        else
          b.num_children = b.num_children+1
        end
        newangle = pick_angle(b,is_left)
        newratio = pick_ratio(b)

        tree.last_branch_id = tree.last_branch_id+1
        tree.branch.create(branch_id: tree.last_branch_id, age: 0, parent_id: b.branch_id, anglex10: newangle, sumdevx10: b.sumdevx10 + newangle, length: 2.0, generation: b.generation+1, factor: newratio)
      end

      # Split Mechanic to be implemented here

      b.save
    end
  end
end
