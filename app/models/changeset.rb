class Changeset < ActiveRecord::Base
  require 'xml/libxml'

  belongs_to :user

  has_many :changeset_tags, :foreign_key => 'id'

  def self.from_xml(xml, create=false)
    begin
      p = XML::Parser.new
      p.string = xml
      doc = p.parse

      cs = Changeset.new

      doc.find('//osm/changeset').each do |pt|
        if create
          cs.created_at = Time.now
        end

        pt.find('tag').each do |tag|
          cs.add_tag_keyval(tag['k'], tag['v'])
        end
      end
    rescue Exception => ex
    print "noes "+ ex.to_s + "\n"
      cs = nil
    end

    return cs
  end

  def tags
    unless @tags
      @tags = {}
      self.changeset_tags.each do |tag|
        @tags[tag.k] = tag.v
      end
    end
    @tags
  end

  def tags=(t)
    @tags = t
  end

  def add_tag_keyval(k, v)
    @tags = Hash.new unless @tags
    @tags[k] = v
  end

  def save_with_tags!
    t = Time.now

    Changeset.transaction do
      # fixme update modified_at time?
      self.save!
    end

    ChangesetTag.transaction do
      tags = self.tags
      ChangesetTag.delete_all(['id = ?', self.id])

      tags.each do |k,v|
        tag = ChangesetTag.new
        tag.k = k
        tag.v = v
        tag.id = self.id
        tag.save!
      end
    end
  end
end
