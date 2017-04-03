#!/usr/bin/ruby
require 'bigdecimal'
require 'monetize'
require 'coinbase/wallet'
I18n.load_path = ['en.yml']
client = Coinbase::Wallet::Client.new(api_key: ENV['COINBASE_API_KEY'], api_secret: ENV['COINBASE_API_SECRET'])

account_id = client.primary_account.id

usd_buy_total = BigDecimal.new(0)
btc_total = BigDecimal.new(0)
client.list_buys(account_id, fetch_all: true).each do |data, resp|
  usd_buy_total += BigDecimal.new(data['total']['amount'])  # Add money spent on buying bitcoin
  btc_total += BigDecimal.new(data['amount']['amount'])
end

usd_sell_total = BigDecimal.new(0)
client.list_sells(account_id, fetch_all: true).each do |data, resp|
  usd_sell_total += BigDecimal.new(data['total']['amount']) # Realized returns from sales
  btc_total -= BigDecimal.new(data['amount']['amount'])  # Subtract sold bitcoin from current holdings
end

usd_transfer_total = BigDecimal.new(0)
client.transactions(account_id, fetch_all: true).each do |data, resp|
  if data['type'] == 'send'
    btc_total += BigDecimal.new(data['amount']['amount']) # Remove sent BTC from current holdings (amounts are negative for sends)
    usd_transfer_total += BigDecimal.new(data['native_amount']['amount']) # Adjust USD spent for transfer amounts in and out (at prices when transfer was done)
  end
end

current_value = btc_total * BigDecimal.new(client.spot_price['amount'])
profit = current_value + usd_sell_total - usd_buy_total
puts "Profit: #{profit.to_money.format}"
