#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'coinbase/wallet'
require 'monetize'

I18n.load_path = ['en.yml']
client = Coinbase::Wallet::Client.new(api_key: ENV['COINBASE_API_KEY'], api_secret: ENV['COINBASE_API_SECRET'])

crypto_totals = { btc: BigDecimal.new(0), eth: BigDecimal.new(0), ltc: BigDecimal.new(0) } 
usd_buy_total = BigDecimal.new(0)
usd_transfer_total = BigDecimal.new(0)
usd_sell_total = BigDecimal.new(0)

client.accounts.each do |account, resp|
  next if account['type'] == 'fiat' # Skip USD accounts
  currency = account['currency'].downcase.to_sym
  # Need to list buys/sells separately to get the exact values including fees and order delays
  client.list_buys(account['id'], fetch_all: true).each do |data, resp|
    usd_buy_total += BigDecimal.new(data['total']['amount'])  # Add money spent on buying bitcoin
    crypto_totals[currency] += BigDecimal.new(data['amount']['amount'])
  end

  client.list_sells(account['id'], fetch_all: true).each do |data, resp|
    usd_sell_total += BigDecimal.new(data['total']['amount']) # Realized returns from sales
    crypto_totals[currency] -= BigDecimal.new(data['amount']['amount'])  # Subtract sold bitcoin from current holdings
  end

  client.transactions(account['id'], fetch_all: true).each do |data, resp|
    next if data['type'] == 'transfer'
    if ['send', 'exchange_deposit', 'exchange_withdrawal', 'order'].include? data['type']
      crypto_totals[currency] += BigDecimal.new(data['amount']['amount']) # Remove sent BTC from current holdings (amounts are negative for sends)
      usd_transfer_total += BigDecimal.new(data['native_amount']['amount']) # Adjust USD spent for transfer amounts in and out (at prices when transfer was done)
    elsif not ['buy', 'sell'].include? data['type']
      puts data
    end
  end
end

current_btc_value = crypto_totals[:btc] * BigDecimal.new(client.spot_price['amount'])
current_eth_value = crypto_totals[:eth] * BigDecimal.new(client.spot_price(currency_pair: 'ETH-USD')['amount'])
profit = current_btc_value + current_eth_value + usd_sell_total - usd_buy_total
puts "Profit: #{profit.to_money.format}"
