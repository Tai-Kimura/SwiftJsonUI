# frozen_string_literal: true

class String
  def camelize
    self.split("_").map{|w| w.empty? ? w : (w[0] = w[0].upcase; w)}.join
  end
end