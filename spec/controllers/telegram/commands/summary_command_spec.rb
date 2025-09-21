# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::SummaryCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:code).and_return('```code```')
  end

  describe '#call' do
    it 'generates weekly summary by default' do
      reporter = instance_double(Reporter)
      allow(Reporter).to receive(:new).and_return(reporter)
      allow(reporter).to receive(:projects_to_users_matrix).with(user, :week).and_return('summary text')

      command.call

      expect(controller).to have_received(:respond_with).with(:message, text: '```code```', parse_mode: :Markdown)
    end

    it 'generates monthly summary when period is month' do
      reporter = instance_double(Reporter)
      allow(Reporter).to receive(:new).and_return(reporter)
      allow(reporter).to receive(:projects_to_users_matrix).with(user, :month).and_return('summary text')

      command.call('month')

      expect(controller).to have_received(:respond_with).with(:message, text: '```code```', parse_mode: :Markdown)
    end
  end
end
