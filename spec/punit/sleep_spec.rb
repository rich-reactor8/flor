
#
# specifying flor
#
# Sat May 14 07:02:08 JST 2016
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf[:unit] = 'pu_sleep'
    @unit.storage.delete_tables
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.shutdown
  end

  describe 'sleep' do

    it 'creates a timer' do

      flor = %{
        sleep '1y'
      }

      exid = @unit.launch(flor)

      sleep 0.777

      ts = @unit.timers.all
      t = ts.first
      td = t.data

      expect(ts.count).to eq(1)

      expect(t.exid).to eq(exid)
      expect(t.type).to eq('in')
      expect(t.schedule).to eq('1y')
      expect(t.ntime_t.year).to eq(Time.now.utc.year + 1)

      expect(td['message']['point']).to eq('receive')
    end

    it 'understands for:' do

      flor = %{
        sleep for: '2y'
      }

      exid = @unit.launch(flor)

      sleep 0.350

      ts = @unit.timers.all
      t = ts.first
      td = t.data

      expect(ts.count).to eq(1)

      expect(t.exid).to eq(exid)
      expect(t.type).to eq('in')
      expect(t.schedule).to eq('2y')
      expect(t.ntime_t.year).to eq(Time.now.utc.year + 2)

      expect(td['message']['point']).to eq('receive')
    end

    it 'fails when missing a duration' do

      flor = %{
        sleep _
      }

      msg = @unit.launch(flor, wait: true)

      expect(msg['point']).to eq('failed')
      expect(msg['error']['msg']).to eq('missing a sleep time duration')
    end

    it 'does not sleep when t <= 0' do

      flor = %{
        sleep '0s'
      }

      exid = @unit.launch(flor)

      sleep 0.777

      expect(@unit.executions.terminated.count).to eq(1)

      e = @unit.executions.terminated.first
      expect(e.data['duration']).to be < 0.777

      expect(@unit.timers.count).to eq(0)
    end

    it 'makes an execution sleep for a while' do

      flor = %{
        sleep '1s'
      }

      exid = @unit.launch(flor)

      sleep 0.777

      expect(@unit.timers.count).to eq(1)

      sleep 0.777

      expect(@unit.executions.terminated.count).to eq(1)

      e = @unit.executions.terminated.first

      expect(e.data['duration']).to be > 1.0

      expect(@unit.timers.count).to eq(0)
    end
  end
end

