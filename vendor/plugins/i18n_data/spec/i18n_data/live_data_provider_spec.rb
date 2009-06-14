require File.join(File.dirname(__FILE__),'..',"spec_helper")
require 'i18n_data/live_data_provider'

describe I18nData::LiveDataProvider do
  describe :po_to_hash do
    def po_to_hash(text)
      I18nData::LiveDataProvider.send(:po_to_hash,text)
    end
    it "parses po file into translations" do
      text = <<EOF
# come comment msgstr
msgid "one"
msgstr "1"
EOF
      po_to_hash(text).should == {"one"=>"1"}
    end
    it "keeps order of translations" do
      text = <<EOF
msgid "one"
msgstr "1"
msgid "two"
msgstr ""
msgid "three"
msgstr "3"
EOF
      po_to_hash(text).should == {"one"=>"1","two"=>"","three"=>"3"}
    end
    pending_it "finds x-line long translations" do
      text = <<EOF
#. name for chu, cu
msgid ""
"Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church "
"Slavonic"
msgstr "Kirchenslavisch"
EOF
      long_name = "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic"
      po_to_hash(text)[long_name].should == "Kirchenslavisch"
    end
  end
end