#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails db:migrate

# Package Chrome extension as a downloadable zip
cd chrome_extension && zip -r ../public/qlarity-extension.zip . && cd ..
