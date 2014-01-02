require 'uv-rays'

describe UV::Scheduler::CronLine do

    def cl(cronline_string)
        UV::Scheduler::CronLine.new(cronline_string)
    end

    def match(line, time)
        expect(cl(line).matches?(time)).to eq(true)
    end
    def no_match(line, time)
        expect(cl(line).matches?(time)).to eq(false)
    end
    def to_a(line, array)
        expect(cl(line).to_array).to eq(array)
    end
    def local(*args)
        Time.local(*args)
    end
    alias lo local

    def utc(*args)
        Time.utc(*args)
    end

    describe '.new' do

        it 'interprets cron strings correctly' do

            to_a '* * * * *', [ [0], nil, nil, nil, nil, nil, nil, nil ]
            to_a '10-12 * * * *', [ [0], [10, 11, 12], nil, nil,    nil, nil, nil, nil ]
            to_a '* * * * sun,mon', [ [0], nil, nil, nil, nil, [0, 1], nil, nil ]
            to_a '* * * * mon-wed', [ [0], nil, nil, nil, nil, [1, 2, 3], nil, nil ]
            to_a '* * * * 7', [ [0], nil, nil, nil, nil, [0], nil, nil ]
            to_a '* * * * 0', [ [0], nil, nil, nil, nil, [0], nil, nil ]
            to_a '* * * * 0,1', [ [0], nil, nil, nil, nil, [0,1], nil, nil ]
            to_a '* * * * 7,1', [ [0], nil, nil, nil, nil, [0,1], nil, nil ]
            to_a '* * * * 7,0', [ [0], nil, nil, nil, nil, [0], nil, nil ]
            to_a '* * * * sun,2-4', [ [0], nil, nil, nil, nil, [0, 2, 3, 4], nil, nil ]

            to_a '* * * * sun,mon-tue', [ [0], nil, nil, nil, nil, [0, 1, 2], nil, nil ]

            to_a '* * * * * *', [ nil, nil, nil, nil, nil, nil, nil, nil ]
            to_a '1 * * * * *', [ [1], nil, nil, nil, nil, nil, nil, nil ]
            to_a '7 10-12 * * * *', [ [7], [10, 11, 12], nil, nil, nil, nil, nil, nil ]
            to_a '1-5 * * * * *', [ [1,2,3,4,5], nil, nil, nil, nil, nil, nil, nil ]

            to_a '0 0 1 1 *', [ [0], [0], [0], [1], [1], nil, nil, nil ]

            to_a '0 23-24 * * *', [ [0], [0], [23, 0], nil, nil, nil, nil, nil ]
                #
                # as reported by Aimee Rose in
                # https://github.com/jmettraux/rufus-scheduler/issues/56

            to_a '0 23-2 * * *', [ [0], [0], [23, 0, 1, 2], nil, nil, nil, nil, nil ]
        end

        it 'rejects invalid weekday expressions' do

            expect  { cl '0 17 * * MON_FRI' }.to raise_error
                # underline instead of dash

            expect  { cl '* * * * 9' }.to raise_error
            expect  { cl '* * * * 0-12' }.to raise_error
            expect  { cl '* * * * BLABLA' }.to raise_error
        end

        it 'rejects invalid cronlines' do

            expect  { cl '* nada * * 9' }.to raise_error(ArgumentError)
        end

        it 'interprets cron strings with TZ correctly' do

            to_a('* * * * * EST', [ [0], nil, nil, nil, nil, nil, nil, 'EST' ])
            to_a('* * * * * * EST', [ nil, nil, nil, nil, nil, nil, nil, 'EST' ])

            to_a(
                '* * * * * * America/Chicago',
                [ nil, nil, nil, nil, nil, nil, nil, 'America/Chicago' ])
            to_a(
                '* * * * * * America/New_York',
                [ nil, nil, nil, nil, nil, nil, nil, 'America/New_York' ])

            expect  { cl '* * * * * NotATimeZone' }.to raise_error
            expect  { cl '* * * * * * NotATimeZone' }.to raise_error
        end

        it 'interprets cron strings with / (slashes) correctly' do

            to_a(
                '0 */2 * * *',
                [ [0], [0], (0..11).collect { |e| e * 2 }, nil, nil, nil, nil, nil ])
            to_a(
                '0 7-23/2 * * *',
                [ [0], [0], (7..23).select { |e| e.odd? }, nil, nil, nil, nil, nil ])
            to_a(
                '*/10 * * * *',
                [ [0], [0, 10, 20, 30, 40, 50], nil, nil, nil, nil, nil, nil ])

            # fighting https://github.com/jmettraux/rufus-scheduler/issues/65
            #
            to_a(
                '*/10 * * * * Europe/Berlin',
                [ [0], [ 0, 10, 20, 30, 40, 50], nil, nil, nil, nil, nil, 'Europe/Berlin' ])
        end

        it 'accepts lonely / (slashes) (like <= 2.0.19 did)' do

            # fighting https://github.com/jmettraux/rufus-scheduler/issues/65

            to_a(
                '/10 * * * *',
                [ [0], [ 0, 10, 20, 30, 40, 50], nil, nil, nil, nil, nil, nil ])
        end

        it 'does not support ranges for monthdays (sun#1-sun#2)' do

            expect {
                UV::Scheduler::CronLine.new('* * * * sun#1-sun#2')
            }.to raise_error(ArgumentError)
        end

        it 'accepts items with initial 0' do

            to_a '09 * * * *', [ [0], [9], nil, nil, nil, nil, nil, nil ]
            to_a '09-12 * * * *', [ [0], [9, 10, 11, 12], nil, nil, nil, nil, nil, nil ]
            to_a '07-08 * * * *', [ [0], [7, 8], nil, nil, nil, nil, nil, nil ]
            to_a '* */08 * * *', [ [0], nil, [0, 8, 16], nil, nil, nil, nil, nil ]
            to_a '* */07 * * *', [ [0], nil, [0, 7, 14, 21], nil, nil, nil, nil, nil ]
            to_a '* 01-09/04 * * *', [ [0], nil, [1, 5, 9], nil, nil, nil, nil, nil ]
            to_a '* * * * 06', [ [0], nil, nil, nil, nil, [6], nil, nil ]
        end

        it 'interprets cron strings with L correctly' do

            to_a '* * L * *', [[0], nil, nil, ['L'], nil, nil, nil, nil ]
            to_a '* * 2-5,L * *', [[0], nil, nil, [2,3,4,5,'L'], nil, nil, nil, nil ]
            to_a '* * */8,L * *', [[0], nil, nil, [1,9,17,25,'L'], nil, nil, nil, nil ]
        end

        it 'does not support ranges for L' do

            expect  { cl '* * 15-L * *'}.to raise_error(ArgumentError)
            expect  { cl '* * L/4 * *'}.to raise_error(ArgumentError)
        end

        it 'does not support multiple Ls' do

            expect  { cl '* * L,L * *'}.to raise_error(ArgumentError)
        end

        it 'raises if L is used for something else than days' do

            expect  { cl '* L * * *'}.to raise_error(ArgumentError)
        end

        it 'raises for out of range input' do

            expect  { cl '60-62 * * * *'}.to raise_error(ArgumentError)
            expect  { cl '62 * * * *'}.to raise_error(ArgumentError)
            expect  { cl '60 * * * *'}.to raise_error(ArgumentError)
            expect  { cl '* 25-26 * * *'}.to raise_error(ArgumentError)
            expect  { cl '* 25 * * *'}.to raise_error(ArgumentError)
                #
                # as reported by Aimee Rose in
                # https://github.com/jmettraux/rufus-scheduler/pull/58
        end
    end

    describe '#next_time' do

        def nt(cronline, now)
            UV::Scheduler::CronLine.new(cronline).next_time(now)
        end

        it 'computes the next occurence correctly' do

            now = Time.at(0).getutc # Thu Jan 01 00:00:00 UTC 1970

            expect(nt('* * * * *', now)).to eq(now + 60)
            expect(nt('* * * * sun', now)).to eq(now + 259200)
            expect(nt('* * * * * *', now)).to eq(now + 1)
            expect(nt('* * 13 * fri', now)).to eq(now + 3715200)

            expect(nt('10 12 13 12 *', now)).to eq(now + 29938200)
                # this one is slow (1 year == 3 seconds)
                #
                # historical note:
                # (comment made in 2006 or 2007, the underlying libs got better and
                # that slowness is gone)

            expect(nt('0 0 * * thu', now)).to eq(now + 604800)
            expect(nt('00 0 * * thu', now)).to eq(now + 604800)

            expect(nt('0 0 * * *', now)).to eq(now + 24 * 3600)
            expect(nt('0 24 * * *', now)).to eq(now + 24 * 3600)

            now = local(2008, 12, 31, 23, 59, 59, 0)

            expect(nt('* * * * *', now)).to eq(now + 1)
        end

        it 'computes the next occurence correctly in UTC (TZ not specified)' do

            now = utc(1970, 1, 1)

            expect(nt('* * * * *', now)).to eq(utc(1970, 1, 1, 0, 1))
            expect(nt('* * * * sun', now)).to eq(utc(1970, 1, 4))
            expect(nt('* * * * * *', now)).to eq(utc(1970, 1, 1, 0, 0, 1))
            expect(nt('* * 13 * fri', now)).to eq(utc(1970, 2, 13))

            expect(nt('10 12 13 12 *', now)).to eq(utc(1970, 12, 13, 12, 10))
                # this one is slow (1 year == 3 seconds)
            expect(nt('* * 1 6 *', now)).to eq(utc(1970, 6, 1))

            expect(nt('0 0 * * thu', now)).to eq(utc(1970, 1, 8))
        end

        it 'computes the next occurence correctly in local TZ (TZ not specified)' do

            now = local(1970, 1, 1)

            expect(nt('* * * * *', now)).to eq(local(1970, 1, 1, 0, 1))
            expect(nt('* * * * sun', now)).to eq(local(1970, 1, 4))
            expect(nt('* * * * * *', now)).to eq(local(1970, 1, 1, 0, 0, 1))
            expect(nt('* * 13 * fri', now)).to eq(local(1970, 2, 13))

            expect(nt('10 12 13 12 *', now)).to eq(local(1970, 12, 13, 12, 10))
                # this one is slow (1 year == 3 seconds)
            expect(nt('* * 1 6 *', now)).to eq(local(1970, 6, 1))

            expect(nt('0 0 * * thu', now)).to eq(local(1970, 1, 8))
        end

        it 'computes the next occurence correctly in UTC (TZ specified)' do

            zone = 'Europe/Stockholm'
            tz = TZInfo::Timezone.get(zone)
            now = tz.local_to_utc(local(1970, 1, 1))
                # Midnight in zone, UTC

            expect(nt("* * * * * #{zone}", now)).to eq(utc(1969, 12, 31, 23, 1))
            expect(nt("* * * * sun #{zone}", now)).to eq(utc(1970, 1, 3, 23))
            expect(nt("* * * * * * #{zone}", now)).to eq(utc(1969, 12, 31, 23, 0, 1))
            expect(nt("* * 13 * fri #{zone}", now)).to eq(utc(1970, 2, 12, 23))

            expect(nt("10 12 13 12 * #{zone}", now)).to eq(utc(1970, 12, 13, 11, 10))
            expect(nt("* * 1 6 * #{zone}", now)).to eq(utc(1970, 5, 31, 23))

            expect(nt("0 0 * * thu #{zone}", now)).to eq(utc(1970, 1, 7, 23))
        end

        #it 'computes the next occurence correctly in local TZ (TZ specified)' do
        #    zone = 'Europe/Stockholm'
        #    tz = TZInfo::Timezone.get(zone)
        #    now = tz.local_to_utc(utc(1970, 1, 1)).localtime
        #        # Midnight in zone, local time
        #    expect(nt("* * * * * #{zone}", now)).to eq(local(1969, 12, 31, 18, 1))
        #    expect(nt("* * * * sun #{zone}", now)).to eq(local(1970, 1, 3, 18))
        #    expect(nt("* * * * * * #{zone}", now)).to eq(local(1969, 12, 31, 18, 0, 1))
        #    expect(nt("* * 13 * fri #{zone}", now)).to eq(local(1970, 2, 12, 18))
        #    expect(nt("10 12 13 12 * #{zone}", now)).to eq(local(1970, 12, 13, 6, 10))
        #    expect(nt("* * 1 6 * #{zone}", now)).to eq(local(1970, 5, 31, 19))
        #    expect(nt("0 0 * * thu #{zone}", now)).to eq(local(1970, 1, 7, 18))
        #end

        it 'computes the next time correctly when there is a sun#2 involved' do

            expect(nt('* * * * sun#1', local(1970, 1, 1))).to eq(local(1970, 1, 4))
            expect(nt('* * * * sun#2', local(1970, 1, 1))).to eq(local(1970, 1, 11))

            expect(nt('* * * * sun#2', local(1970, 1, 12))).to eq(local(1970, 2, 8))
        end

        it 'computes the next time correctly when there is a sun#2,sun#3 involved' do

            expect(nt('* * * * sun#2,sun#3', local(1970, 1, 1))).to eq(local(1970, 1, 11))
            expect(nt('* * * * sun#2,sun#3', local(1970, 1, 12))).to eq(local(1970, 1, 18))
        end

        it 'understands sun#L' do

            expect(nt('* * * * sun#L', local(1970, 1, 1))).to eq(local(1970, 1, 25))
        end

        it 'understands sun#-1' do

            expect(nt('* * * * sun#-1', local(1970, 1, 1))).to eq(local(1970, 1, 25))
        end

        it 'understands sun#-2' do

            expect(nt('* * * * sun#-2', local(1970, 1, 1))).to eq(local(1970, 1, 18))
        end

        it 'computes the next time correctly when "L" (last day of month)' do

            expect(nt('* * L * *', lo(1970, 1, 1))).to eq(lo(1970, 1, 31))
            expect(nt('* * L * *', lo(1970, 2, 1))).to eq(lo(1970, 2, 28))
            expect(nt('* * L * *', lo(1972, 2, 1))).to eq(lo(1972, 2, 29))
            expect(nt('* * L * *', lo(1970, 4, 1))).to eq(lo(1970, 4, 30))
        end

        it 'returns a time with subseconds chopped off' do

            expect(nt('* * * * *', Time.now).usec).to eq(0)
            expect(nt('* * * * *', Time.now).iso8601(10).match(/\.0+[^\d]/)).not_to eq(nil)
        end
    end

    describe '#previous_time' do

        def pt(cronline, now)
            UV::Scheduler::CronLine.new(cronline).previous_time(now)
        end

        it 'returns the previous time the cron should have triggered' do

            expect(pt('* * * * sun', lo(1970, 1, 1))).to eq(lo(1969, 12, 28, 23, 59, 00))
            expect(pt('* * 13 * *', lo(1970, 1, 1))).to eq(lo(1969, 12, 13, 23, 59, 00))
            expect(pt('0 12 13 * *', lo(1970, 1, 1))).to eq(lo(1969, 12, 13, 12, 00))

            expect(pt('* * * * * sun', lo(1970, 1, 1))).to eq(lo(1969, 12, 28, 23, 59, 59))
        end
    end

    describe '#matches?' do

        it 'matches correctly in UTC (TZ not specified)' do

            match '* * * * *', utc(1970, 1, 1, 0, 1)
            match '* * * * sun', utc(1970, 1, 4)
            match '* * * * * *', utc(1970, 1, 1, 0, 0, 1)
            match '* * 13 * fri', utc(1970, 2, 13)

            match '10 12 13 12 *', utc(1970, 12, 13, 12, 10)
            match '* * 1 6 *', utc(1970, 6, 1)

            match '0 0 * * thu', utc(1970, 1, 8)

            match '0 0 1 1 *', utc(2012, 1, 1)
            no_match '0 0 1 1 *', utc(2012, 1, 1, 1, 0)
        end

        it 'matches correctly in local TZ (TZ not specified)' do

            match '* * * * *', local(1970, 1, 1, 0, 1)
            match '* * * * sun', local(1970, 1, 4)
            match '* * * * * *', local(1970, 1, 1, 0, 0, 1)
            match '* * 13 * fri', local(1970, 2, 13)

            match '10 12 13 12 *', local(1970, 12, 13, 12, 10)
            match '* * 1 6 *', local(1970, 6, 1)

            match '0 0 * * thu', local(1970, 1, 8)

            match '0 0 1 1 *', local(2012, 1, 1)
            no_match '0 0 1 1 *', local(2012, 1, 1, 1, 0)
        end

        it 'matches correctly in UTC (TZ specified)' do

            zone = 'Europe/Stockholm'

            match "* * * * * #{zone}", utc(1969, 12, 31, 23, 1)
            match "* * * * sun #{zone}", utc(1970, 1, 3, 23)
            match "* * * * * * #{zone}", utc(1969, 12, 31, 23, 0, 1)
            match "* * 13 * fri #{zone}", utc(1970, 2, 12, 23)

            match "10 12 13 12 * #{zone}", utc(1970, 12, 13, 11, 10)
            match "* * 1 6 * #{zone}", utc(1970, 5, 31, 23)

            match "0 0 * * thu #{zone}", utc(1970, 1, 7, 23)
        end

        it 'matches correctly when there is a sun#2 involved' do

            match '* * 13 * fri#2', utc(1970, 2, 13)
            no_match '* * 13 * fri#2', utc(1970, 2, 20)
        end

        it 'matches correctly when there is a L involved' do

            match '* * L * *', utc(1970, 1, 31)
            no_match '* * L * *', utc(1970, 1, 30)
        end

        it 'matches correctly when there is a sun#2,sun#3 involved' do

            no_match '* * * * sun#2,sun#3', local(1970, 1, 4)
            match '* * * * sun#2,sun#3', local(1970, 1, 11)
            match '* * * * sun#2,sun#3', local(1970, 1, 18)
            no_match '* * * * sun#2,sun#3', local(1970, 1, 25)
        end
    end

    describe '#monthdays' do

        it 'returns the appropriate "sun#2"-like string' do

            class UV::Scheduler::CronLine
                public :monthdays
            end

            cl = UV::Scheduler::CronLine.new('* * * * *')

            expect(cl.monthdays(local(1970, 1, 1))).to eq(%w[ thu#1 thu#-5 ])
            expect(cl.monthdays(local(1970, 1, 7))).to eq(%w[ wed#1 wed#-4 ])
            expect(cl.monthdays(local(1970, 1, 14))).to eq(%w[ wed#2 wed#-3 ])

            expect(cl.monthdays(local(2011, 3, 11))).to eq(%w[ fri#2 fri#-3 ])
        end
    end

    describe '#frequency' do

        it 'returns the shortest delta between two occurrences' do

            expect(UV::Scheduler::CronLine.new('* * * * *').frequency).to eq(60)
            expect(UV::Scheduler::CronLine.new('* * * * * *').frequency).to eq(1)

            expect(UV::Scheduler::CronLine.new('5 23 * * *').frequency).to eq(24 * 3600)
            expect(UV::Scheduler::CronLine.new('5 * * * *').frequency).to eq(3600)
            expect(UV::Scheduler::CronLine.new('10,20,30 * * * *').frequency).to eq(600)
        end
    end
end
