class Session < ActiveRecord::Base
  def [](key)
    @data = Marshal.load(Base64.decode64(self.data)) unless @data

    return @data[key]
  end
end
