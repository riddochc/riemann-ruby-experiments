module Riemann::Experiment
  class Client < Net::TCPClient
    attr_reader :keepalive_active, :keepalive_idle, :keepalive_interval, :keepalive_count
    attr_accessor :default_host, :default_service, :default_tags, :default_ttl, :pending_events

    # service and host can be assigned to :default here,
    # to use a string generated from process info and hostname, respectively.
    def initialize(options = {})
      @event_fields = Set.new([:time, :service, :host, :description, :metric, :tags, :ttl])
      @msg_fields = Set.new([:ok, :error, :states, :query, :events])
      @generated_service = "#{$0};#{$PID}"

      default_opts = {server: "localhost:5555",
                      connect_timeout: 2,
                      read_timeout: 2,
                      write_timeout: 2 }

      @default_service = options.delete(:service)
      @default_host = options.delete(:host) || Socket.gethostname
      @default_tags = options.delete(:tags)
      @default_ttl = options.delete(:ttl)
      @pending_events = []


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

    def add_event(*rest)
      e = Riemann::Experiment::Event.new(self)
      e.build(*rest)
      @pending_events.push(e)
    end

    def send_message(**p)
      m = ::Msg.new
      m.ok = p[:ok] if p.has_key?(:ok)
      m.error = p[:error] if p.has_key?(:error)
      m.query = p[:query] if p.has_key?(:query)
      @pending_events.each {|e|
        e.maybe_apply_defaults
        m.events << e.protobuf
      }
      exchange(m.to_s)
      @pending_events = []
      m
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

