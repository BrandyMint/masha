# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Edit::PaginationService do
  let(:controller) { double('controller', session: session) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(controller, user) }
  let(:session) { {} }

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

    it 'orders time shifts by date and created_at desc' do
      result = service.get_paginated_time_shifts(1)
      shifts = result[:time_shifts]

      expect(shifts).to eq(shifts.sort_by { |s| [s.date, s.created_at] }.reverse)
    end

    it 'includes project association' do
      result = service.get_paginated_time_shifts(1)
      time_shift = result[:time_shifts].first

      expect(time_shift.association(:project)).to be_loaded
    end
  end

  describe '#save_pagination_context' do
    let(:pagination) do
      {
        current_page: 2,
        total_pages: 5,
        per_page: 10,
        offset: 10,
        has_next: true,
        has_prev: true
      }
    end

    it 'saves pagination data to session' do
      service.save_pagination_context(pagination)

      expect(controller.session[:edit_pagination]).to eq({
        current_page: 2,
        total_pages: 5
      })
    end
  end

  describe '#validate_page' do
    context 'with pagination context in session' do
      before do
        controller.session[:edit_pagination] = { current_page: 1, total_pages: 3 }
      end

      it 'returns true for valid page' do
        expect(service.validate_page(2)).to be true
      end

      it 'returns false for page too low' do
        expect(service.validate_page(0)).to be false
      end

      it 'returns false for page too high' do
        expect(service.validate_page(4)).to be false
      end

      it 'returns false for non-integer page' do
        expect(service.validate_page('2')).to be false
      end
    end

    context 'without pagination context in session' do
      it 'returns false' do
        expect(service.validate_page(1)).to be false
      end
    end
  end

  describe '#build_keyboard' do
    context 'with multiple pages' do
      let(:pagination) do
        {
          current_page: 2,
          total_pages: 5,
          per_page: 10,
          offset: 10,
          has_next: true,
          has_prev: true
        }
      end

      it 'builds keyboard with navigation buttons' do
        keyboard = service.build_keyboard(pagination)

        expect(keyboard).to eq({
          inline_keyboard: [
            [
              { text: "⬅️ Назад", callback_data: "edit_page:1" },
              { text: "2/5", callback_data: "noop" },
              { text: "Вперед ➡️", callback_data: "edit_page:3" }
            ]
          ]
        })
      end
    end

    context 'on first page' do
      let(:pagination) do
        {
          current_page: 1,
          total_pages: 3,
          per_page: 10,
          offset: 0,
          has_next: true,
          has_prev: false
        }
      end

      it 'builds keyboard without back button' do
        keyboard = service.build_keyboard(pagination)

        expect(keyboard).to eq({
          inline_keyboard: [
            [
              { text: "1/3", callback_data: "noop" },
              { text: "Вперед ➡️", callback_data: "edit_page:2" }
            ]
          ]
        })
      end
    end

    context 'on last page' do
      let(:pagination) do
        {
          current_page: 3,
          total_pages: 3,
          per_page: 10,
          offset: 20,
          has_next: false,
          has_prev: true
        }
      end

      it 'builds keyboard without next button' do
        keyboard = service.build_keyboard(pagination)

        expect(keyboard).to eq({
          inline_keyboard: [
            [
              { text: "⬅️ Назад", callback_data: "edit_page:2" },
              { text: "3/3", callback_data: "noop" }
            ]
          ]
        })
      end
    end

    context 'with single page' do
      let(:pagination) do
        {
          current_page: 1,
          total_pages: 1,
          per_page: 10,
          offset: 0,
          has_next: false,
          has_prev: false
        }
      end

      it 'returns nil' do
        keyboard = service.build_keyboard(pagination)
        expect(keyboard).to be_nil
      end
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

    it 'returns nil for page that fails validation' do
      page = service.handle_callback('edit_page:0')
      expect(page).to be_nil
    end

    context 'without pagination context' do
      before do
        controller.session[:edit_pagination] = nil
      end

      it 'returns nil even for valid callback format' do
        page = service.handle_callback('edit_page:1')
        expect(page).to be_nil
      end
    end
  end
end