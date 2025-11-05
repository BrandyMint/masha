# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PeriodParser do
  describe '.parse' do
    context 'when arg is nil' do
      it 'returns default week period' do
        expect(described_class.parse(nil)).to eq('week')
      end
    end

    context 'relative periods' do
      it 'parses supported relative periods' do
        expect(described_class.parse('day')).to eq('day')
        expect(described_class.parse('week')).to eq('week')
        expect(described_class.parse('month')).to eq('month')
        expect(described_class.parse('last_month')).to eq('last_month')
        expect(described_class.parse('last_week')).to eq('last_week')
        expect(described_class.parse('last_day')).to eq('last_day')
      end
    end

    context 'date formats' do
      it 'parses specific date' do
        result = described_class.parse('2024-11-05')
        expect(result[:type]).to eq(:date)
        expect(result[:date]).to eq(Date.parse('2024-11-05'))
      end

      it 'parses month format' do
        result = described_class.parse('2024-11')
        expect(result[:type]).to eq(:month)
        expect(result[:date]).to eq(Date.parse('2024-11-01'))
      end

      it 'raises error for invalid date' do
        expect { described_class.parse('2024-13-01') }
          .to raise_error(ArgumentError, 'Invalid date format: invalid date')
      end

      it 'raises error for invalid month' do
        expect { described_class.parse('2024-13') }
          .to raise_error(ArgumentError, 'Invalid date format: invalid date')
      end
    end

    context 'date ranges' do
      it 'parses date range' do
        result = described_class.parse('2024-11-01..2024-11-05')
        expect(result[:type]).to eq(:range)
        expect(result[:start_date]).to eq(Date.parse('2024-11-01'))
        expect(result[:end_date]).to eq(Date.parse('2024-11-05'))
      end

      it 'parses month range' do
        result = described_class.parse('2024-10..2024-11')
        expect(result[:type]).to eq(:month_range)
        expect(result[:start_date]).to eq(Date.parse('2024-10-01'))
        expect(result[:end_date]).to eq(Date.parse('2024-11-01'))
      end
    end

    context 'validation' do
      it 'raises error when start date is after end date' do
        expect { described_class.parse('2024-11-05..2024-11-01') }
          .to raise_error(ArgumentError, 'Start date cannot be after end date')
      end

      it 'raises error for period exceeding 365 days' do
        expect { described_class.parse('2024-01-01..2025-01-02') }
          .to raise_error(ArgumentError, 'Period cannot exceed 365 days')
      end

      it 'raises error for data older than 2 years' do
        old_date = (Date.today - 800).strftime('%Y-%m-%d') # ~2.2 years
        expect { described_class.parse(old_date) }
          .to raise_error(ArgumentError, 'Data older than 2 years is not available')
      end
    end

    context 'invalid formats' do
      it 'raises error for unsupported format' do
        expect { described_class.parse('invalid') }
          .to raise_error(ArgumentError, 'Invalid period format')
      end

      it 'raises error for malformed date' do
        expect { described_class.parse('2024/11/05') }
          .to raise_error(ArgumentError, 'Invalid period format')
      end

      it 'raises error for malformed range' do
        expect { described_class.parse('2024-11-01-2024-11-05') }
          .to raise_error(ArgumentError, 'Invalid period format')
      end
    end
  end
end
