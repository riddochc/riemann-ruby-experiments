module Riemann::Experiment
  class Client < Net::TCPClient
    attr_reader :keepalive_active, :keepalive_idle, :keepalive_interval, :keepalive_count
    attr_accessor :host

    # service and host can be assigned to :default here,
    # to use a string generated from process info and hostname, respectively.
    def initialize(options = {})
      @event_fields = Set.new([:time, :service, :host, :description, :metric, :tags, :ttl])
      @msg_fields = Set.new([:ok, :error, :states, :query, :events])
      @localhost = Socket.gethostname
      @generated_service = "#{$0};#{$PID}"

      default_opts = {server: "localhost:5555",
                      connect_timeout: 2,
                      read_timeout: 2,
                      write_timeout: 2 }

      # default_event_fields, other_options = options.each.partition {|o| event_fields.include?(o) }
      @service = options.delete(:service)
      @host = options.delete(:host)
      @tags = options.delete(:tags) || []

      @keepalive_active = options.delete(:keepalive_active) || true
      @keepalive_idle   = options.delete(:keepalive_idle) || 60
      @keepalive_interval = options.delete(:keepalive_interval) || 30
      @keepalive_count = options.delete(:keepalive_count) || 5

      options.merge!(default_opts)
      options.delete(:buffered)
      options[:buffered] = false
      super(options)
      setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_KEEPALIVE,  @keepalive_active)
      setsockopt(::Socket::SOL_TCP,    ::Socket::TCP_KEEPIDLE , @keepalive_idle)
      setsockopt(::Socket::SOL_TCP,    ::Socket::TCP_KEEPINTVL, @keepalive_interval)
      setsockopt(::Socket::SOL_TCP,    ::Socket::TCP_KEEPCNT  , @keepalive_count)
    end

    def send_event(fields = {})
      evkeys = Set.new(fields.keys)

      e = Event.new

      if evkeys.include?(:time)
        e.time = fields[:time].to_i
      else
        e.time = Time.now.to_i
      end

      if evkeys.include?(:service)
        e.service = fields[:service].to_s
      elsif @service
        if @service != :default
          e.service = @service
        else
          e.service = @generated_service
        end
      end

      if evkeys.include?(:host)
        e.host = fields[:host].to_s
      elsif @host
        if @host != :default
          e.host = @host
        else
          e.host = @localhost
        end
      end

      if evkeys.include?(:description)
        e.description = fields[:description].to_s
      end

      if evkeys.include?(:tags) or @tags.length > 0
        e.tags = fields[:tags].to_a + @tags.to_a
      end

      if evkeys.include?(:ttl) or @ttl
        e.ttl = fields[:ttl] || @ttl
      end

      case fields[:metric]
      when Integer
        e.metric_sint64 = fields[:metric]
      when Float
        e.metric_d = fields[:metric]
      end  # BigDecimal? Anything else?

      e.attributes = (evkeys - @event_fields - @msg_fields).to_a.map {|k|
          a = Attribute.new
          a.key, a.value = k.to_s, fields[k].to_s
          a
      }

      m = Msg.new
      if fields[:ok] == true
        m.ok = true
      elsif fields[:ok] == false
        m.ok = false
      end
      m.error = fields[:error].to_s if fields[:error]
      m.events << e
      exchange(m)
    end

    # Writes a riemann message to socket.
    # You probably want to use exchange, because it receives a 
    # response from 
    # yields to a block if the write times out (and re-raises the WriteTimeout)
    def put(message)
      msg = message.to_s
      out_packet = [msg.length].pack('N') + msg
      write(out_packet)
    rescue Net::TCPClient::WriteTimeout => e
      yield if block_given?
      raise e
    end

    # Receives a response from a riemann server.
    # This method will raise ProtocolBuffers::DecoderError on invalid data.
    # yields to a block if the read times out (and re-raises the ReadTimeout)
    def get()
      in_len = read(4).unpack("N").first
      in_packet = read(in_len)
      Msg.parse(in_packet)
    rescue Net::TCPClient::ReadTimeout => e
      yield if block_given?
      raise e
    end

    def exchange(message)
      retry_on_connection_failure do
        put(message)
        get
      end
    end
  end
end

