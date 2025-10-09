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

    # Create membership so user has access to project
    create(:membership, user: user, project: project)
  end

  describe '#call' do
    context 'when user has time shifts' do
      it 'shows list of time shifts' do
        command.call

        expect(controller).to have_received(:save_context).with(:edit_select_time_shift_input)
        expect(controller).to have_received(:respond_with).with(
          :message,
          hash_including(
            text: include('Последние 50 записей'),
            parse_mode: :Markdown
          )
        )
      end
    end

    context 'when user has no time shifts' do
      before do
        time_shift.destroy
      end

      it 'shows empty message' do
        command.call

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: 'У вас нет записей времени для редактирования'
        )
        expect(controller).not_to have_received(:save_context)
      end
    end

    context 'when time shift has long description' do
      let!(:long_description_shift) do
        create(:time_shift, user: user, project: project, description: 'A' * 50)
      end

      it 'truncates description in table' do
        command.call

        expect(controller).to have_received(:respond_with) do |_type, options|
          expect(options[:text]).to include('...')
        end
      end
    end
  end
end
