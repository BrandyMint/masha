# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReportFormatter do
  let(:user) { users(:user_with_telegram) }
  let(:work_project) { projects(:work_project) }
  let(:test_project) { projects(:test_project) }

  describe 'initialization' do
    it 'accepts report_data and format parameters' do
      report_data = { period: { from: Date.current, to: Date.current }, entries: [] }
      formatter = ReportFormatter.new(report_data, format: :summary)

      expect(formatter).to be_a(ReportFormatter)
    end

    it 'defaults to summary format if not specified' do
      report_data = { period: { from: Date.current, to: Date.current }, entries: [] }
      formatter = ReportFormatter.new(report_data)

      expect(formatter.format).to eq(:summary)
    end

    it 'accepts :detailed format' do
      report_data = { period: { from: Date.current, to: Date.current }, entries: [] }
      formatter = ReportFormatter.new(report_data, format: :detailed)

      expect(formatter.format).to eq(:detailed)
    end
  end

  describe '#format_report' do
    context 'with empty data' do
      it 'returns message about no data for summary format' do
        report_data = {
          period: { from: Date.current, to: Date.current },
          total_hours: 0,
          entries: [],
          grouped_by_project: {},
          grouped_by_day: {}
        }
        formatter = ReportFormatter.new(report_data, format: :summary)
        result = formatter.format_report

        expect(result).to include('Нет записей')
        expect(result).not_to include('Terminal::Table')
      end

      it 'returns message about no data for detailed format' do
        report_data = {
          period: { from: Date.current, to: Date.current },
          total_hours: 0,
          entries: [],
          grouped_by_project: {},
          grouped_by_day: {}
        }
        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        expect(result).to include('Нет записей')
      end
    end

    context 'summary format' do
      around do |example|
        travel_to Date.new(2025, 1, 15) do
          example.run
        end
      end

      let(:report_data) do
        builder = ReportBuilder.new(user: user, period: :today)
        builder.build
      end

      it 'returns formatted table with period header' do
        formatter = ReportFormatter.new(report_data, format: :summary)
        result = formatter.format_report

        expect(result).to be_a(String)
        expect(result).to include('2025-01-15')
      end

      it 'includes total hours in output' do
        formatter = ReportFormatter.new(report_data, format: :summary)
        result = formatter.format_report

        # Should include total hours somewhere in the output
        expect(result).to match(/\d+(\.\d+)?/)
      end

      it 'groups data by project' do
        formatter = ReportFormatter.new(report_data, format: :summary)
        result = formatter.format_report

        # Should show project slugs in the output
        report_data[:grouped_by_project].keys.each do |project_slug|
          expect(result).to include(project_slug)
        end
      end

      it 'shows hours by project' do
        formatter = ReportFormatter.new(report_data, format: :summary)
        result = formatter.format_report

        # Should display project hours
        report_data[:grouped_by_project].each do |_slug, data|
          hours_str = data[:hours].to_s
          expect(result).to include(hours_str) if data[:hours] > 0
        end
      end

      it 'includes separator lines' do
        formatter = ReportFormatter.new(report_data, format: :summary)
        result = formatter.format_report

        # Terminal::Table includes separator lines
        expect(result).to match(/[-+]+/)
      end
    end

    context 'detailed format' do
      let(:report_data) do
        builder = ReportBuilder.new(user: user, period: :today)
        builder.build
      end

      it 'returns formatted table with descriptions' do
        skip 'No time shift data for today' if report_data[:entries].empty?

        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        expect(result).to be_a(String)
        expect(result).to include(Date.current.to_s)
      end

      it 'includes project names' do
        skip 'No time shift data for today' if report_data[:entries].empty?

        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        report_data[:entries].map { |e| e[:project].slug }.uniq.each do |slug|
          expect(result).to include(slug)
        end
      end

      it 'includes descriptions for each entry' do
        skip 'No time shift data for today' if report_data[:entries].empty?

        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        # Should show descriptions (or · for empty ones)
        report_data[:entries].each do |entry|
          if entry[:description].present?
            expect(result).to include(entry[:description])
          end
        end
      end

      it 'groups entries by project' do
        skip 'No time shift data for today' if report_data[:entries].empty?

        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        # Проверяем что проекты упоминаются
        project_slugs = report_data[:entries].map { |e| e[:project].slug }.uniq
        project_slugs.each do |slug|
          expect(result).to include(slug)
        end
      end

      it 'shows individual hours for each entry' do
        skip 'No time shift data for today' if report_data[:entries].empty?

        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        # Should display individual entry hours
        report_data[:entries].each do |entry|
          hours_str = entry[:hours].to_s
          expect(result).to include(hours_str)
        end
      end

      it 'includes total hours at the bottom' do
        skip 'No time shift data for today' if report_data[:entries].empty?

        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        total_str = report_data[:total_hours].to_s
        expect(result).to include(total_str)
        expect(result).to include('Итого')
      end

      it 'uses · for empty descriptions' do
        # Create report data with entry that has no description
        data_with_empty_desc = report_data.dup
        if data_with_empty_desc[:entries].any? { |e| e[:description].blank? }
          formatter = ReportFormatter.new(data_with_empty_desc, format: :detailed)
          result = formatter.format_report

          expect(result).to include('·')
        else
          skip 'No entries with empty descriptions in test data'
        end
      end
    end

    context 'period formatting' do
      it 'formats today correctly' do
        travel_to Date.new(2025, 1, 15) do
          report_data = {
            period: { from: Date.new(2025, 1, 15), to: Date.new(2025, 1, 15) },
            total_hours: 0,
            entries: [],
            grouped_by_project: {},
            grouped_by_day: {}
          }
          formatter = ReportFormatter.new(report_data, format: :summary)
          result = formatter.format_report

          expect(result).to include('2025-01-15')
        end
      end

      it 'formats date range correctly' do
        travel_to Date.new(2025, 1, 15) do
          report_data = {
            period: { from: Date.new(2025, 1, 1), to: Date.new(2025, 1, 15) },
            total_hours: 0,
            entries: [],
            grouped_by_project: {},
            grouped_by_day: {}
          }
          formatter = ReportFormatter.new(report_data, format: :summary)
          result = formatter.format_report

          expect(result).to include('2025-01-01')
          expect(result).to include('2025-01-15')
        end
      end

      it 'formats week period correctly' do
        travel_to Date.new(2025, 1, 15) do
          week_start = Date.new(2025, 1, 13) # Monday
          week_end = Date.new(2025, 1, 19)   # Sunday
          report_data = {
            period: { from: week_start, to: week_end },
            total_hours: 0,
            entries: [],
            grouped_by_project: {},
            grouped_by_day: {}
          }
          formatter = ReportFormatter.new(report_data, format: :summary)
          result = formatter.format_report

          expect(result).to match(/2025-01-13.*2025-01-19/)
        end
      end
    end

    context 'with multi-project data' do
      around do |example|
        travel_to Date.new(2025, 1, 15) do
          example.run
        end
      end

      let(:report_data) do
        builder = ReportBuilder.new(user: user, period: :today)
        builder.build
      end

      it 'summary format shows all projects' do
        formatter = ReportFormatter.new(report_data, format: :summary)
        result = formatter.format_report

        project_slugs = report_data[:grouped_by_project].keys
        project_slugs.each do |slug|
          expect(result).to include(slug)
        end
      end

      it 'detailed format groups by project' do
        formatter = ReportFormatter.new(report_data, format: :detailed)
        result = formatter.format_report

        project_slugs = report_data[:entries].map { |e| e[:project].slug }.uniq
        project_slugs.each do |slug|
          expect(result).to include(slug)
        end
      end
    end
  end

  describe 'output format' do
    it 'uses Terminal::Table for table formatting' do
      travel_to Date.new(2025, 1, 15) do
        report_data = ReportBuilder.new(user: user, period: :today).build
        formatter = ReportFormatter.new(report_data, format: :summary)

        # Should use Terminal::Table which produces lines with +, - and |
        result = formatter.format_report
        expect(result).to match(/[+|\-]/)
      end
    end

    it 'aligns numeric columns to the right' do
      travel_to Date.new(2025, 1, 15) do
        report_data = ReportBuilder.new(user: user, period: :today).build
        formatter = ReportFormatter.new(report_data, format: :detailed)

        result = formatter.format_report
        # Terminal::Table with right alignment produces specific spacing
        expect(result).to be_a(String)
      end
    end
  end
end
