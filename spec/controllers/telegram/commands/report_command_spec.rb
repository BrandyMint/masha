# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::ReportCommand, type: :controller do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:code).and_return('```report```')
  end

  describe '#call' do
    let(:reporter) { instance_double(Reporter) }

    before do
      allow(Reporter).to receive(:new).and_return(reporter)
      allow(reporter).to receive(:list_by_days)
        .with(user, group_by: :user).and_return('user report')
      allow(reporter).to receive(:list_by_days)
        .with(user, group_by: :project).and_return('project report')
    end

    it 'generates detailed report' do
      command.call

      expect(controller).to have_received(:respond_with)
        .with(:message, text: '```report```', parse_mode: :Markdown)
    end
  end
end
