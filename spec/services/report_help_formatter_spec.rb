# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReportHelpFormatter do
  let(:formatter) { described_class.new }

  describe '#main_help' do
    subject(:help_text) { formatter.main_help }

    it 'returns help text as string' do
      expect(help_text).to be_a(String)
    end

    it 'includes title with emoji' do
      expect(help_text).to include('📊')
      expect(help_text).to include('/report')
    end

    it 'includes quick start section' do
      expect(help_text).to include('Быстрый старт')
      expect(help_text).to include('/report')
      expect(help_text).to include('week')
      expect(help_text).to include('month')
    end

    it 'includes periods section' do
      expect(help_text).to include('Периоды')
      expect(help_text).to include('today')
      expect(help_text).to include('yesterday')
    end

    it 'includes filters section' do
      expect(help_text).to include('Фильтры')
      expect(help_text).to include('project:')
      expect(help_text).to include('projects:')
    end

    it 'includes options section' do
      expect(help_text).to include('Опции')
      expect(help_text).to include('detailed')
    end

    it 'includes examples section' do
      expect(help_text).to include('Примеры')
    end
  end

  describe '#main_keyboard' do
    subject(:keyboard) { formatter.main_keyboard }

    it 'returns inline keyboard structure' do
      expect(keyboard).to be_a(Hash)
      expect(keyboard).to have_key(:inline_keyboard)
    end

    it 'has 4 navigation buttons' do
      buttons = keyboard[:inline_keyboard].flatten
      expect(buttons.count).to eq(4)
    end

    it 'contains periods button' do
      buttons = keyboard[:inline_keyboard].flatten
      periods_button = buttons.find { |b| b[:text].include?('Периоды') }

      expect(periods_button).not_to be_nil
      expect(periods_button[:callback_data]).to eq('report_periods:')
    end

    it 'contains filters button' do
      buttons = keyboard[:inline_keyboard].flatten
      filters_button = buttons.find { |b| b[:text].include?('Фильтры') }

      expect(filters_button).not_to be_nil
      expect(filters_button[:callback_data]).to eq('report_filters:')
    end

    it 'contains options button' do
      buttons = keyboard[:inline_keyboard].flatten
      options_button = buttons.find { |b| b[:text].include?('Опции') }

      expect(options_button).not_to be_nil
      expect(options_button[:callback_data]).to eq('report_options:')
    end

    it 'contains examples button' do
      buttons = keyboard[:inline_keyboard].flatten
      examples_button = buttons.find { |b| b[:text].include?('Примеры') }

      expect(examples_button).not_to be_nil
      expect(examples_button[:callback_data]).to eq('report_examples:')
    end
  end

  describe '#periods_help' do
    subject(:help_text) { formatter.periods_help }

    it 'returns help text as string' do
      expect(help_text).to be_a(String)
    end

    it 'includes section title' do
      expect(help_text).to include('Периоды отчетов')
    end

    it 'includes named periods' do
      expect(help_text).to include('today')
      expect(help_text).to include('yesterday')
      expect(help_text).to include('week')
      expect(help_text).to include('month')
      expect(help_text).to include('quarter')
    end

    it 'includes date formats' do
      expect(help_text).to include('2024-01-15')
      expect(help_text).to include(':')
    end

    it 'includes examples' do
      expect(help_text).to include('/report')
    end
  end

  describe '#filters_help' do
    subject(:help_text) { formatter.filters_help }

    it 'returns help text as string' do
      expect(help_text).to be_a(String)
    end

    it 'includes section title' do
      expect(help_text).to include('Фильтры')
    end

    it 'includes single project filter' do
      expect(help_text).to include('project:')
    end

    it 'includes multiple projects filter' do
      expect(help_text).to include('projects:')
    end

    it 'includes examples' do
      expect(help_text).to include('/report')
    end
  end

  describe '#options_help' do
    subject(:help_text) { formatter.options_help }

    it 'returns help text as string' do
      expect(help_text).to be_a(String)
    end

    it 'includes section title' do
      expect(help_text).to include('Опции')
    end

    it 'includes detailed option' do
      expect(help_text).to include('detailed')
    end

    it 'includes examples' do
      expect(help_text).to include('/report')
    end
  end

  describe '#examples_help' do
    subject(:help_text) { formatter.examples_help }

    it 'returns help text as string' do
      expect(help_text).to be_a(String)
    end

    it 'includes section title' do
      expect(help_text).to include('Примеры')
    end

    it 'includes multiple examples' do
      expect(help_text.scan(%r{/report}).count).to be >= 5
    end

    it 'includes varied examples' do
      expect(help_text).to include('week')
      expect(help_text).to include('month')
      expect(help_text).to include('project:')
      expect(help_text).to include('detailed')
    end
  end

  describe '#navigation_keyboard' do
    it 'returns keyboard with back button for periods section' do
      keyboard = formatter.navigation_keyboard('periods')
      buttons = keyboard[:inline_keyboard].flatten
      back_button = buttons.find { |b| b[:text].include?('Назад') }

      expect(back_button).not_to be_nil
      expect(back_button[:callback_data]).to eq('report_main:')
    end

    it 'returns keyboard with back button for filters section' do
      keyboard = formatter.navigation_keyboard('filters')
      buttons = keyboard[:inline_keyboard].flatten
      back_button = buttons.find { |b| b[:text].include?('Назад') }

      expect(back_button).not_to be_nil
    end

    it 'includes navigation to other sections' do
      keyboard = formatter.navigation_keyboard('periods')
      buttons = keyboard[:inline_keyboard].flatten

      expect(buttons.count).to be >= 2
    end
  end
end
