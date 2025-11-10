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

      context 'integer slugs' do
        it 'does not allow integer slugs' do
          integer_slugs = %w[1 2 123 999 0]

          integer_slugs.each do |integer_slug|
            project = build(:project, slug: integer_slug)
            project.valid?
            expect(project.errors[:slug]).to include("не может быть целым числом: #{integer_slug}")
          end
        end

        it 'allows slugs with numbers mixed with letters' do
          mixed_slugs = %w[project1 2project test123abc abc123]

          mixed_slugs.each do |mixed_slug|
            project = build(:project, slug: mixed_slug)
            project.valid?
            expect(project.errors[:slug]).to be_empty
          end
        end

        it 'allows decimal numbers in slug' do
          decimal_slugs = %w[1.5 2.0 123.45]

          decimal_slugs.each do |decimal_slug|
            project = build(:project, slug: decimal_slug)
            project.valid?
            expect(project.errors[:slug]).to be_empty
          end
        end
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
