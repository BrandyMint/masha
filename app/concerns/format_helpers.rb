# frozen_string_literal: true

module FormatHelpers
  # Метод для объединения нескольких строк в одну с переносами
  def multiline(*args)
    args.flatten.map(&:to_s).join("\n")
  end

  # Метод для форматирования текста в блок кода
  def code(text)
    multiline '```', text, '```'
  end
end
