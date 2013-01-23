# -*- encoding: UTF-8 -*-

module DeepMergeHash

  def deep_merge(other_hash)
    r = {}
    merge(other_hash) do |key, oldval, newval|
      r[key] = oldval.class == self.class ? oldval.deep_merge(newval) : newval
    end
  end
end

class Hash
  include DeepMergeHash
end
