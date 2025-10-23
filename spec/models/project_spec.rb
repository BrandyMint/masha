# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  subject { build(:project) }

  it { should be_valid }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }

    context 'slug validation' do
      it { should validate_uniqueness_of(:slug) }
    end

    context 'reserved words' do
      it 'does not allow reserved words as slug' do
        # Проверяем несколько примеров реальных зарезервированных слов
        reserved_words = %w[list start stop day week projects settings]

        reserved_words.each do |reserved_word|
          project = build(:project, slug: reserved_word)
          project.valid?
          expect(project.errors[:slug]).to include("не может быть зарезервированным словом: #{reserved_word}")
        end
      end

      it 'allows normal slugs' do
        project = build(:project, slug: 'my-awesome-project')
        project.valid?
        expect(project.errors[:slug]).to be_empty
      end
    end
  end

  describe 'scopes' do
    let!(:active_project) { create(:project, active: true) }
    let!(:archived_project) { create(:project, active: false) }

    it '.active returns only active projects' do
      expect(Project.active).to contain_exactly(active_project)
    end

    it '.archive returns only archived projects' do
      expect(Project.archive).to contain_exactly(archived_project)
    end
  end
end
