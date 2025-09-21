# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::HelpCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }

  before do
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:help_message).and_return('help text')
  end

  describe '#call' do
    it 'responds with help message' do
      command.call

      expect(controller).to have_received(:respond_with).with(:message, text: 'help text')
    end
  end
end
