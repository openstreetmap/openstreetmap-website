class CreateCommunityMember < ActiveRecord::Migration[7.0]
  def change
    create_enum :community_member_role_enum, %w[member organizer]

    safety_assured do
      change_table :communities do |t|
        t.rename :organizer_id, :leader_id
      end
    end

    create_table :community_members do |t|
      t.references :community, :foreign_key => true, :null => false, :index => true
      t.references :user, :foreign_key => true, :null => false, :index => true
      t.column :role, :community_member_role_enum, :null => false, :default => "member"

      t.timestamps
      t.index [:community_id, :user_id, :role], :unique => true
    end

    # There will likely be no communities yet, but if there are, create members
    # for each leader of communities.
    reversible do |dir|
      dir.up do
        Community.all.each do |community|
          CommunityMember.new(
            :community => community,
            :user => community.leader,
            :role => CommunityMember::Roles::ORGANIZER
          ).save!
        end
      end
      # There's no need for dir.down because the entire table will be dropped.
    end
  end
end
