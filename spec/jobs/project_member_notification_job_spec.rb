# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberNotificationJob, type: :job do
  let(:project) { projects(:work_project) }
  let(:new_member) { users(:user_with_telegram) }
  let(:existing_member) { users(:admin) }

  before do
    # Ensure existing_member is a member of the project
    existing_member.memberships.create(project: project, role_cd: 2) unless existing_member.memberships.exists?(project: project)
  end

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
