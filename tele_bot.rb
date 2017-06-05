require 'bundler'
Bundler.require(:default)
require 'telegram/bot'
require 'timeout'

require_relative "responder.rb"
require_relative "app/bot_strategy.rb"
require_relative "app/address_asker.rb"
require_relative "app/description_asker.rb"
require_relative "app/hello_sayer.rb"
require_relative "app/location_asker.rb"
require_relative "app/phone_asker.rb"
require_relative "app/photo_asker.rb"

BOT_TOKEN = "353654051:AAGWb0BKYs8STk4AonC87cr5Z_zDURK9hzA"

$responders = []

Telegram::Bot::Client.run(BOT_TOKEN) do |bot|
  bot.listen do |message|
    Responder.find_or_create(bot, message).handle!
  end
end

