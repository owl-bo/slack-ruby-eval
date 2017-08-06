require 'bundler'
Bundler.require

module SlackBot
  ROOT_PATH = File.expand_path(File.dirname(__FILE__))
  CONFIG = Hashie::Mash.new YAML.load ERB.new( File.read File.join(ROOT_PATH, 'config.yml') ).result
  MAX_POST_LENGTH = CONFIG.slack.max_message_length

  class Responser
    def initialize
      log_path = File.join(ROOT_PATH, '/log/')
      log_name = File.join(log_path, "#{self.class.name}.log")
      FileUtils.mkdir_p(log_path) unless FileTest.exist?(log_path)
      @logger = Logger.new(log_name, 3)
    end

    def run
      response = HTTP.post(CONFIG.slack.api_url.realtime_start, params: {token: CONFIG.slack.token})
      url = JSON.parse(response.body)['url']
      @logger.info '=== Start Bot'
      EM.run do
        @ws = Faye::WebSocket::Client.new(url)
        @ws.on :message do |event|
          data = JSON.parse(event.data)
          process_event(data)
        end

        @ws.on :close do |event|
          @logger.info "===Close Bot - CODE: #{event.code}".join
          @ws = nil
          EM.stop
        end
      end
    end

    def process_event(data)
      # To override this method.
      @logger.info data.inspect
    end

    def download_snippet(url)
      uri = URI.parse(url)
      response = nil
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = 'Bearer ' + CONFIG.slack.token
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.start { |h| response = h.request(request) }
      code = response.body.force_encoding('UTF-8')
      file_path = File.join('/tmp/', File.basename(url) )
      File.open(file_path, "w") { |f| f.puts(code) }
      @logger.info "Download snippet."
      @logger.info "  url: #{url}"
      @logger.info "  #{response.inspect}"
      @logger.info "  #{file_path}"
      file_path
    end
  end
end
