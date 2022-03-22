require 'httpi'

module HTTPI; end
module HTTPI::Adapter; end
class HTTPI::Adapter::MTLibuv < HTTPI::Adapter::Base
    register :mtlibuv, deps: %w(mt-uv-rays)

    def initialize(request)
        @request = request
        @client = ::MTUV::HttpEndpoint.new request.url
    end

    attr_reader :client

    def request(method)
        @client.inactivity_timeout = (@request.read_timeout * 1000).to_i if @request.read_timeout && @request.read_timeout > 0

        req = {
            path: @request.url,
            headers: @request.headers,
            body: @request.body
        }

        if proxy = @request.proxy
            req[:proxy] = {
                host: proxy.host,
                port: proxy.port,
                username: proxy.user,
                password: proxy.password
            }
        end

        # Apply authentication settings
        auth = @request.auth
        type = auth.type
        if auth.type
            creds = auth.credentials

            case auth.type
            when :basic
                req[:headers][:Authorization] = creds
            when :digest
                req[:digest] = {
                    user: creds[0],
                    password: creds[1]
                }
            when :ntlm
                req[:ntlm] = {
                    username: creds[0],
                    password: creds[1],
                    domain: creds[2] || ''
                }
            end
        end

        # Apply Client certificates
        ssl = auth.ssl
        if ssl.verify_mode == :peer
            tls_opts = req[:tls_options] = {}
            tls_opts[:cert_chain]  = ssl.cert.to_pem     if ssl.cert
            tls_opts[:client_ca]   = ssl.ca_cert_file    if ssl.ca_cert_file
            tls_opts[:private_key] = ssl.cert_key.to_pem if ssl.cert_key
        end

        # Use co-routines to make non-blocking requests
        response = @client.request(method, req).value
        ::HTTPI::Response.new(response.status, response, response.body)
    end
end
