class LocationAsker < BotStrategy
  def ask!
    kb = [
        Telegram::Bot::Types::KeyboardButton.new(text: 'Відправити своє місцезнаходження', request_location: true),
        Telegram::Bot::Types::KeyboardButton.new(text: 'Я не можу це зробити')
    ]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    reply('Відправте своє місцезнаходження, будь ласка. Для більш точного місцезнаходження включіть геолокацію на телефоні.', markup)
  end

  def handle_response
    if responder.location
      reply("Дякую!", remove_kb_markup)
      done!
    elsif text == 'Я не можу це зробити'
      reply("Добре. Але можливо Ви знаєте адресу?", remove_kb_markup)
      done!
    else
      reply("Натисніть кнопку 'Відправити своє місцезнаходження' або 'Я не можу це зробити'")
    end
  end
end
