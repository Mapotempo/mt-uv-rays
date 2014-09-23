require 'uv-rays'


module HttpServer
	def post_init
		@parser = ::HttpParser::Parser.new(self)
        @state = ::HttpParser::Parser.new_instance
        @state.type = :request
	end

	def on_message_complete(parser)
		write("HTTP/1.1 200 OK\r\nContent-type: text/html\r\nContent-length: 1\r\n\r\ny")
	end

	def on_read(data, connection)
		if @parser.parse(@state, data)
            p 'parse error'
            p @state.error
        end
	end
end

module OldServer
	def post_init
		@parser = ::HttpParser::Parser.new(self)
        @state = ::HttpParser::Parser.new_instance
        @state.type = :request
	end

	def on_message_complete(parser)
		write("HTTP/1.0 200 OK\r\nContent-type: text/html\r\nContent-length: 0\r\n\r\n")
	end

	def on_read(data, connection)
		if @parser.parse(@state, data)
            p 'parse error'
            p @state.error
        end
	end
end


describe UV::HttpEndpoint do
	before :each do
		@loop = Libuv::Loop.new
		@general_failure = []
		@timeout = @loop.timer do
			@loop.stop
			@general_failure << "test timed out"
		end
		@timeout.start(5000)

		@request_failure = proc { |err|
			@general_failure << err
			@loop.stop
		}
	end
	
	describe 'basic http request' do
		it "should send a request then receive a response" do
			@loop.run { |logger|
				logger.progress do |level, errorid, error|
					begin
						@general_failure << "Log called: #{level}: #{errorid}\n#{error.message}\n#{error.backtrace.join("\n")}\n"
					rescue Exception
						@general_failure << 'error in logger'
					end
				end

				tcp = UV.start_server '127.0.0.1', 3250, HttpServer
				server = UV::HttpEndpoint.new 'http://127.0.0.1:3250'

				request = server.get(:path => '/')
				request.then(proc { |response|
					@response = response
					tcp.close
					@loop.stop
				}, @request_failure)
			}

			expect(@general_failure).to eq([])
			expect(@response[:headers][:"Content-type"]).to eq('text/html')
			expect(@response[:headers].http_version).to eq('1.1')
			expect(@response[:headers].status).to eq(200)
			expect(@response[:headers].cookies).to eq({})
			expect(@response[:headers].keep_alive).to eq(true)

			expect(@response[:body]).to eq('y')
		end

		it "should send multiple requests on the same connection" do
			@loop.run { |logger|
				logger.progress do |level, errorid, error|
					begin
						@general_failure << "Log called: #{level}: #{errorid}\n#{error.message}\n#{error.backtrace.join("\n")}\n"
					rescue Exception
						@general_failure << 'error in logger'
					end
				end

				tcp = UV.start_server '127.0.0.1', 3250, HttpServer
				server = UV::HttpEndpoint.new 'http://127.0.0.1:3250'

				request = server.get(:path => '/')
				request.then(proc { |response|
					@response = response
					#@loop.stop
				}, @request_failure)
				
				request2 = server.get(:path => '/')
				request2.then(proc { |response|
					@response2 = response
					tcp.close
					@loop.stop
				}, @request_failure)
			}

			expect(@general_failure).to eq([])
			expect(@response[:headers][:"Content-type"]).to eq('text/html')
			expect(@response[:headers].http_version).to eq('1.1')
			expect(@response[:headers].status).to eq(200)
			expect(@response[:headers].cookies).to eq({})
			expect(@response[:headers].keep_alive).to eq(true)

			expect(@response2[:headers][:"Content-type"]).to eq('text/html')
			expect(@response2[:headers].http_version).to eq('1.1')
			expect(@response2[:headers].status).to eq(200)
			expect(@response2[:headers].cookies).to eq({})
			expect(@response2[:headers].keep_alive).to eq(true)
		end
	end

	describe 'old http request' do
		it "should send a request then receive a response" do
			@loop.run { |logger|
				logger.progress do |level, errorid, error|
					begin
						@general_failure << "Log called: #{level}: #{errorid}\n#{error.message}\n#{error.backtrace.join("\n")}\n"
					rescue Exception
						@general_failure << 'error in logger'
					end
				end

				tcp = UV.start_server '127.0.0.1', 3250, OldServer
				server = UV::HttpEndpoint.new 'http://127.0.0.1:3250'

				request = server.get(:path => '/')
				request.then(proc { |response|
					@response = response
					tcp.close
					@loop.stop
				}, @request_failure)
			}

			expect(@general_failure).to eq([])
			expect(@response[:headers][:"Content-type"]).to eq('text/html')
			expect(@response[:headers].http_version).to eq('1.0')
			expect(@response[:headers].status).to eq(200)
			expect(@response[:headers].cookies).to eq({})
			expect(@response[:headers].keep_alive).to eq(false)
		end

		it "should send multiple requests" do
			@loop.run { |logger|
				logger.progress do |level, errorid, error|
					begin
						@general_failure << "Log called: #{level}: #{errorid}\n#{error.message}\n#{error.backtrace.join("\n")}\n"
					rescue Exception
						@general_failure << 'error in logger'
					end
				end

				tcp = UV.start_server '127.0.0.1', 3250, OldServer
				server = UV::HttpEndpoint.new 'http://127.0.0.1:3250'

				request = server.get(:path => '/')
				request.then(proc { |response|
					@response = response
					#@loop.stop
				}, @request_failure)
				
				request2 = server.get(:path => '/')
				request2.then(proc { |response|
					@response2 = response
					tcp.close
					@loop.stop
				}, @request_failure)
			}

			expect(@general_failure).to eq([])
			expect(@response[:headers][:"Content-type"]).to eq('text/html')
			expect(@response[:headers].http_version).to eq('1.0')
			expect(@response[:headers].status).to eq(200)
			expect(@response[:headers].cookies).to eq({})
			expect(@response[:headers].keep_alive).to eq(false)

			expect(@response2[:headers][:"Content-type"]).to eq('text/html')
			expect(@response2[:headers].http_version).to eq('1.0')
			expect(@response2[:headers].status).to eq(200)
			expect(@response2[:headers].cookies).to eq({})
			expect(@response2[:headers].keep_alive).to eq(false)
		end
	end
end
