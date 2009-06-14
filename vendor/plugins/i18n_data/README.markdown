Problem
=======
 - Present users coutries/languages in their language
 - Convert a country/language-name to its code

Solution
========
 - A list of 2-letter-code/name pairs for all countries/languages in all languages
 - A tool to convert a coutry/language name into 2-letter-code
 - Write countries/language into a cache-file, and use this file for production applications languages/countries list

Containing
==========
Translations through [pkg-isocodes](http://svn.debian.org/wsvn/pkg-isocodes/trunk/iso-codes/)  
185 Language codes (iso 639 - 2 letter)  
in 66 Languages  
246 Country codes (iso 3166 - 2 letter)  
in 85 Languages  

Usage
=====

    sudo gem install grosser-i18n_data
    require 'i18n_data'
    ...
    I18nData.languages        # {"DE"=>"German",...}
    I18nData.languages('DE')  # {"DE"=>"Deutsch",...}
    I18nData.languages('FR')  # {"DE"=>"Allemand",...}
    ...

    I18nData.countries        # {"DE"=>"Germany",...}
    I18nData.countries('DE')  # {"DE"=>"Deutschland",...}
    ...

    #Not yet implemented...
    I18nData.language_code('German')       # DE
    I18nData.language_code('Deutsch')      # DE
    I18nData.language_code('Allemand')     # DE
    ..

    I18nData.country_code('Germany')       # DE
    I18nData.country_code('Deutschland')   # DE
    ..

Data Providers
==============
 - FileDataProvider: _FAST_ (default) (loading data from cache-files)
 - LiveDataProvider: _SLOW_ (fetching up-to-date data from svn repos)

TODO
====
 - include other language/country code formats (3-letter codes...) ?
 
Author
======
Michael Grosser  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...  