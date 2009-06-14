require File.join(File.dirname(__FILE__),'..',"spec_helper")
require 'i18n_data/file_data_provider'

describe I18nData::FileDataProvider do
  before do
    `rm -f #{I18nData::FileDataProvider.send(:cache_for,"XX","YY")}`
  end

  def read(x,y)
    I18nData::FileDataProvider.codes(x,y)
  end

  it "preserves data when writing and then reading" do
    data = {"x"=>"y","z"=>"w"}
    I18nData::FileDataProvider.send(:write_to_file,data,"XX","YY")
    read("XX","YY").should == data
  end

  it "does not write empty data sets" do
    I18nData::FileDataProvider.send(:write_to_file,{},"XX","YY")
    lambda{read("XX","YY")}.should raise_error I18nData::NoTranslationAvailable
  end
end