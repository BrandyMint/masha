class AddMissedMembers < ActiveRecord::Migration
  def change
    TimeShift.find_each do |ts|
      ts.user.membership_of(ts.project) || ts.user.memberships.create!(:project=>ts.project, :role=>:member)
    end
  end
end
