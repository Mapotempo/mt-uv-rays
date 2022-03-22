# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'handsoap'

module Handsoap
    module Http
        module Drivers
            class MTLibuvDriver < AbstractDriver
                def self.load!
                    require 'mt-uv-rays'
                end

                def send_http_request_async(request)
                    endp = ::UV::HttpEndpoint.new(request.url)

                    if request.username && request.password
                        request.headers['Authorization'] = [request.username, request.password]
                    end

                    req = endp.request(request.http_method, {
                        headers: request.headers,
                        body: request.body
                    })

                    deferred = ::Handsoap::Deferred.new
                    req.then do |resp|
                        # Downcase headers and convert values to arrays
                        headers = Hash[resp.map { |k, v| [k.to_s.downcase, Array(v)] }]
                        http_response = parse_http_part(headers, resp.body, resp.status)
                        deferred.trigger_callback http_response
                    end
                    req.catch do |err|
                        deferred.trigger_errback err
                    end
                    deferred
                end
            end
        end

        @@drivers[:libuv] = ::Handsoap::Http::Drivers::MTLibuvDriver
    end
end
