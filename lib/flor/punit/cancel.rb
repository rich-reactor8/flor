
class Flor::Pro::Cancel < Flor::Procedure
  #
  # Cancels an execution branch
  #
  # ```
  # concurrence
  #   sequence tag: 'blue'
  #   sequence
  #     cancel ref: 'blue'
  # ```

  name 'cancel', 'kill'
    # ruote had "undo" as well...

  def pre_execute

    @node['atts'] = []
  end

  def receive_last

    targets =
      @node['atts']
        .select { |k, v| k == nil }
        .inject([]) { |a, (k, v)|
          v = Array(v)
          a.concat(v) if v.all? { |e| e.is_a?(String) }
          a
        } +
      att_a('nid') +
      att_a('ref')

    nids, tags = targets.partition { |t| Flor.is_nid?(t) }

    nids += tags_to_nids(tags)

    fla = @node['heap']

    nids.uniq.collect { |nid|
      reply('point' => 'cancel', 'nid' => nid, 'flavour' => fla).first
    } + reply
  end
end

