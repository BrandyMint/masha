# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::VersionCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }

  before do
    allow(controller).to receive(:respond_with)
    stub_const('AppVersion', '1.0.0')
  end

  describe '#call' do
    it 'responds with app version' do
      command.call

      expect(controller).to have_received(:respond_with).with(:message, text: 'Версия Маши: 1.0.0')
    end
  end
end
