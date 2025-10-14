# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Edit::PaginationService do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(controller, user) }

  before do
    allow(controller).to receive(:session).and_return({})
  end

  describe '#get_paginated_time_shifts' do
    let!(:project) { create(:project) }

    before do
      create(:membership, user: user, project: project)
      # Create test time shifts
      15.times { |i| create(:time_shift, user: user, project: project, hours: i + 1) }
    end

    it 'returns paginated results' do
      result = service.get_paginated_time_shifts(2)

      expect(result[:time_shifts]).to be_present
      expect(result[:pagination][:current_page]).to eq(2)
      expect(result[:pagination][:per_page]).to eq(ApplicationConfig.telegram_edit_per_page)
      expect(result[:total_count]).to eq(15)
    end

    it 'calculates total pages correctly' do
      result = service.get_paginated_time_shifts(1)
      total_pages = (15.0 / ApplicationConfig.telegram_edit_per_page).ceil

      expect(result[:pagination][:total_pages]).to eq(total_pages)
    end
  end

  describe '#handle_callback' do
    before do
      controller.session[:edit_pagination] = { current_page: 1, total_pages: 3 }
    end

    it 'extracts page number from callback data' do
      page = service.handle_callback('edit_page:2')
      expect(page).to eq(2)
    end

    it 'validates page number' do
      page = service.handle_callback('edit_page:5')
      expect(page).to be_nil
    end

    it 'returns nil for invalid callback format' do
      page = service.handle_callback('invalid_callback')
      expect(page).to be_nil
    end
  end
end