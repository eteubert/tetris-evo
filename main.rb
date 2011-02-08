class Individual
  
  @weights    = []
  @exponents  = []
  
  def initialize(values)
    @weights    = values[:weights]
    @exponents  = values[:exponents]
  end

  def self.create_random(size = 12)
    weights = exponents = []
    size.times do |i|
      weights << self::random_weight
      exponents << self::random_exponent
    end
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

