
require 'rubygems'
require 'bankjob'      # this require will pull in all the classes we need
require 'base_scraper' # this defines scraper that BpiScraper extends

require 'activesupport'

class VisaScraper < BaseScraper

  currency "BRL"
  decimal ","
  account_number  'Visa'
  account_type 'CREDITCARD'

  # compra parcelada muda a descrição e a data é igual a
  # data da compra + número de parcelas.
  transaction_rule do |tx|
    regex = /(\d+)\/(\d+)$/
    if tx.raw_description =~ regex
      m = tx.raw_description.match(regex)
      # compra é parcelada e feita no passado
      tx.date = tx.date.prev_year if tx.date.future?

      tx.raw_description.gsub!(regex, " - #{m[1]} de #{m[2]} em #{tx.date.strftime('%d/%m/%Y')}")
      tx.date = tx.date.months_since(m[1].to_i-1)
    end
  end
  
  def parse_transactions_page transactions_page
    statement = create_statement

    valores = (transactions_page/"td.TRNtitcampo").select{ |v| v.inner_text =~ /\d+,\d+/ }.collect &:inner_text
    cotacao = valores[-3].gsub(',', '.').to_f
    p "cotação #{cotacao}"

    # verificação da cotação do dolar.
    throw "Cotação #{cotacao} suspeita" if cotacao < 1 or cotacao > 2
    
    # vencimento da fatura.
    # vencimento = (transactions_page/"td.TRNdado").select {|c| c.inner_text =~ /^\d{2}\/\d{2}/ }.collect &:inner_text
    # vencimento = Date.strptime(vencimento.first, '%d/%m/%Y')
    
    rows = (transactions_page/"tr")
    rows.each do |row|

      # procuro apenas TRs sem TRs dentro
      next if (row/'tr').size > 0

      row = (row/'td').collect{ |cell| cell.inner_text.strip.strip.gsub(/(\t|\r\n|\302\240)/, "") }
      
      # ignorar o que não começa com data.
      next if row.first !~ /^\d{2}\/\d{2}/
      next if row.first =~ /PAGAMENTO EFETUADO/
      
      desc = row[0]
      if row.size == 3
        # nacional
        cred = row[1]
        debt = row[2]
      else
        # internacional
        # converte para DOLAR
        cred = from_dollar row[4]
        debt = from_dollar row[5]
      end

      if m = desc.match('\d{2}/\d{2} - (.*)')
        t = create_transaction

        t.date = Date.strptime(desc, '%d/%m')   
        t.raw_description = m[1]

        # esse tem duas colunas
        if cred != '0,00'
          t.amount = cred
        else
          t.amount = "-" + debt
        end
        # remover o .
        t.amount.gsub(/\./, '')

        p t.to_s
        
        statement.add_transaction t
      end
    end
    statement.finish false
    statement
  end

  def from_dollar v
    v = v.gsub(/\./, '').gsub(',', '.').to_f
    v = "%.2f" % (v * 1.7)
    v.to_s.gsub('.', ',')
  end
end