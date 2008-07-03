module ObjectFinder
  def visible
    find :all, :conditions => "#{proxy_reflection.table_name}.visible = 1"
  end
end
