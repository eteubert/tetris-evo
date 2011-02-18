require 'tetris-api'

require './initializers'

RATING_SUBFUNCTIONS = 12
DEBUG = false

BOARD_WIDTH = 6
BOARD_HEIGHT = 6

POPULATION_SIZE = 12
CHILDREN_SIZE = 12

RECOMBINATION_CHANCE = 0.2
MUTATION_CHANCE = 1.0/6

GENERATIONS = 100

require './individual'

class Main
  
  def initialize(values = {})
    @population_size = values[:population_size] || POPULATION_SIZE
    @population = []
    @iteration = 1
    @logger = Logger.new("log/#{Time.new}.log")
  end
  
  def run
    @logger.info  "== Random Individuals =="
    puts "== Random Individuals =="
    
    generate_initial_population
    # sort population by fitness
    @population.sort_by!(&:fitness).reverse!
    # print current populations fitness
    @logger.info @population.map(&:fitness).inspect
    p @population.map(&:fitness)
    
    GENERATIONS.times do
      @logger.info "== Iteration #{@iteration} =="
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
      selection = Selection.new(
        :take => POPULATION_SIZE,
        :with_parents => @population,
        :and_children => children
      )
      @population = selection.tournament

      # logging
      sorted_population = @population.sort_by(&:fitness).reverse!
      best = sorted_population.first
      
      @logger.info sorted_population.map(&:fitness).inspect
      p sorted_population.map(&:fitness)
      
      @logger.info "Best Individual:"
      @logger.info "Fitness    #{best.fitness} cleared lines"
      @logger.info "Weights    #{best.weights.to_s}"
      @logger.info "Exponents  #{best.exponents.to_s}"

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
  
  def initialize(values)
    @amount = values[:take]
    @parents = values[:with_parents]
    @children = values[:and_children]
    @population = @parents + @children
  end
  
  def elite
    @population.sort_by(&:fitness).reverse!.take(@amount)
  end
  
  # 3 stage tournament
  def tournament
    @population.each { |individual| individual.wins = 0 }
    
    @population.each do |individual|
      3.times do
        duelist = @population.sample
        if individual.fitness > duelist.fitness
          individual.wins += 1
        else
          duelist.wins += 1
        end
      end
    end
    
    @population.sort_by(&:wins).reverse!.take(@amount)
  end
  
end

main = Main.new
main.run
