# Module 12 Completion Report

## Instruction File
- Filename: instructions/Interest_calculator.agent.md

- **Purpose:** calculate compound interest on a lump sum by running `./tools/compound_interest.py`, so figures come from the tool and not from manual arithmetic.

- **When to use:**
  + The user asks for the final amount, future value, or interest earned on a single principal with a fixed annual rate, a fixed compounding frequency, and a known duration.
  + Do not use it for recurring deposits or withdrawals, variable rates, taxes or fees, or simple (non-compounded) interest; say so instead of approximating.

- **Input format:**
  + Four positional arguments, in this order: `PRINCIPAL RATE COMPOUNDS YEARS`.
    + `PRINCIPAL`: initial amount, greater than 0; plain number with no currency symbol or thousands separators.
    + `RATE`: annual rate as a percentage, greater than 0 (`7.34` means 7.34%, not `0.0734`).
    + `COMPOUNDS`: compounds per year, a whole number greater than 0 (annual 1, semi-annual 2, quarterly 4, monthly 12, daily 365).
    + `YEARS`: total time in years, greater than 0; may be fractional.
  + Convert mixed durations to years as years + months / 12 (8 years 7 months = `103/12`) and pass the unrounded value.
  + Ask the user for any missing value; do not assume a compounding frequency.
  + Example: `python tools/compound_interest.py 15847 7.34 12 8.583333333333334`.

- **Processing steps:**
  + Normalize the inputs as described above.
  + Run the command from the repository root.
  + On a usage error, correct the reported argument and run again; do not fall back to a manual calculation.
  + If `python` is not on PATH, use the full path to the installed `python.exe`.

- **Output format:**
  + The tool prints `Final amount:` and `Interest earned:`, rounded to 2 decimals with thousands separators.
  + Report both values with the user's currency symbol and restate the inputs (principal, rate, compounding frequency, duration).
  + Example: "$15,847 at 7.34% compounded monthly for 8 years 7 months grows to **$29,697.95**, earning **$13,850.95** in interest."

- **Constraints:**
  + Never present figures the tool did not produce; do not recompute or re-round them.
  + Rounding applies to display only; mention it if the user needs exact values.
  + The result is an illustration of the stated inputs, not financial advice.

## Script File
- Filename: tools/compound_interest.py
- Language: Python

```python
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
```

## Script Execution Output
```
> python tools/compound_interest.py --help
usage: compound_interest.py [-h] principal rate compounds years

Calculate compound interest.

positional arguments:
  principal   initial amount
  rate        annual interest rate in percent (e.g. 7.34)
  compounds   compounds per year (e.g. 12 for monthly)
  years       total time in years (may be fractional)

options:
  -h, --help  show this help message and exit

> python tools/compound_interest.py 15847 7.34 12 (103/12)
Final amount:    29,697.95
Interest earned: 13,850.95
```
