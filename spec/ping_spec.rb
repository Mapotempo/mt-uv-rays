require 'mt-uv-rays'


describe MTUV::Ping do
    before :each do
        @reactor = MTLibuv::Reactor.default
        @reactor.notifier do |error, context|
            begin
                @general_failure << "Log called: #{context}\n#{error.message}\n#{error.backtrace.join("\n") if error.backtrace}\n"
            rescue Exception
                @general_failure << "error in logger #{e.inspect}"
            end
        end
        @general_failure = []
        @timeout = @reactor.timer do
            @reactor.stop
            @general_failure << "test timed out"
        end
        @timeout.start(5000)
    end

    after :each do
        @timeout.close
    end

    it "should ping IPv4" do
        pingger = ::MTUV::Ping.new('127.0.0.1')
        result = nil

        @reactor.run { |reactor|
            pingger.ping
            @timeout.stop
        }

        expect(@general_failure).to eq([])
        expect(pingger.pingable).to eq(true)
        expect(pingger.exception).to eq(nil)
        expect(pingger.warning).to eq(nil)
        expect(pingger.duration).to be > 0
    end

    xit "should ping IPv6", travis_skip: true do
        pingger = ::MTUV::Ping.new('::1')
        result = nil

        @reactor.run { |reactor|
            pingger.ping
            @timeout.stop
        }

        expect(@general_failure).to eq([])
        expect(pingger.pingable).to eq(true)
        expect(pingger.exception).to eq(nil)
        expect(pingger.warning).to eq(nil)
        expect(pingger.duration).to be > 0
    end
    
    it "should ping localhost after resolving using DNS" do
        pingger = ::MTUV::Ping.new('localhost')
        result = nil

        @reactor.run { |reactor|
            pingger.ping
            @timeout.stop
        }

        expect(@general_failure).to eq([])
        expect(pingger.pingable).to eq(true)
        expect(pingger.exception).to eq(nil)
        expect(pingger.warning).to eq(nil)
        expect(pingger.duration).to be > 0
    end
end
