
#
# specifying flor
#
# Fri May 20 14:29:17 JST 2016
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'u'
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.stop
    @unit.storage.clear
    @unit.shutdown
  end

  describe 'trap' do

    it 'fails when children count < 2' do

      flon = %{
        trap 'execute'
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('failed')
      expect(r['error']['msg']).to eq('trap requires at least one child node')
    end

    it 'traps messages' do

      flon = %{
        sequence
          trap 'terminated'
            def msg; trace "t:$(msg.from)"
          trace "s:$(nid)"
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('terminated')

      sleep 0.100

      expect(
        @unit.traces.collect(&:text).join(' ')
      ).to eq(
        's:0_1_0_0 t:0'
      )
    end

    it 'traps tags' do

      flon = %{
        sequence
          trace 'a'
          trap tag: 'x'
            trace f.msg.point
          sequence tag: 'x'
            trace 'c'
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('terminated')

      sleep 0.100

      expect(
        @unit.traces.collect(&:text).join(' ')
      ).to eq(
        'a c entered'
      )
    end

    it 'traps multiple times' do

      flon = %{
        trap point: 'receive'
          trace "($(nid))=$(f.msg.from)->$(f.msg.nid)"
        sequence
          sequence
            trace '*'
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('terminated')

      sleep 0.350

      expect(
        #@unit.traces.collect(&:text).join(' | ')
        @unit.traces
          .each_with_index
          .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
      ).to eq(%w{
        0:(0_0_1_0_0-1)=0_0->0
        1:*
        2:(0_0_1_0_0-2)=0_1_0_0_0_0->0_1_0_0_0
        3:(0_0_1_0_0-3)=0_1_0_0_0->0_1_0_0
        4:(0_0_1_0_0-4)=0_1_0_0->0_1_0
        5:(0_0_1_0_0-5)=0_1_0->0_1
        6:(0_0_1_0_0-6)=0_1->0
        7:(0_0_1_0_0-7)=0->
      }.collect(&:strip).join("\n"))
    end
  end
end

