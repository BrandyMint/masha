# frozen_string_literal: true

# Shared example для тестирования callback query обработчиков
# Проверяет, что метод корректно вызывает answerCallbackQuery

RSpec.shared_examples 'callback query handler' do
  it 'answers callback query' do
    expect { subject }.to make_telegram_request(bot, :answerCallbackQuery)
  end
end

# Shared example для тестирования callback query с конкретным текстом
RSpec.shared_examples 'callback query handler with text' do |expected_text|
  it 'answers callback query with expected text' do
    expect { subject }.to make_telegram_request(bot, :answerCallbackQuery) do |req|
      expect(req[:text]).to eq(expected_text) if expected_text
    end
  end
end

# Shared example для тестирования callback query с show_alert
RSpec.shared_examples 'callback query handler with alert' do |expected_text|
  it 'answers callback query with alert' do
    expect { subject }.to make_telegram_request(bot, :answerCallbackQuery) do |req|
      expect(req[:text]).to eq(expected_text) if expected_text
      expect(req[:show_alert]).to be true
    end
  end
end
