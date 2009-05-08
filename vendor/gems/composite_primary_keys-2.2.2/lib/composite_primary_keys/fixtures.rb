class Fixture #:nodoc:
  def [](key)
    if key.is_a? Array
      return key.map { |a_key| self[a_key.to_s] }.to_composite_ids.to_s
    end
    @fixture[key]
  end
end
