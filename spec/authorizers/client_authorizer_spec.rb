# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientAuthorizer, type: :authorizer do
  subject { described_class.new(resource) }

  let(:current_user) { create(:user) }
  let(:owner) { create(:user) }
  let(:resource) { create(:client, user: owner) }
  let(:other_user) { create(:user) }
  let(:project) { create(:project, client: resource) }

  context 'when user is the owner of the client' do
    let(:current_user) { owner }

    describe '#creatable_by?' do
      it 'returns true' do
        expect(subject.creatable_by?(current_user)).to be true
      end
    end

    describe '#readable_by?' do
      it 'returns true' do
        expect(subject.readable_by?(current_user)).to be true
      end
    end

    describe '#updatable_by?' do
      it 'returns true' do
        expect(subject.updatable_by?(current_user)).to be true
      end
    end

    describe '#deletable_by?' do
      it 'returns true' do
        expect(subject.deletable_by?(current_user)).to be true
      end
    end
  end

  context 'when user is a project participant of the client' do
    let(:current_user) { other_user }

    before do
      # Добавляем пользователя как участника проекта клиента
      create(:membership, user: current_user, project: project, role: :member)
    end

    describe '#creatable_by?' do
      it 'returns true for any user' do
        expect(subject.creatable_by?(current_user)).to be true
      end
    end

    describe '#readable_by?' do
      it 'returns true for project participants' do
        expect(subject.readable_by?(current_user)).to be true
      end
    end

    describe '#updatable_by?' do
      it 'returns false for non-owners' do
        expect(subject.updatable_by?(current_user)).to be false
      end
    end

    describe '#deletable_by?' do
      it 'returns false for non-owners' do
        expect(subject.deletable_by?(current_user)).to be false
      end
    end
  end

  context 'when user is not related to the client' do
    let(:current_user) { other_user }

    describe '#creatable_by?' do
      it 'returns true for any user' do
        expect(subject.creatable_by?(current_user)).to be true
      end
    end

    describe '#readable_by?' do
      it 'returns false for unrelated users' do
        expect(subject.readable_by?(current_user)).to be false
      end
    end

    describe '#updatable_by?' do
      it 'returns false for non-owners' do
        expect(subject.updatable_by?(current_user)).to be false
      end
    end

    describe '#deletable_by?' do
      it 'returns false for non-owners' do
        expect(subject.deletable_by?(current_user)).to be false
      end
    end
  end

  context 'when user is a participant in multiple projects of the client' do
    let(:current_user) { other_user }
    let(:other_project) { create(:project, client: resource) }

    before do
      create(:membership, user: current_user, project: project, role: :member)
      create(:membership, user: current_user, project: other_project, role: :member)
    end

    describe '#readable_by?' do
      it 'returns true for participants in any client project' do
        expect(subject.readable_by?(current_user)).to be true
      end
    end
  end

  context 'when user was a participant but membership was removed' do
    let(:current_user) { other_user }

    before do
      # Ensure there's at least one user in the database so new users don't become root
      create(:user) unless User.exists?

      membership = create(:membership, user: current_user, project: project, role: :member)
      membership.destroy
    end

    describe '#readable_by?' do
      it 'returns false after membership removal' do
        expect(subject.readable_by?(current_user)).to be false
      end
    end
  end

  describe 'edge cases' do
    context 'when client has no projects' do
      let(:resource) { create(:client, user: owner) }

      it 'owner can perform all actions' do
        expect(subject.creatable_by?(owner)).to be true
        expect(subject.readable_by?(owner)).to be true
        expect(subject.updatable_by?(owner)).to be true
        expect(subject.deletable_by?(owner)).to be true
      end

      it 'non-owner users cannot read the client' do
        expect(subject.readable_by?(other_user)).to be false
      end
    end

    context 'when user is root user' do
      let(:root_user) { create(:user, is_root: true) }

      before do
        # Root users should have access through default method in ApplicationAuthorizer
        allow(described_class).to receive(:default).and_return(true)
      end

      describe '#readable_by?' do
        it 'returns true for root users' do
          expect(subject.readable_by?(root_user)).to be true
        end
      end
    end
  end
end
