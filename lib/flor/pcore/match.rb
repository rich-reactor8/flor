
class Flor::Pro::Match < Flor::Procedure

  names %w[ match match? ]

  def pre_execute

    @node['rets'] = []
  end

  def receive_last

    rex, str = arguments

    m = rex.match(str)

    payload['ret'] =
      if @node['heap'] == 'match?'
        !! m
      else
        m ? m.to_a : []
      end

    reply
  end

  protected

  def arguments

    fail ArgumentError.new(
      "'match' needs at least 2 arguments"
    ) if @node['rets'].size < 2

    rex = @node['rets']
      .find { |r| r.is_a?(Array) && r[0] == '_rxs' } || @node['rets'].last

    str = (@node['rets'] - [ rex ]).first

    rex = rex.is_a?(String) ? rex : rex[1].to_s
    rex = rex.match(/\A\/[^\/]*\/[a-z]*\z/) ? Kernel.eval(rex) : Regexp.new(rex)

    [ rex, str ]
  end
end

