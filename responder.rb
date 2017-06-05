require 'timeout'

class BotStrategy
  attr_reader :responder, :was_asked

  def initialize(responder)
    @responder = responder
  end

  def done?
    @done
  end

  def done!
    @done = true
  end

  def waiting_response?
    !@done
  end

  def chat
    msg.chat
  end

  def was_asked?
    @was_asked
  end

  def handle!
    return if done?
    if was_asked?
      handle_response
    else
      ask!
      @was_asked = true
    end
  end

  def reply(text, markdown = nil)
    responder.reply(text, markdown)
  end

  def ask!
    fail NotImplementedError
  end

  def handle_response!
    fail NotImplementedError
  end


  def with_keyboard(answers)
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: answers, one_time_keyboard: true)
  end

  def yes_words
    %w(Так так Да да Ага ага Угу угу)
  end

  def no_words
    %w(Ні ні Нет нет Не не Нi нi)
  end

  def remove_kb_markup
    responder.remove_kb_markup
  end

  def yes?
    yes_words.include? text
  end

  def no?
    no_words.include? text
  end

  def msg
    responder.msg
  end

  def text
    msg.text.strip
  end
end

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

class Responder
  attr_reader :bot, :msg, :chat_id
  attr_accessor :address, :problem_text

  def initialize(bot, msg)
    @bot = bot
    @msg = msg
    @chat_id = msg.chat.id
  end

  def self.find_or_create(bot, msg)
    responder = $responders.detect { |i| i.chat_id == msg.chat.id }
    if responder
      responder.msg = msg
      return responder
    end
    responder = Responder.new(bot, msg)
    $responders << responder
    responder
  end

  def strategies
    [HelloSayer, DescriptionAsker, PhotoAsker, LocationAsker, AddressAsker, PhoneAsker]
  end

  def strategy_objs
    @strategy_objs ||= strategies.map do |i|
      i.new(self)
    end
  end

  def contact
    msg.contact ? @contact = msg.contact : @contact
  end

  def location
    msg.location ? @location = msg.location : @location
  end

  def photo_path
    return @photo_path if @photo_path
    return unless msg.photo
    begin
      res = HTTParty.get("https://api.telegram.org/bot#{BOT_TOKEN}/getFile?file_id=#{msg.photo&.last&.file_id}")
      file_path = JSON.parse(res.body)["result"]["file_path"]

      @photo_path ||= "https://api.telegram.org/file/bot#{BOT_TOKEN}/#{file_path}"
    rescue
      nil
    end
  end

  def handle!
    strategy_objs.each do |i|
      i.handle!
      return if i.waiting_response?
    end

    reply("Дякую! Я подав заяву для вирішення Вашої проблеми. Буду тримати Вас у курсі!", remove_kb_markup)

    opts = {chat_id: chat_id,
            photo_path: photo_path,
            state: 'Waiting Moderation',
            description: problem_text,
            address: address}
    contact.to_h.each do |k,v|
      opts[("author_" + k.to_s).to_sym] = v
    end
    location.to_h.each do |k,v|
      opts[("location_" + k.to_s).to_sym] = v
    end
    opts[:created_at] = opts[:updated_at] = Time.now.to_i
    Timeout::timeout(5) do
      HTTParty.post("http://localhost:3000/issues", body: opts)
    end

    instance_variables.each do |i|
      instance_variable_set(i, nil)
    end
  end

  def reply(text, markup = nil)
    opts = {chat_id: msg.chat.id, text: text}
    opts[:reply_markup] = markup if markup
    bot.api.send_message(opts)
  end

  def remove_kb_markup
    Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
  end
end
