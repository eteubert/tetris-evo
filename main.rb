require 'tetris-api'

RATING_SUBFUNCTIONS = 12
DEBUG = false

BOARD_WIDTH = 6
BOARD_HEIGHT = 6

POPULATION_SIZE = 5
CHILDREN_SIZE = 8

RECOMBINATION_CHANCE = 0.2

CYCLES = 10

class Array
  
  def sum
    self.compact.inject(0) {|sum, i| sum += i}
  end
  
  def rand_index
    rand(self.length)
  end
  
  def sample
    self[rand_index]
  end
  
end

class Individual
  attr_reader :weights, :exponents
  attr_accessor :fitness
  
  @weights    = []
  @exponents  = []
  @fitness    = nil
  
  def initialize(values)
    @weights    = values[:weights]
    @exponents  = values[:exponents]
  end
  
  def ihash
    (@weights.sum * @exponents.sum).to_s[0,64]
  end
  
  # mutate 1 weight and 1 exponent at once
  # weights:
  #   - *= 2 to 100  70%
  #   - /= 2 to 100  25%
  #   - *= -1        5%
  # exponent:
  #   - +- 0 to 0.5 
  def mutate
    weight_index = rand(RATING_SUBFUNCTIONS)
    random_value_for_weight = (rand * 100).round
    
    @weights[weight_index] = case random_value_for_weight
    when 0..5     then @weights[weight_index] *= -1
    when 6..30    then @weights[weight_index] /= rand(99)+2
    when 31..100  then @weights[weight_index] *= rand(99)+2
    end
    @weights[weight_index] = @weights[weight_index].round
    
    exponent_index = rand(RATING_SUBFUNCTIONS)
    @exponents[exponent_index] += rand - 0.5
    
    # uncache fitness
    @fitness = nil
    
    self
  end
    
  # one point crossover
  # either weights OR exponents
  def recombine_with(individual)
    if rand < 0.5 # weights
      index = rand(@weights.length)
      if rand < 0.5 # adopt sequence before index
        0.upto(index) do |i|
          @weights[i] = individual.weights[i]
        end
      else          # adopt sequence after index
        index.upto(weights.length) do |i|
          @weights[i] = individual.weights[i]
        end
      end
    else          # exponents
      index = rand(@exponents.length)
      if rand < 0.5 # adopt sequence before index
        0.upto(index) do |i|
          @exponents[i] = individual.exponents[i]
        end
      else          # adopt sequence after index
        index.upto(weights.length) do |i|
          @exponents[i] = individual.exponents[i]
        end
      end
    end
  end  
    
  def fitness
    
    # cache fitness
    return @fitness unless @fitness.nil?
    
    # puts "Calc fitness for #{self.ihash}"
    
    # or recalculate it
    @tetris = Tetris::Game.new(
      Tetris::Dimensions.new(:width => BOARD_WIDTH, :height => BOARD_HEIGHT)
    )
    current_fitness = 0
    best_board = @tetris.board
    while not best_board.lost?
      possibilities = best_board.generate_possibilities_for_both_tetrominos
      
      # choose board with highest rating
      highest_rating = nil
      best_board = nil

      possibilities.each do |board|
        rating = Tetris::BoardRating.new(board)
        rating_sum = 0
        RATING_SUBFUNCTIONS.times do |i|
          rating_sum += @weights[i] * rating.send(Tetris::BoardRating::RATING_NAMES[i]) ** @exponents[i]
        end
        if highest_rating == nil || rating_sum > highest_rating
          highest_rating = rating_sum
          best_board = deep_copy(board.parent)
        end
      end
      
      break if best_board.nil?
      break if DEBUG && current_fitness > 5
      current_fitness = best_board.lines_cleared
      # puts "======"
      # best_board.display
      # puts best_board.lines_cleared
    end
    
    @fitness = current_fitness
    
    return @fitness
  end

  def self.create_random(size = 12)
    weights = []
    exponents = []
    size.times do |i|
      weights << self::random_weight
      exponents << self::random_exponent
    end
    Individual.new(:weights => weights, :exponents => exponents)
  end
  
  # random signed fixnum (-999 to 999)
  def self.random_weight
    weight = rand(1000)
    weight = -weight if rand > 0.5
    weight
  end
  
  # random unsigned float (0.5 to 1.5)
  def self.random_exponent
    rand + 0.5
  end
  
end

class Main
  
  def initialize(values = {})
    @population_size = values[:population_size] || POPULATION_SIZE
    @population = []
    @iteration = 1
  end
  
  def run
    puts "== Random Individuals =="
    
    generate_initial_population
    # sort population by fitness
    @population.sort_by!(&:fitness).reverse!
    # print current populations fitness
    p @population.map(&:fitness)
    
    CYCLES.times do
      puts "== Iteration #{@iteration} =="
      # calculate children via mutation & recombination
      children = []
      CHILDREN_SIZE.times do
        sample = deep_copy(@population.sample)
        if rand < RECOMBINATION_CHANCE
          sample.recombine_with deep_copy(@population.sample)
        end
        children << sample.mutate
      end

      # take best <POPULATION_SIZE> of parents and children
      # old_and_new = (@population + children).sort_by!(&:fitness).reverse!
      # @population = old_and_new.take(POPULATION_SIZE)
      @population = Selection::elite(@population, children, POPULATION_SIZE)
      p @population.map(&:fitness)

      @iteration += 1
    end
  end
  
  private
  
  def generate_initial_population
    @population_size.times do |i|
      @population << Individual::create_random
    end
  end
  
end

class Selection
  
  def self.elite(parents, children, amount)
    (parents + children).sort_by(&:fitness).reverse!.take(amount)
  end
  
end

main = Main.new
main.run
