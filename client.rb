#!/usr/bin/env ruby

# require 'gruf'
require 'base64'
require 'logger'

this_dir = File.expand_path(File.dirname(__FILE__))
services_dir = File.join(File.dirname(this_dir), 'proto_services')
types_dir = File.join(File.dirname(this_dir), 'proto_types')
$LOAD_PATH.unshift(types_dir) unless $LOAD_PATH.include?(types_dir)
$LOAD_PATH.unshift(services_dir) unless $LOAD_PATH.include?(services_dir)
$LOAD_PATH.unshift(this_dir) unless $LOAD_PATH.include?(this_dir)


require 'proto_services/travel_time_service'

include GRPC::Core::TimeConsts

ENV['GRPC_SSL_CIPHER_SUITES'] = 'HIGH+ECDSA'
# ENV['GRPC_TRACE'] = 'all'
ENV['GRPC_VERBOSITY'] = 'debug'

module StdoutLogger
  def logger
    LOGGER
  end

  LOGGER = Logger.new(STDOUT)
end

GRPC.extend(StdoutLogger)

APP_ID = ENV['APP_ID']
API_KEY = ENV['API_KEY']

channel_creds = GRPC::Core::ChannelCredentials.new()
basic_value = Base64.strict_encode64("#{APP_ID}:#{API_KEY}")
auth_proc = proc { { 'authorization' => "Basic #{basic_value}" } }
call_creds = GRPC::Core::CallCredentials.new(auth_proc)

host = 'proto.api.traveltimeapp.com'
opts = {
  # :creds => channel_creds.compose(call_creds),
  # channel_args: { GRPC::Core::Channel::SSL_TARGET => "https://#{host}" },
  timeout: INFINITE_FUTURE,
}

creds = :this_channel_is_insecure # channel_creds.compose(call_creds)

stub = Traveltime::Stub.new(host, channel_creds.compose(call_creds), **opts)

#client = GRPCWeb::Client.new("http://#{host}/api/v2/uk/time-filter/fast/driving", Traveltime::Service)
# client = Gruf::Client.new(
#   service: Traveltime::Service,
#   options: {
#     hostname: "http://#{host}/api/v2/uk/time-filter/fast/driving+ferry",
#     username: APP_ID,
#     password: API_KEY
#   }
# )

@req = Traveltime::Requests::TimeFilterFastRequest.new(
  oneToManyRequest: Traveltime::Requests::TimeFilterFastRequest::OneToMany.new(
    departureLocation: Traveltime::Requests::Coords.new(lat: 51, lng: 0), # :message, 1, "com.igeolise.traveltime.rabbitmq.requests.Coords"
    # locationDeltas: , # :sint32, 2
    transportation: Traveltime::Requests::Transportation.new(
      type: Traveltime::Requests::TransportationType::DRIVING_AND_FERRY
    ), # :message, 3, "com.igeolise.traveltime.rabbitmq.requests.Transportation"
    # arrivalTimePeriod: , # :enum, 4, "com.igeolise.traveltime.rabbitmq.requests.TimePeriod"
    # travelTime: , # :sint32, 5
    properties: [Traveltime::Requests::TimeFilterFastRequest::Property::DISTANCES] # :enum, 6, "com.igeolise.traveltime.rabbitmq.requests.TimeFilterFastRequest.Property"
  )
)
@resp = stub.send(:'driving+ferry', [@req])

begin
  @resp.each { |r| puts r.inspect }
rescue GRPC::Unimplemented => @e
  require 'irb'
  IRB.start(__FILE__)
end

