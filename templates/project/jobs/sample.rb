SCHEDULER.every '5s' do
    send_event('synergy',        { value: (rand * 1024).floor })
    send_event('convergence',    { value: (rand * 1024).floor })
    send_event('paradigm_shift', { value: (rand * 1024).floor })
end