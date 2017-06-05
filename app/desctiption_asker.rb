class DescriptionAsker < BotStrategy
  def ask!
    reply("Опишіть Вашу проблему, будь ласка")
  end

  def handle_response
    if yes?
      if !responder.problem_text
        reply("Опишіть Вашу проблему, будь ласка")
      else
        reply("Дякую", remove_kb_markup)
        done!
      end
    elsif no?
      reply("Добре. Опишить ще раз Вашу проблему", remove_kb_markup)
    elsif text&.size < 10
      reply("Можете детальніше описати проблему?")
    else
      responder.problem_text = text
      reply("Ви написали '#{responder.problem_text}'. Відправляти так?", with_keyboard(%w(Так Нi)))
    end
  end
end
