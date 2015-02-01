# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( index.js browse.js welcome.js fixthemap.js )
Rails.application.config.assets.precompile += %w( user.js diary_entry.js )
Rails.application.config.assets.precompile += %w( large-ltr.css small-ltr.css print-ltr.css )
Rails.application.config.assets.precompile += %w( large-rtl.css small-rtl.css print-rtl.css )
Rails.application.config.assets.precompile += %w( leaflet-all.css leaflet.ie.css )
Rails.application.config.assets.precompile += %w( embed.js embed.css )
Rails.application.config.assets.precompile += %w( html5shiv.js )
Rails.application.config.assets.precompile += %w( images/marker-*.png img/*-handle.png )
Rails.application.config.assets.precompile += %w( swfobject.js expressInstall.swf )
Rails.application.config.assets.precompile += %w( potlatch2.swf )
Rails.application.config.assets.precompile += %w( potlatch2/assets.zip )
Rails.application.config.assets.precompile += %w( potlatch2/FontLibrary.swf )
Rails.application.config.assets.precompile += %w( potlatch2/locales/*.swf )
Rails.application.config.assets.precompile += %w( help/introduction.* )
Rails.application.config.assets.precompile += %w( iD.js iD.css )
Rails.application.config.assets.precompile += %w( iD/img/*.svg iD/img/*.png iD/img/*.gif )
Rails.application.config.assets.precompile += %w( iD/img/pattern/*.png )
Rails.application.config.assets.precompile += %w( iD/locales/*.json )
