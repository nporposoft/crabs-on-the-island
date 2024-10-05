@state = 0

def has_state(state)
  mask = 1 << state
  @state & mask
end

def set_state(state)
  mask = 1 << state
  @state |= mask
end

def unset_state(state)
  mask = 1 << state
  @state &= ~mask
end
