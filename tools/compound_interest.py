"""Calculate compound interest.

Usage:
    python tools/compound_interest.py PRINCIPAL ANNUAL_RATE COMPOUNDS_PER_YEAR YEARS

ANNUAL_RATE is a percentage (e.g. 7.34 for 7.34%). YEARS may be fractional
(e.g. 8.5833 for 8 years and 7 months).
"""

import argparse


def positive(type_):
    def parse(value):
        number = type_(value)
        if number <= 0:
            raise argparse.ArgumentTypeError(f"must be greater than 0 (got {value})")
        return number

    return parse


def compound_interest(principal, annual_rate_pct, compounds_per_year, years):
    rate = annual_rate_pct / 100
    amount = principal * (1 + rate / compounds_per_year) ** (compounds_per_year * years)
    return amount, amount - principal


def main():
    parser = argparse.ArgumentParser(description="Calculate compound interest.")
    parser.add_argument("principal", type=positive(float), help="initial amount")
    parser.add_argument("rate", type=positive(float), help="annual interest rate in percent (e.g. 7.34)")
    parser.add_argument("compounds", type=positive(int), help="compounds per year (e.g. 12 for monthly)")
    parser.add_argument("years", type=positive(float), help="total time in years (may be fractional)")
    args = parser.parse_args()

    amount, interest = compound_interest(args.principal, args.rate, args.compounds, args.years)

    print(f"Final amount:    {amount:,.2f}")
    print(f"Interest earned: {interest:,.2f}")


if __name__ == "__main__":
    main()
