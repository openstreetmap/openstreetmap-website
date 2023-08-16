class UseMicrosoftGraph < ActiveRecord::Migration[7.0]
  def self.up
    User.where(:auth_provider => 'windowslive').update_all(:auth_provider => 'microsoft_graph')
  end

  def self.down
    User.where(:auth_provider => 'microsoft_graph').update_all(:auth_provider => 'windowslive')
  end
end
