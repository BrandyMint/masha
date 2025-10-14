# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::EditCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let!(:project) { create(:project, name: 'Test Project', slug: 'test') }
  let!(:time_shift) { create(:time_shift, user: user, project: project, hours: 8, description: 'Original work') }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
    allow(controller).to receive(:multiline) { |*args| args.compact.join("\n") }
    allow(controller).to receive(:code) { |text| "```\n#{text}\n```" }
    allow(controller).to receive(:session).and_return({})

    # Create membership so user has access to project
    create(:membership, user: user, project: project)
  end

  describe '#call' do
    it 'creates TimeShiftService and calls show_time_shifts_list' do
      service_double = instance_double(Telegram::Edit::TimeShiftService)
      expect(Telegram::Edit::TimeShiftService).to receive(:new).with(controller, user).and_return(service_double)
      expect(service_double).to receive(:show_time_shifts_list).with(1)

      command.call
    end
  end

  describe '#show_time_shifts_list' do
    it 'creates TimeShiftService and calls show_time_shifts_list with page parameter' do
      service_double = instance_double(Telegram::Edit::TimeShiftService)
      expect(Telegram::Edit::TimeShiftService).to receive(:new).with(controller, user).and_return(service_double)
      expect(service_double).to receive(:show_time_shifts_list).with(2)

      command.show_time_shifts_list(2)
    end
  end
end
