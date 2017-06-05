class PhoneAsker < BotStrategy
  def ask!
    kb = [
      Telegram::Bot::Types::KeyboardButton.new(text: 'Відправити свій номер телефона', request_contact: true)
    ]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    reply('Відправте свої контактні данні, будь ласка', markup)
  end

  def handle_response
    if responder.contact
      reply("Дякую", remove_kb_markup)
      done!
    else
      reply("Натисніть кнопку 'Відправити свій номер телефона'")
    end
  end
end