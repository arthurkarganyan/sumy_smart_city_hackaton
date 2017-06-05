class HelloSayer < BotStrategy
  def ask!
    reply('Доброго дня! Я - робот, який допомагає робити місто Суми краще завдяки Вам. Ви б хотiли розповісти про проблему?', remove_kb_markup)
    reply("Напишить 'Так' якщо це так", with_keyboard(%w(Так)))
  end

  def handle_response
    if yes?
      reply("Зрозумів", remove_kb_markup)
      done!
    else
      reply("Не зрозумів. Напишить 'Так' якщо це Ви б хотіли розповісти про проблему.")
    end
  end
end
