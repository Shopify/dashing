SCHEDULER.every '5s' do
  sayings = [
      "That's one trouble with dual identities, Robin. Dual responsibilities.",
      "You know your neosauruses well, Robin. Peanut butter sandwiches it is.",
      "You're far from mod, Robin. And many hippies are older than you are.",
      "We're still over land, Robin, and a seal is an aquatic, marine mammal.",
      "True. You owe your life to dental hygiene.",
      "This money goes to building better roads. We all must do our part."
    ]

    send_event('sample', { quote: sayings.sample })
end