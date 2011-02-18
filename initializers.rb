class Array
  
  def sum
    self.compact.inject(0) {|sum, i| sum += i}
  end
  
  def avg
    (self.sum / self.count.to_f).round(2)
  end
  
  def rand_index
    rand(self.length)
  end
  
  def sample
    self[rand_index]
  end
  
end