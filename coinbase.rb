#!/usr/bin/ruby
require 'bigdecimal'
require 'monetize'
require 'coinbase/wallet'
I18n.load_path = ['en.yml']
client = Coinbase::Wallet::Client.new(api_key: ENV['COINBASE_API_KEY'], api_secret: ENV['COINBASE_API_SECRET'])

usd_buy_total = BigDecimal.new(0)
btc_total = BigDecimal.new(0)
client.list_buys(client.primary_account.id, fetch_all: true).each do |data, resp|
  usd_buy_total += BigDecimal.new(data['total']['amount'])  # Add money spent on buying bitcoin
  btc_total += BigDecimal.new(data['amount']['amount'])
end

usd_sell_total = BigDecimal.new(0)
client.list_sells(client.primary_account.id, fetch_all: true).each do |data, resp|
  usd_sell_total += BigDecimal.new(data['total']['amount']) # Realized returns from sales
  btc_total -= BigDecimal.new(data['amount']['amount'])  # Subtract sold bitcoin from current holdings
end

current_value = btc_total * BigDecimal.new(client.spot_price['amount'])
profit = current_value + usd_sell_total - usd_buy_total
puts "Profit: #{profit.to_money.format}"
