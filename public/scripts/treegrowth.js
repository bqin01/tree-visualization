// BEGINNING OF CONSTANTS FOR TREE GROWING
// Trees stop growing after roughly 150 years

const TREE_FACTOR_MIN = 500;
const TREE_FACTOR_MAX = 750;
const TREE_GROWTH_FAVOR_THRESHOLD = 1500;
// when the tree growth favor threshold is reached, there should be a uniform
// chance of rolling anywhere from the min to max

// Model 2 for Tree Growth using cell growth using a logistic model
// P(t) = c/(1+ae^{-bt})
// where c = carrying capacity, a = scaling factor, b = growth factor/speed
// ALWAYS ENSURE
// Starting length = c/(1+a)

const LOG_MODEL_CARRYING_CAPACITY = 400; // times scale_base^generation, c value
// Should hit 80% of this height after around 30 years of life
const LOG_MODEL_CARRYING_CAPACITY_SCALE_BASE = 0.6;
const LOG_MODEL_SCALE_FACTOR = 79; // a value, very subject to change
const LOG_MODEL_GROWTH_FACTOR = 0.03; // b value, very subject to change

const LENGTH_STD_DEV_FACTOR = 0.02;
// To make every tree different, the height addition will vary in a normal
// distribution, with LENGTH_STD_DEV_FACTOR*{expected_length} as the deviation
// where {expected_length} is computed above using the logistic model

// Note that when a branch is young, it will favor average branch factors
// Vice versa holds: older branches will favor extreme branch factors
// By doing the above two steps, middle branches are likely to be longer and older.

// Here is our formula!
// Age of the parent branch = t
// the length proportion on which it will grow on its parent branch will be
// STD_DEV(mean = (TREE_FACTOR_MIN+TREE_FACTOR_MAX)/2, deviation = (TREE_FACTOR_MAX-mean)/(FAVOR_THRESHOLD-t)) when t < FAVOR_THRESHOLD
// UNIFORM_DISTRIBUTION(ANGLE_MIN, ANGLE_MAX) when t = FAVOR_THRESHOLD
// otherwise, pick left of mean, right of mean at random
// Then, from new ANGLE_MIN, ANGLE_MAX, pick number p from 0 to 1
// Then, our angle = x^(p*(log_x(ANG_MAX)-log_x(ANG_MIN)) + log_x(ANG_MIN)),
// where x = (e-1) * (FAVOR_THRESHOLD/(FAVOR_THRESHOLD-t)) + 1


const TREE_GROWTH_ANGLE_MIN = 30; // In degrees
const TREE_GROWTH_ANGLE_MAX = 60; // In degrees

const TREE_DEV_ANGLE_MAX_BASE = 75; // In degrees, multiplied by (2-1/2^(gen-1))
// 0, 75, 75*(2-1/2), 75*(2 - 1/4), 75*(2-1/8), 75*(2-1/16), ...
// This value attempts to push MAX_BASE * 2

const TREE_SPLIT_ANGLE_MIN = 10; // In degrees
const TREE_SPLIT_ANGLE_MAX = 40; // In degrees
const TREE_SPLIT_MUTUAL_ANGLE_MIN = 30; // In degrees

const TREE_SPLIT_LENGTH_FACTOR_MAX = 0.4;
const TREE_SPLIT_AGE_MIN = 50; // multiplied by scale_base^generation
const TREE_SPLIT_AGE_MIN_SCALE_BASE = 1.5;
const TREE_SPLIT_GROWTH_PROB_SCALING = 0.5;
const TREE_SPLIT_GROWTH_RATE = 100;
// sum{P(split_age)} = 1-e^(-(x/GROWTH_RATE)^(TREE_SPLIT_GROWTH_PROB_SCALING)), x = min(0,split_age-split_age_min*scale_base^generation);
// Note when x = GROWTH_RATE, the probability will be 1-1/e, roughly 63% chance, always.
// When x = 2*GROWTH_RATE, the probability will be 1-1/sqrt{e} when PROB_SCALING = 0.5, roughly 76% chance.

TREE_GROWTH_AGE_MIN = 90
TREE_GROWTH_AGE_MIN_SCALE_BASE = 1.2


// END OF CONSTANTS FOR TREE GROWING

function comp_prob_true(split_age, age_min, prob_scaling, rate){
  return 1.0 - Math.exp(0.0 - Math.pow((Math.max(0.0,split_age-age_min)/rate), prob_scaling));
}

function should_grow(split_age, age_min, prob_scaling, rate){
  let prob = (comp_prob_true(split_age,age_min,prob_scaling,rate) - comp_prob_true(split_age-1,age_min,prob_scaling,rate))/(1.0-comp_prob_true(split_age-1,age_min,prob_scaling,rate));
  let rand_chance = Math.random();
  return (rand_chance < prob);
}

function len_expect(time, gen){
  return LOG_MODEL_CARRYING_CAPACITY*(Math.pow(LOG_MODEL_CARRYING_CAPACITY_SCALE_BASE,gen))/(1.0+LOG_MODEL_SCALE_FACTOR*(Math.exp(-LOG_MODEL_GROWTH_FACTOR*time)));
}

const NORMAL_CLT_TRIALS = 300;
function normalCLT(mean, stddev){
  let mean1000 = Math.floor(mean * 1000);
  let stddev1000 = Math.floor(stddev * 1000);
  let a = Math.floor(mean1000 - stddev1000 * Math.sqrt(3 * NORMAL_CLT_TRIALS));
  let b = Math.floor(mean1000 + stddev1000 * Math.sqrt(3 * NORMAL_CLT_TRIALS));
  let sum = 0;
  for(var i = 0; i < NORMAL_CLT_TRIALS; i++)
  {
    sum += Math.floor((Math.random() * (b-a)) + a);
  }
  return sum/(NORMAL_CLT_TRIALS) * 0.001;
}

class Line
{
  constructor(x1,x2,y1,y2){
    this.x1 = x1;
    this.x2 = x2;
    this.y1 = y1;
    this.y2 = y2;
  }
  get_x1(){
    return this.x1;
  }
  get_x2(){
    return this.x2;
  }
  get_y1(){
    return this.y1;
  }
  get_y2(){
    return this.y2;
  }
}

class Branch
{
  /**
  create_table "branches", force: :cascade do |t|
      t.integer "user_id", null: false
      t.integer "branch_id", null: false
      t.integer "age", null: false
      t.integer "parent_id", null: false
      t.integer "anglex10", default: 0, null: false
      t.float "length", null: false
      t.integer "sumdevx10", null: false
      t.float "factor", null: false
      t.integer "time_since_last_split", default: 0, null: false
      t.integer "num_children", default: 0
      t.integer "generation", default: 0, null: false
      t.boolean "has_split", default: false, null: false
      t.boolean "is_split_child", default: false, null: false
    end
  **/
  constructor(branch_id,age,parent_id,anglex10,length,sumdevx10,factor,time_since_last_split,num_children,generation,has_split,is_split_child)
  {
    this.branch_id = branch_id;
    this.age = age;
    this.parent_id = parent_id;
    this.anglex10 = anglex10;
    this.length = length;
    this.sumdevx10 = sumdevx10;
    this.factor = factor;
    this.time_since_last_split = time_since_last_split;
    this.num_children = num_children;
    this.generation = generation;
    this.has_split = has_split;
    this.is_split_child = is_split_child;
  }

  set_parent(B)
  {
    this.parent = B;
  }

  get_branch_id(){
    return this.branch_id;
  }

  get_age(){
    return this.age;
  }

  get_parent_id(){
    return this.parent_id;
  }

  get_anglex10(){
    return this.anglex10;
  }

  get_blength(){
    return this.length;
  }

  get_sumdevx10(){
    return this.sumdevx10;
  }

  get_factor(){
    return this.factor;
  }

  get_time_since_last_split(){
    return this.time_since_last_split;
  }

  get_num_children(){
    return this.num_children;
  }

  get_generation(){
    return this.generation;
  }

  get_has_split(){
    return this.has_split;
  }

  get_is_split_child(){
    return this.is_split_child;
  }

  increment_age(){
    this.age = this.age + 1;
    this.time_since_last_split = this.time_since_last_split + 1;
  }

  comp_angle_max(){
    return 10*TREE_DEV_ANGLE_MAX_BASE*(2 - Math.pow(0.5,(this.generation-1)));
  }

  pick_ratio(){

    var factor_max = TREE_FACTOR_MAX;
    var factor_min = TREE_FACTOR_MIN;

    // if branch.age == TREE_GROWTH_FAVOR_THRESHOLD
    //   random = rand(factor_max-factor_min+1)
    //   return (random.truncate(0) + factor_min)/1000.0
    // elsif branch.age < TREE_GROWTH_FAVOR_THRESHOLD
    //   normal_distrib = Distribution::Normal.rng((factor_min+factor_max)/2, ((TREE_GROWTH_FAVOR_THRESHOLD-branch.age)**(-0.1)) * (factor_max-factor_min)/3)
    //   return (((((normal_distrib.call).truncate(0) - factor_min)%(factor_max-factor_min) + (factor_max-factor_min)) % (factor_max-factor_min)) + factor_min)/1000.0
    // else
    //   p = rand(1)
    //   x = (Math::E - 1) * (TREE_GROWTH_FAVOR_THRESHOLD / (branch.age - TREE_GROWTH_FAVOR_THRESHOLD)) + 1
    //   factor = x**((p * (Math::log((factor_max + factor_min)/2) - Math::log(factor_min)) + Math::log(factor_min))/Math::log(x))
    //
    //   q = rand(1)
    //   if q > 0.5
    //     factor = factor_max+factor_min - factor
    //   end
    //
    //   return factor.truncate(0)/1000.0
    // end

    var rand = Math.floor(Math.random()*(factor_max-factor_min) + factor_min);
    return rand/1000.0;
  }

  pick_angle(is_left){

    var angle_min = TREE_GROWTH_ANGLE_MIN*10;
    var angle_max = TREE_GROWTH_ANGLE_MAX*10;

    if (is_left){
      if (this.sumdevx10 < 0){
        angle_max = Math.min(TREE_GROWTH_ANGLE_MAX*10, this.comp_angle_max()+this.sumdevx10);
        angle_min = angle_max * TREE_GROWTH_ANGLE_MIN/TREE_GROWTH_ANGLE_MAX;
      }
    }else{
      if (this.sumdevx10 > 0){
        angle_max = Math.max(TREE_GROWTH_ANGLE_MAX*10, this.comp_angle_max()-this.sumdevx10);
        angle_min = angle_max * TREE_GROWTH_ANGLE_MIN/TREE_GROWTH_ANGLE_MAX
      }
    }

    var angle = Math.floor(Math.random(angle_max-angle_min) + angle_min);
    if (is_left){
      return -1 * angle;
    }else{
      return angle;
    }
  }

  set_length(len){
    this.length = len;
  }

  reset_split(){
    this.time_since_last_split = 0;
  }

  children_decr(){
    this.children -= 1;
  }

  children_incr(){
    this.children += 1;
  }

  toString()
  {
    return "Branch " + `${this.branch_id}` + ": ["
         + "Age: " + `${this.age}`
         + ", Parent: " + `${this.parent_id}`
         + ", Factor: " + `${this.factor}`
         + ", Deviation*10: " + `${this.sumdevx10}`
         + "]";
  }
}

class TreeGrowth
{
  constructor(branchdict, last_branch_id){
    this.branches = branchdict;
    this.last_branch_id = last_branch_id;
  }
  get_branches(){
    return this.branches;
  }
  get_last_branch_id(){
    return this.last_branch_id;
  }
  compStartPoint(B,factor){
    var theline = this.compBranchInfo(B);
    var thepoint = [0,0];
    thepoint[0] = (1-factor)*(theline.get_x1()) + (factor)*(theline.get_x2());
    thepoint[1] = (1-factor)*(theline.get_y1()) + (factor)*(theline.get_y2());
    return thepoint;
  }

  compBranchInfo(B){
    var startpoint = null;
    if(B.get_parent_id() == -1){
      startpoint = [400,600];
    }else{
      startpoint = this.compStartPoint(this.branches[B.get_parent_id()],B.get_factor());
    }
    var len = B.get_blength();
    var delx = len * Math.sin(B.get_sumdevx10() * Math.PI / 1800.0);
    var dely = -len * Math.cos(B.get_sumdevx10() * Math.PI / 1800.0);
    var result_line = new Line(startpoint[0],startpoint[0]+delx,startpoint[1],startpoint[1]+dely);
    return result_line;
  }
  grow_tree(){
    for (var key in this.branches){
      var b = this.branches[key];
      b.increment_age();
      if (!b.get_has_split()){
        // Length Increase Mechanic
        var newlen = len_expect(b.get_age(),b.get_generation());
        var curexp = len_expect(b.get_age()-1, b.get_generation());
        let curlen = b.get_blength();
        let diff = normalCLT((newlen-curexp), (newlen-curexp)*LENGTH_STD_DEV_FACTOR);
        if (diff > 0){
          b.set_length(curlen + diff);
        }
        // Offshoot Mechanic
        if (should_grow(b.get_time_since_last_split(),
                       TREE_GROWTH_AGE_MIN*(TREE_GROWTH_AGE_MIN_SCALE_BASE**b.get_generation()),
                       TREE_SPLIT_GROWTH_PROB_SCALING, TREE_SPLIT_GROWTH_RATE)){
          b.reset_split();
          var is_left = true;
          if (b.get_num_children() == 0){
            var rand_chance = Math.random();
            if (rand_chance < 0.5){
              is_left = false;
            }
          }else{
            if (b.get_num_children() < 0){
              is_left = false;
            }
          }

          if (is_left){
            b.children_decr();
          }else{
            b.children_incr();
          }
          var newangle = b.pick_angle(is_left);
          var newratio = b.pick_ratio();

          this.last_branch_id = this.last_branch_id+1;
          //constructor(branch_id,age,parent_id,anglex10,length,sumdevx10,factor,time_since_last_split,num_children,generation,has_split,is_split_child)
          this.branches[this.last_branch_id] =
            new Branch(branch_id = this.last_branch_id, age = 0,
                       parent_id = b.get_branch_id(), anglex10 = newangle,
                       length = 2.0, sumdevx10 = b.get_sumdevx10()+newangle,
                       factor = newratio, time_since_last_split = 0,
                       num_children = 0, generation = b.get_generation()+1,
                       has_split = false, is_split_child = false);
        }

        // Split Mechanic to be implemented here

      }
    }
  }
}
