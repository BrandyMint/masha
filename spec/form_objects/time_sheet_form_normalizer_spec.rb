require 'spec_helper'

describe TimeSheetFormNormalizer do

  subject { described_class }

  describe "Нормализация формата даты" do

    context "Дата верного формата 'dd.mm.yyyy' и пользователь со 'нормальной' локалью" do

      let(:date) { "13-12-2014" }
      let(:normalized_date) { "2014-12-13" }
      let(:locale) { "ru-RU" }

      let(:result) { described_class.new({}).normalize_date( date, locale ) }

      it "приводится к формату yyyy.mm.dd" do
        expect(result).to eq(normalized_date)
      end

    end

    context "Дата формата 'mm.dd.yyyy' при пользователе со 'странной' локалью" do

      let(:date) { "12-17-2014" }
      let(:normalized_date){ "2014-12-17" }

      let(:strange_locale) { ["en-US","en_BZ","fil-PH","ar_SA","iu-Cans-CA"].shuffle.first }

      let(:result) { described_class.new({}).normalize_date(date, strange_locale) }

      it "приводится к формату yyyy.mm.dd" do
        expect(result).to eq(normalized_date)
      end

    end


    context "Дата неверного формата '290-13-17'" do

      let(:date) { "290-13-17" }

      let(:result) { described_class.new({}).normalize_date(date) }

      it "возвращается как есть" do
        expect(result).to eq(date)
      end

    end


  end

end