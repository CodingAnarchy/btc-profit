#!/usr/bin/ruby
require 'bigdecimal'
require 'monetize'
require 'coinbase/wallet'
I18n.load_path = ['en.yml']
client = Coinbase::Wallet::Client.new(api_key: ENV['COINBASE_API_KEY'], api_secret: ENV['COINBASE_API_SECRET'])

usd_total = BigDecimal.new(0)
btc_total = BigDecimal.new(0)
client.list_buys(client.primary_account.id, fetch_all: true).each do |data, resp|
  usd_total += BigDecimal.new(data['total']['amount'])
  btc_total += BigDecimal.new(data['amount']['amount'])
end

current_value = btc_total * BigDecimal.new(client.spot_price['amount'])
profit = current_value - usd_total
puts "Profit: #{profit.to_money.format}"
