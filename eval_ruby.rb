require './bot_base.rb'

module SlackBot
  class RubyEvaler < Responser
    FORBIDDEN_CLASSES = %w(Dir IO File FileTest)

    class << self
      def start
        self.new.run
      end
    end

    def process_event(data)
      if is_ruby_snippet?(data)
        url = data['file']['url_private_download']
        file_path = download_snippet(url)
        channel = data['channel']
        eval_and_post_stdot(file_path, channel)
      end
    end

    def is_ruby_snippet?(data)
      data['subtype'] == 'file_share' && data['file']['filetype'] == 'ruby'
    end

    def eval_and_post_stdot(code_file_path, channel)
      begin
        output = get_eval_result(code_file_path)
        post_text = fetch_result_message(output)
        return if post_text.length > MAX_POST_LENGTH
        params = { type: 'message', text: post_text, channel: channel }.to_json
        @ws.send(params)
        @logger.info "Posted message =>"
        @logger.info params
      rescue => e
        @logger.error e.inspect
      end
    end

    def get_eval_result(code_file_path)
      SafeEvaler.safe_eval(code_file_path)
    end

    def fetch_result_message(output)
      message = ['*stdout:*']
      output_lines = output.split("\n")
      message << output_lines.first(10).map { |line| ">#{line}" }
      message << '>...' if output_lines.size > 10
      message.join("\n")
    end
  end
end

module SafeEvaler
  FORBIDDEN_CLASSES = %w(Dir IO File FileTest)
  class << self
    def safe_eval(code_file_path)
      code = File.open(code_file_path).read
      return 'forbidden' unless check_codes_safety(code)
      result = nil
      exec_time = 3
      thread_list = Thread.list
      timekeep = Thread.start(code) do |code_to_eval|
        code_to_eval = safe_code + code_to_eval
        result = capture(:stdout) { eval(code_to_eval) }
      end.join(exec_time)
      (Thread.list - thread_list).each {|th| th.kill}
      raise StandardError unless timekeep
      result
    end

    def safe_code
      codes = ['$SAFE = 1;']
      codes.join("\n")
    end

    def capture(stream)
      begin
        stream = stream.to_s
        eval "$#{stream} = StringIO.new"
        yield
        result = eval("$#{stream}").string
      ensure
        eval("$#{stream} = #{stream.upcase}")
      end
      result
    end

    def check_codes_safety(code)
      FORBIDDEN_CLASSES.none? { |keyword| code.include?(keyword) }
    end
  end
end

SlackBot::RubyEvaler.start
