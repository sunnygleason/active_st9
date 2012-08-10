module ActiveRest
  module Reloadable
    def reloaded
      self.class.find!(id)
    end
  end
end
