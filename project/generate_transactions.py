"""
generate_transactions.py
------------------------
Synthetic data generator for a retail banking transactions warehouse.

Produces four CSV files that map to a star-schema dimensional model:
  - transactions.csv   : fact table  (500 000 rows)
  - accounts.csv       : dimension   (100 accounts)
  - dim_date.csv       : date dimension covering the full calendar year
  - dim_merchant.csv   : merchant dimension derived from the fact data

Run this script once before loading data into the warehouse.
Output files are written to the current working directory.
"""

import random
import csv
from datetime import date, timedelta

# ---------------------------------------------------------------------------
# Reference data
# ---------------------------------------------------------------------------

# Spending categories used to classify every transaction
CATEGORIES = ['groceries', 'rent', 'dining', 'transport', 'utilities']

# Pool of realistic Canadian merchants per category.
# Merchant names are drawn randomly during transaction generation.
MERCHANTS = {
    'groceries': ['Walmart', 'Loblaws', 'No Frills', 'Costco', 'Metro'],
    'rent': ['Skyline Properties', 'First Capital', 'Boardwalk REIT'],
    'dining': ['Tim Hortons', 'McDonalds', 'Osmow\'s', 'The Keg', 'Pho 99'],
    'transport': ['Uber', 'TTC', 'Presto', 'Enterprise', 'Petro Canada'],
    'utilities': ['Rogers', 'Bell', 'Enbridge', 'Toronto Hydro', 'Reliance']
}

# ---------------------------------------------------------------------------
# Generation parameters — adjust these to scale the dataset up or down
# ---------------------------------------------------------------------------

NUM_ACCOUNTS = 100          # Total number of unique bank accounts to create
NUM_TRANSACTIONS = 500000   # Total rows in the fact table
START_DATE = date(2024, 1, 1)
END_DATE   = date(2024, 12, 31)


# ---------------------------------------------------------------------------
# Generator functions
# ---------------------------------------------------------------------------

def generate_transactions():
    """
    Build the fact table: one row per financial transaction.

    Each transaction is assigned a random account, category, merchant,
    amount (CAD 5.00 – 2000.00), and date within the configured date range.

    Returns:
        list[dict]: List of transaction records ready to be written to CSV.
    """
    transactions = []
    date_range = (END_DATE - START_DATE).days  # total number of days available

    for i in range(NUM_TRANSACTIONS):
        account_id = random.randint(1, NUM_ACCOUNTS)
        category   = random.choice(CATEGORIES)
        merchant   = random.choice(MERCHANTS[category])  # merchant is always consistent with category
        amount     = round(random.uniform(5.0, 2000.0), 2)
        txn_date   = START_DATE + timedelta(days=random.randint(0, date_range))

        transactions.append({
            'txn_id':     i + 1,       # surrogate key, 1-based
            'account_id': account_id,
            'category':   category,
            'merchant':   merchant,
            'amount':     amount,
            'txn_date':   txn_date
        })

    return transactions


def generate_accounts():
    """
    Build the accounts dimension: one row per unique bank account.

    Account IDs are sequential integers (1 – NUM_ACCOUNTS).
    Each account is randomly assigned one of three types:
    'checking', 'savings', or 'credit'.

    Returns:
        list[dict]: List of account records ready to be written to CSV.
    """
    account_types = ['checking', 'savings', 'credit']
    accounts = []

    for i in range(1, NUM_ACCOUNTS + 1):
        accounts.append({
            'account_id':   i,
            'account_name': f"Account {i}",
            'account_type': random.choice(account_types)
        })

    return accounts

def generate_dim_date():
    """
    Build the date dimension: one row for every calendar day in the date range.

    Includes time-intelligence attributes commonly needed in BI tools:
    day name, month name, quarter label, weekend flag, and month-end flag.

    The date_id (e.g. 20240101) is an integer surrogate key that matches the
    YYYYMMDD format — easy to join on from fact tables that store dates as integers.

    Returns:
        list[dict]: One record per date from START_DATE to END_DATE inclusive.
    """
    dates = []
    current = START_DATE

    while current <= END_DATE:
        dates.append({
            'date_id':       int(current.strftime('%Y%m%d')),  # e.g. 20240101
            'full_date':     current,
            'day_of_week':   current.weekday(),                # 0 = Monday, 6 = Sunday
            'day_name':      current.strftime('%A'),           # e.g. "Monday"
            'month_number':  current.month,
            'month_name':    current.strftime('%B'),           # e.g. "January"
            'quarter':       f'Q{(current.month - 1) // 3 + 1}',  # Q1–Q4
            'year':          current.year,
            'is_weekend':    current.weekday() >= 5,           # True for Sat & Sun
            # A day is month-end if the next day falls in a different month
            'is_month_end':  (current + timedelta(days=1)).month != current.month
        })
        current += timedelta(days=1)

    return dates


def generate_dim_merchant(transactions):
    """
    Build the merchant dimension from the already-generated transactions.

    Extracts every unique (merchant_name, category) pair seen in the fact data
    and assigns a sequential merchant_id. This ensures referential integrity —
    only merchants that actually appear in transactions are included.

    Args:
        transactions (list[dict]): Fact rows produced by generate_transactions().

    Returns:
        list[dict]: Deduplicated merchant records sorted by merchant name.
    """
    unique_merchants = set()

    # Collect unique (merchant, category) pairs from the fact table
    for t in transactions:
        unique_merchants.add((t['merchant'], t['category']))

    merchants = []
    # Sort for deterministic output order across runs
    for i, (merchant, category) in enumerate(sorted(unique_merchants), start=1):
        merchants.append({
            'merchant_id':   i,
            'merchant_name': merchant,
            'category':      category
        })

    return merchants

def generate_dim_account(accounts):
    """
    Build the account dimension from already-generated accounts.

    Sorts by account_id for deterministic output order across runs.
    Kept as a separate pass from generate_accounts() so the raw accounts list
    remains available for upstream use (e.g. seeding foreign keys).

    Args:
        accounts (list[dict]): Records produced by generate_accounts().

    Returns:
        list[dict]: Account records sorted by account_id, ready to write to CSV.
    """

    dim_accounts = []
    
    for account in sorted(accounts, key=lambda x: x['account_id']):
        dim_accounts.append({
            'account_id':   account['account_id'],
            'account_name': account['account_name'],
            'account_type': account['account_type']
        })

    return dim_accounts


# ---------------------------------------------------------------------------
# Main execution: generate data and write each table to its own CSV file
# ---------------------------------------------------------------------------

if __name__ == "__main__":

    # --- Raw table: transactions ---
    print("Generating transactions...")
    transactions = generate_transactions()

    with open('transactions.csv', 'w', newline='') as f:
        fieldnames = ['txn_id', 'account_id', 'category', 'merchant', 'amount', 'txn_date']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(transactions)

    print(f"Done. {len(transactions)} rows written to transactions.csv")

    # --- Raw table: accounts ---
    print("Generating accounts...")
    accounts = generate_accounts()

    with open('accounts.csv', 'w', newline='') as f:
        fieldnames = ['account_id', 'account_name', 'account_type']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(accounts)

    print(f"Done. {len(accounts)} rows written to accounts.csv")

    # --- Dimension: date ---
    print("Generating dim_date...")
    dim_date = generate_dim_date()

    with open('dim_date.csv', 'w', newline='') as f:
        fieldnames = [
            'date_id', 'full_date', 'day_of_week', 'day_name',
            'month_number', 'month_name', 'quarter', 'year',
            'is_weekend', 'is_month_end'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(dim_date)

    print(f"Done. {len(dim_date)} rows written to dim_date.csv")

    # --- Dimension: merchant (derived from transactions, so must run last) ---
    print("Generating dim_merchant...")
    dim_merchant = generate_dim_merchant(transactions)

    with open('dim_merchant.csv', 'w', newline='') as f:
        fieldnames = ['merchant_id', 'merchant_name', 'category']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(dim_merchant)

    print(f"Done. {len(dim_merchant)} rows written to dim_merchant.csv")

    # --- Dimension: account (derived from accounts, so must run last) ---
    print("Generating dim_account...")
    dim_account = generate_dim_account(accounts)

    with open('dim_account.csv', 'w', newline='') as f:
        fieldnames = ['account_id', 'account_name', 'account_type']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(dim_account)

    print(f"Done. {len(dim_account)} rows written to dim_account.csv")

