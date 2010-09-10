
require 'rubygems'
require 'bankjob'      # this require will pull in all the classes we need
require 'base_scraper' # this defines scraper that BpiScraper extends

require 'activesupport'

class VisaScraper < BaseScraper

  currency "BRL"
  decimal ","
  account_number  'Amex'
  account_type 'CREDITCARD'

  # compra parcelada muda a descrição e a data é igual a
  # data da compra + número de parcelas.
  transaction_rule do |tx|
    regex = /COMPRA PARCELADA PRESTACAO (\d+) DE (\d+)/
    if tx.raw_description =~ regex
      m = tx.raw_description.match(regex)
      tx.raw_description.gsub!(regex, " - #{m[1]} de #{m[2]} em #{tx.date.strftime('%d/%m/%Y')}")
        tx.date = tx.date.months_since(m[1].to_i-1)
    end
  end
  
  # cartão de crédito o valor é invertido
  transaction_rule do |tx|
    tx.amount = tx.amount.gsub(/(R\$|\.)/, '')
    if tx.amount =~ /^-/
      tx.amount = tx.amount.delete '-'
    else
      tx.amount = tx.amount.insert(0, '-')
    end    
  end

  def parse_transactions_page transactions_page
    statement = create_statement
    rows = (transactions_page/"tbody[@id*=mittbody_]/tr")
    rows.each do |row|
      begin
        date, description, amount = (row/"td").collect{ |cell| cell.inner_text.strip.strip.gsub(/(\t|\r\n|\302\240)/, "") }
        # ignorar.
        next if description =~ /PAGAMENTO RECEBIDO - OBRIGADO/
        
        # gera exception caso a data esteja incorreta(não quero essas linhas)
        begin
          date = Date.strptime(date, '%d/%m/%Y')   
        rescue
          next
        end
        
        t = create_transaction
        t.raw_description = description
        t.date = date
        t.amount = amount
        p t.to_s
        statement.add_transaction t
      rescue Exception => e
        p e
      end
    end
    statement.finish false
    statement
  end
end