current_valuation = 0

SCHEDULER.every '2s' do
  last_valuation = current_valuation
  current_valuation = rand(100)

  send_event('valuation', { current: current_valuation, last: last_valuation })
  send_event('synergy',   { value: rand(100) })
end