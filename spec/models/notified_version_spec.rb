# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotifiedVersion, type: :model do
  before do
    allow(AppStartupNotificationJob).to receive(:perform_later)
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:version) }
  end

  describe 'attributes' do
    it 'has a version attribute' do
      expect(described_class.new).to respond_to(:version)
      expect(described_class.new).to respond_to(:version=)
    end
  end

  describe 'database' do
    it 'has the correct table structure' do
      expect(described_class.table_exists?).to be true
      expect(described_class.column_names).to include('version')
    end

    it 'enforces unique versions' do
      test_version = "app-version-#{SecureRandom.hex(4)}"
      described_class.create(version: test_version)

      record2 = described_class.new(version: test_version)
      # This should fail due to uniqueness constraint
      expect(record2.save).to be false
    end
  end
end
