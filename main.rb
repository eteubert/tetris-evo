require 'tetris-api'

POPULATION_SIZE = 5
BOARD_WIDTH = 6
BOARD_HEIGHT = 10
RATING_SUBFUNCTIONS = 12
DEBUG = true

class Individual
  attr_reader :weights, :exponents
  
  @weights    = []
  @exponents  = []
  @fitness    = nil
  
  def initialize(values)
    @weights    = values[:weights]
    @exponents  = values[:exponents]
  end

  def fitness
    
    # cache fitness
    return @fitness unless @fitness.nil?
    
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
  end
  
  def run
    generate_initial_population
    
    # sort population by fitness
    @population.sort_by!(&:fitness).reverse!
    # print current populations fitness
    p @population.map(&:fitness)
  end
  
  private
  
  def generate_initial_population
    @population_size.times do |i|
      @population << Individual::create_random
    end
  end
  
end

main = Main.new
main.run
