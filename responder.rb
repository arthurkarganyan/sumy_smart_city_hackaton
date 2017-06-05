class Responder
  attr_reader :bot, :msg, :chat_id
  attr_writer :msg # for find_or_create
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
    # Timeout::timeout(5) do
    #   HTTParty.post("http://localhost:3000/issues", body: opts)
    # end

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
