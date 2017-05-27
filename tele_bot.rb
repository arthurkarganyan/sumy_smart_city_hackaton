require 'bundler'
Bundler.require(:default)
require 'telegram/bot'
require_relative "responder.rb"

BOT_TOKEN = "353654051:AAGWb0BKYs8STk4AonC87cr5Z_zDURK9hzA"

$responders = []

Telegram::Bot::Client.run(BOT_TOKEN) do |bot|
  bot.listen do |message|
    Responder.find_or_create(bot, message).handle!
  end
end

