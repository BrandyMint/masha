# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberNotificationJob, type: :job do
  fixtures :memberships

  let(:project) { projects(:work_project) }
  let(:new_member) { users(:user_with_telegram) }
  let(:existing_member) { users(:admin) }

  # existing_member is already a member of work_project via admin_work fixture

  it 'enqueues the job' do
    expect do
      described_class.perform_later(project_id: project.id, new_member_id: new_member.id)
    end.to have_enqueued_job(described_class)
  end

  it 'sends notifications to project members' do
    expect(TelegramNotificationJob).to receive(:perform_later).at_least(:once)
    described_class.new.perform(project_id: project.id, new_member_id: new_member.id)
  end

  it 'does not raise error when project has no other members' do
    project_with_one_member = projects(:test_project)
    expect do
      described_class.new.perform(project_id: project_with_one_member.id, new_member_id: new_member.id)
    end.not_to raise_error
  end

  it 'does not raise error when new member has no telegram account' do
    user_without_telegram = users(:regular_user)
    expect do
      described_class.new.perform(project_id: project.id, new_member_id: user_without_telegram.id)
    end.not_to raise_error
  end
end
