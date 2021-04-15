# frozen_string_literal: true

require 'byebug'
require 'date'

class VintedShipment
  attr_accessor :month, :previous_month, :discount, :la_poste_special_discount, :transactions

  def initialize
    @discount = 10.0
    @transactions = File.readlines('input.txt')
    @la_poste_special_discount = { taken: true, frequency: 0 }
  end

  PROVIDERS = {lp: "LP", mr: "MR"}
  LP = { s: 1.50, m: 4.90, l: 6.90 }
  MR = { s: 2, m: 3, l: 4 }
  ALLOWED_SIZES = %w(S M L)

  def process
    iteration = 0
    transactions.each do |shipment|
      entry = shipment.split(" ")

      @month = begin
                 Date.parse(entry[0])
               rescue
                 entry[0].to_s
               end

      @previous_month = formatted_month(@month) if iteration.zero?

      size = entry[1] || '-'
      provider = entry[2] || '-'

      invalid_shipment = !@month.is_a?(Date) || [size, provider].include?('-')
      puts [shipment, 'Ignored'].join(' ') if invalid_shipment

      case size
        when 'S'
          cost, current_discount = if (LP[symbolize(size)] - MR[symbolize(size)]).negative?
                                     [LP[symbolize(size)], LP[symbolize(size)] - MR[symbolize(size)]]
                                   else
                                     [MR[symbolize(size)], MR[symbolize(size)] - LP[symbolize(size)]]
                                   end
          @discount = @discount + current_discount
          puts [@month, size, provider, cost, -current_discount].join(' ')

        when 'M'
          cost = if provider.eql?('LP')
                   LP[symbolize(size)].to_f
                 else
                   MR[symbolize(size)].to_f
                 end

          puts [@month, size, provider, cost, '-'].join(' ')

        when 'L'
          if provider.downcase.eql?('lp')

          unless formatted_month(@month) === @previous_month
            @la_poste_special_discount = { taken: true, frequency: 0 }
            @previous_month = formatted_month(@month)
          end

          @la_poste_special_discount[:frequency] = @la_poste_special_discount[:frequency].next

          if @la_poste_special_discount[:frequency].remainder(3).zero? && @la_poste_special_discount[:taken].is_a?(TrueClass)
            @la_poste_special_discount[:taken] = false
            current_discount = @discount >= LP[symbolize(size)] ? LP[symbolize(size)] : @discount
            cost = LP[symbolize(size)]
            @discount = @discount - current_discount
            puts [@month, size, provider, 0.0, current_discount].join(' ')
          else
            puts [@month, size, provider, LP[symbolize(size)], '-'].join(' ')
          end
        end
      end
      iteration = iteration.next
    end
  end

  def formatted_month(month)
    month.strftime "%Y%m"
  end

  def symbolize(str)
    str.to_s.downcase.to_sym
  end
end

obj = VintedShipment.new
obj.process
