#!/usr/bin/env ruby

this_dir = File.expand_path(File.dirname(__FILE__))
services_dir = File.join(File.dirname(this_dir), 'proto_services')
types_dir = File.join(File.dirname(this_dir), 'proto_types')
$LOAD_PATH.unshift(types_dir) unless $LOAD_PATH.include?(types_dir)
$LOAD_PATH.unshift(services_dir) unless $LOAD_PATH.include?(services_dir)
$LOAD_PATH.unshift(this_dir) unless $LOAD_PATH.include?(this_dir)

require 'base64'
require 'logger'
require 'faraday'
require 'faraday/net_http'
require 'proto_services/travel_time_service'

APP_ID = ENV['APP_ID']
API_KEY = ENV['API_KEY']

host = 'https://proto.api.traveltimeapp.com'

conn = Faraday.new(host) do |f|
  f.headers['Content-Type'] = 'application/octet-stream'
  f.request :authorization, :basic, APP_ID, API_KEY
  f.adapter :net_http
end

message = Traveltime::Requests::TimeFilterFastRequest.new(
  oneToManyRequest: Traveltime::Requests::TimeFilterFastRequest::OneToMany.new(
    departureLocation: Traveltime::Requests::Coords.new(lat: 51, lng: -0.12), # :message, 1, "com.igeolise.traveltime.rabbitmq.requests.Coords"
    # locationDeltas: , # :sint32, 2
    transportation: Traveltime::Requests::Transportation.new(
      type: Traveltime::Requests::TransportationType::DRIVING_AND_FERRY
    ), # :message, 3, "com.igeolise.traveltime.rabbitmq.requests.Transportation"
    # arrivalTimePeriod: , # :enum, 4, "com.igeolise.traveltime.rabbitmq.requests.TimePeriod"
    travelTime: 5, # :sint32, 5
    properties: [Traveltime::Requests::TimeFilterFastRequest::Property::DISTANCES] # :enum, 6, "com.igeolise.traveltime.rabbitmq.requests.TimeFilterFastRequest.Property"
  )
)

begin
  puts message.to_json
  @resp = conn.post('api/v2/uk/time-filter/fast/driving+ferry', message.to_proto)
  puts @resp.inspect
  puts Traveltime::Responses::TimeFilterFastResponse.decode(@resp.body).inspect
rescue => @e
  require 'irb'
  IRB.start(__FILE__)
end

