class AddressAsker < BotStrategy
  def ask!
    reply("Яка адреса де є проблема? Хоча б приблизно. Якщо не знаєте, напишить 'Не знаю'", with_keyboard('Не знаю'))
  end

  def handle_response
    if yes?
      if !responder.address
        ask!
      else
        reply("Дякую", remove_kb_markup)
        done!
      end
    elsif no?
      reply("Добре", remove_kb_markup)
      ask!
    elsif text&.size < 5
      reply("Можете детальніше описати адресу?")
    elsif text == "Не знаю"
      reply("Добре. Дякую", remove_kb_markup)
      done!
    else
      responder.address = text
      reply("Ви написали '#{responder.address}'. Відправляти цю адресу?", with_keyboard(%w(Так Нi)))
    end
  end
end