# frozen_string_literal: true

require 'spec_helper'

describe TimeSheetForm do
  subject { described_class }

  describe 'date format' do
    context 'blank dates' do
      let(:form) { described_class.new date_from: '', date_to: '' }
      it 'should be invalid' do
        expect(form).not_to be_valid
      end
    end

    context 'invalid date format 67-dsf-000' do
      let(:form) { described_class.new date_from: '67-dsf-000', date_to: '67-dsf-000' }
      it 'should be invalid' do
        expect(form).not_to be_valid
      end
    end
  end
end
