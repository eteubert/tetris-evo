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