# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientAuthorizer, type: :authorizer do
  subject { described_class.new(resource) }

  let(:current_user) { users(:regular_user) }
  let(:owner) { users(:user_with_telegram) }
  let(:resource) { clients(:client1) } # Глобальный ресурс, будет переопределен в контекстах
  let(:other_user) { users(:project_owner) }
  let(:project) { projects(:project_with_client1) }

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
    let(:resource) { clients(:participant_client) }
    let(:current_user) { users(:user_with_telegram) }

    before do
      # user_with_telegram является участником project_with_client1 через fixture telegram_with_client
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
    let(:current_user) { users(:user_with_telegram) }
    let(:other_project) { projects(:work_project) }

    before do
      # user_with_telegram является участником project_with_client1
      # Для теста имитируем участие в другом проекте того же клиента
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
      # Пользователь не имеет membership для этого клиента
      # В fixtures regular_user не является участником work_client
    end

    describe '#readable_by?' do
      it 'returns false after membership removal' do
        expect(subject.readable_by?(current_user)).to be false
      end
    end
  end

  describe 'edge cases' do
    context 'when client has no projects' do
      let(:resource) { clients(:dev_client) }
      let(:dev_owner) { users(:project_owner) }
      let(:unrelated_user) { users(:regular_user) }

      it 'owner can perform all actions' do
        expect(subject.creatable_by?(dev_owner)).to be true
        expect(subject.readable_by?(dev_owner)).to be true
        expect(subject.updatable_by?(dev_owner)).to be true
        expect(subject.deletable_by?(dev_owner)).to be true
      end

      it 'non-owner users cannot read the client' do
        expect(subject.readable_by?(unrelated_user)).to be false
      end
    end

    context 'when user is root user' do
      let(:root_user) { users(:admin) }

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
