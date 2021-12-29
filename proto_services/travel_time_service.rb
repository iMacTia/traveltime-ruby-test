require 'grpc'
require 'proto_types/TimeFilterFastRequest_pb'
require 'proto_types/TimeFilterFastResponse_pb'

module Traveltime
  class Service
    include GRPC::GenericService

    self.marshal_class_method = :encode
    self.unmarshal_class_method = :decode
    self.service_name = 'api/v2/uk/time-filter/fast'

    rpc :'driving+ferry',
        stream(Traveltime::Requests::TimeFilterFastRequest),
        stream(Traveltime::Responses::TimeFilterFastResponse)
  end

  Stub = Service.rpc_stub_class
end
