# frozen_string_literal: true

namespace :calc do
  desc "Calculate life insurance monthly percent of loan rest.
  Usage: rake calc:life_insurance[loan_amount,months,total_life_insurance]
  Numbers may use '.' as thousands separator and ',' as decimal separator (Polish format).
  Example: rake calc:life_insurance[841023,263,31171]"
  task :life_insurance, [:loan_amount, :months, :total_life_insurance] => :environment do |t, args|
    if args[:loan_amount].nil? || args[:months].nil? || args[:total_life_insurance].nil?
      puts "Usage: rake calc:life_insurance[loan_amount,months,total_life_insurance]"
      puts "Numbers may use '.' as thousands separator and ',' as decimal separator (Polish format)."
      puts "Example: rake calc:life_insurance[841023,263,31171]"
      exit 1
    end

    loan_amount = Integer(args[:loan_amount])
    months = Integer(args[:months])
    total_life_insurance = Integer(args[:total_life_insurance])

    # Approximation: average outstanding balance ≈ loan_amount / 2
    # Sum of monthly outstanding balances ≈ loan_amount * months / 2
    # monthly_percent = total_life_insurance / sum(outstanding_balances)
    monthly_percent_decimal = (2.0 * total_life_insurance) / (loan_amount * months)
    monthly_percent_percent = monthly_percent_decimal * 100.0
    initial_month_insurance = loan_amount * monthly_percent_decimal

    puts "Loan amount: #{format('%.2f', loan_amount)}"
    puts "Months: #{months}"
    puts "Total life insurance: #{format('%.2f', total_life_insurance)}"
    puts "Monthly percent (decimal): #{monthly_percent_decimal}"
    puts "Monthly percent (%): #{format('%.6f', monthly_percent_percent)}%"
    puts "Initial monthly life insurance: #{format('%.2f', initial_month_insurance)}"
    puts "Annualized approx (%): #{format('%.6f', monthly_percent_percent * 12)}% (monthly*12)"
  end
end
