class String
  def camelize
    self.split("_").map{|w| w[0] = w[0].upcase; w}.join
  end
end