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
    msg&.text&.strip
  end
end
