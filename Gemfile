source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# Auth & authz
gem "devise"
gem "devise-two-factor"
gem "rqrcode"         # Inline SVG QR codes for 2FA setup (no external API)
gem "pundit"

# State machine
gem "state_machines-activerecord"

# Audit
gem "paper_trail"

# Integração externa (Sankhya)
gem "faraday"
gem "faraday-retry"
gem "oauth2"
gem "stoplight"

# Exports Lei do Bem
gem "caxlsx"
gem "caxlsx_rails"
gem "caracal"
gem "caracal-rails"
gem "prawn"
gem "prawn-table"

# JSON Schema validation (FORMP&D)
gem "json-schema"

# Paginação
gem "pagy"

# CSV export (extracted from stdlib in Ruby 3.4)
gem "csv"

# Markdown em comentários
gem "redcarpet"

# Inline CSS em e-mails
gem "premailer-rails"

# Active Storage + processamento de imagens
gem "image_processing", "~> 1.2"

gem "tzinfo-data", platforms: %i[windows jruby]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-byebug"
  gem "bullet"
  gem "capybara"
  gem "selenium-webdriver"
  gem "vcr"
  gem "webmock"
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-performance", require: false
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "simplecov", require: false
  gem "erb_lint", require: false
  gem "shoulda-matchers"
end

group :development do
  gem "web-console"
  gem "dotenv-rails"
end
