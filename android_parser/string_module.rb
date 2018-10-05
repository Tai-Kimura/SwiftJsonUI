class String
  def to_camel
    self.split("_").map{|w| w[0] = w[0].upcase; w}.join
  end

  def to_snake
    self
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr("-", "_")
      .downcase
  end
end