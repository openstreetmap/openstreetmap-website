# From:
# http://www.bigbold.com/snippets/posts/show/2178
# http://blog.caboo.se/articles/2006/06/11/stupid-hash-tricks
# 
# An example utilisation of these methods in a controller is:
# def some_action
#    # some script kiddie also passed in :bee, which we don't want tampered with _here_.
#    @model = Model.create(params.pass(:foo, :bar))
#  end
class Hash

  # lets through the keys in the argument
  # >> {:one => 1, :two => 2, :three => 3}.pass(:one)
  # => {:one=>1}
  def pass(*keys)
    keys = keys.first if keys.first.is_a?(Array)
    tmp = self.clone
    tmp.delete_if {|k,v| ! keys.include?(k.to_sym) }
    tmp.delete_if {|k,v| ! keys.include?(k.to_s) }
    tmp
  end

  # blocks the keys in the arguments
  # >> {:one => 1, :two => 2, :three => 3}.block(:one)
  # => {:two=>2, :three=>3}
  def block(*keys)
    keys = keys.first if keys.first.is_a?(Array)
    tmp = self.clone
    tmp.delete_if {|k,v| keys.include?(k.to_sym) }
    tmp.delete_if {|k,v| keys.include?(k.to_s) }
    tmp
  end

end
