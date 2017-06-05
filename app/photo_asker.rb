class PhotoAsker < BotStrategy
  def ask!
    reply('Додайте фото проблеми, будь ласка')
  end

  def handle_response
    if responder.photo_path
      reply('Дякую!')
      done!
    else
      reply('Не можу знайти фото. Додайте фото проблеми, будь ласка')
    end
  end
end
