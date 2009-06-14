require File.expand_path("spec_helper", File.dirname(__FILE__))

NUM_2_LETTER_LANGUAGES = 185
NUM_COUNTRIES = 246

describe I18nData do
  require "i18n_data/live_data_provider"
  require "i18n_data/file_data_provider"
  [I18nData::LiveDataProvider,I18nData::FileDataProvider].each do |provider|
    describe "using #{provider}" do
      before :all do
        I18nData.data_provider = provider
      end
      describe :languages do
        it "raises NoTranslationAvailable for unavailable languages" do
          lambda{I18nData.languages('XX')}.should raise_error(I18nData::NoTranslationAvailable)
        end
        describe :english do
          it "does not contain blanks" do
            I18nData.languages.detect {|k,v| k.blank? or v.blank?}.should == nil
          end
          it "has english as default" do
            I18nData.languages['DE'].should == 'German'
          end
          it "contains all languages" do
            I18nData.languages.size.should == NUM_2_LETTER_LANGUAGES
          end
        end
        describe :translated do
          it "is translated" do
            I18nData.languages('DE')['DE'].should == 'Deutsch'
          end
          it "contains all languages" do
            I18nData.languages('DE').size.should == NUM_2_LETTER_LANGUAGES
          end
          it "has english names for not-translateable languages" do
            I18nData.languages('IS')['HA'].should == I18nData.languages['HA']
          end
          it "does not contain blanks" do
            I18nData.languages('GL').detect {|k,v| k.blank? or v.blank?}.should == nil
          end
          it "is written in unicode" do
            I18nData.languages('DE')['DA'].should == 'Dänisch'
          end
        end
      end
      describe :countries do
        describe :english do
          it "has english as default" do
            I18nData.countries['DE'].should == 'Germany'
          end
          it "does not contain blanks" do
            I18nData.countries.detect {|k,v| k.blank? or v.blank?}.should == nil
          end
          it "contains all countries" do
            I18nData.countries.size.should == NUM_COUNTRIES
          end
        end
        describe :translated do
          it "is translated" do
            I18nData.countries('DE')['DE'].should == 'Deutschland'
          end
          it "contains all countries" do
            I18nData.countries('DE').size.should == NUM_COUNTRIES
          end
          it "has english names for not-translateable countries" do
            I18nData.countries('IS')['PK'].should == I18nData.countries['PK']
          end
          it "does not contain blanks" do
            I18nData.countries('GL').detect {|k,v| k.blank? or v.blank?}.should == nil
          end
          it "is written in unicode" do
            I18nData.countries('DE')['DK'].should == 'Dänemark'
          end
        end
      end
    end
  end
end