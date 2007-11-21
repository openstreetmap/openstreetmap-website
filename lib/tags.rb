module Tags
  def self.join(tags)
    joined = tags.collect { |k,v| "#{escape_string(k)}=#{escape_string(v)}" }.join(';')
    joined = '' if joined.nil?
    return joined
  end

  def self.escape_string(tag)
    return tag.gsub(/[;=\\]/) { |v| escape_char(v) }
  end

  def self.escape_char(v)
    case v
      when ';' then return '\\s'
      when '=' then return '\\e'
    end
    return '\\\\'
  end

  def self.split(tags)
    tags.split(';').each do |tag|
      key,val = tag.split('=').collect { |s| s.strip }
      key = '' if key.nil?
      val = '' if val.nil?
      if key != '' && val != ''
        yield unescape_string(key),unescape_string(val)
      end
    end
  end

  def self.unescape_string(tag)
    return tag.gsub(/\\[se\\]/) { |v| unescape_char(v) }
  end

  def self.unescape_char(v)
    case v
      when '\\s' then return ';'
      when '\\e' then return '='
    end
    return '\\'
  end
end
