principal = 15847
annual_rate = 0.0734
periods_per_year = 12
years, months = 8, 7

n = years * periods_per_year + months
monthly_rate = annual_rate / periods_per_year

amount = principal * (1 + monthly_rate) ** n
interest = amount - principal

print(f"Periods (months): {n}")
print(f"Final amount:     ${amount:,.2f}")
print(f"Total interest:   ${interest:,.2f}")
