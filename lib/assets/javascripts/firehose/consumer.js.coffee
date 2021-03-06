class Firehose.Consumer
  # Transports that are available to Firehose.
  @transports: [Firehose.WebSocket, Firehose.LongPoll]

  constructor: (config = {}) ->
    # List of transport stragies we have to use.
    config.transports   ||= Firehose.Consumer.transports
    unless config.transports.length > 0
      throw 'You must provide at least one tranport for Firehose.Consumer'
    unless typeof config.uri is 'string'
      throw 'You must provide a Firehose server URI for Firehose.Consumer'
    # Empty handler for messages.
    config.message      ||= ->
    # Empty handler for error handling.
    config.error        ||= ->
    # Empty handler for when we establish a connection.
    config.connected    ||= ->
    # Empty handler for when we're disconnected.
    config.disconnected ||= ->
    # The initial connection failed. This is probably triggered when a
    # transport, like WebSockets is supported by the browser, but for whatever
    # reason it can't connect (probably a firewall)
    config.failed       ||= ->
      throw "Could not connect"
    # Params that we'll tack on to the URL.
    config.params       ||= {}
    # Do stuff before we send the message into config.message. The sensible
    # default on the webs is to parse JSON.
    config.parse        ||= JSON.parse
    # Hang on to these config for when we connect.
    @config = config
    # Make sure we return ourself out of the constructor so we can chain.
    this

  connect: (delay=0) =>
    # Get a list of transports that the browser supports
    supportedTransports = (t for t in @config.transports when t.supported())
    # Mmmkay, we've got transports supported by the browser, now lets try connecting
    # to them and dealing with failed connections that might be caused by firewalls,
    # or other network connectivity issues.
    transports = for transport in supportedTransports
      originalFailFun = @config.failed
      # Map the next transport into the existing transports connectionError
      # If the connection fails, try the next transport supported by the browser.
      @config.failed = =>
        # Map the next transport to connect inside of the current transport failures
        if nextTransportType = supportedTransports.pop()
          nextTransport = new nextTransportType @config
          nextTransport.connect delay
        else originalFailFun?()
      new transport(@config)
    # Fire off the first connection attempt.
    [firstTransport] = transports
    firstTransport.connect delay
