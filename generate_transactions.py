import random
import csv
from datetime import date, timedelta

CATEGORIES = ['groceries', 'rent', 'dining', 'transport', 'utilities']

MERCHANTS = {
    'groceries': ['Walmart', 'Loblaws', 'No Frills', 'Costco', 'Metro'],
    'rent': ['Skyline Properties', 'First Capital', 'Boardwalk REIT'],
    'dining': ['Tim Hortons', 'McDonalds', 'Osmow\'s', 'The Keg', 'Pho 99'],
    'transport': ['Uber', 'TTC', 'Presto', 'Enterprise', 'Petro Canada'],
    'utilities': ['Rogers', 'Bell', 'Enbridge', 'Toronto Hydro', 'Reliance']
}

NUM_ACCOUNTS = 100
NUM_TRANSACTIONS = 500000
START_DATE = date(2024, 1, 1)
END_DATE = date(2024, 12, 31)

def generate_transactions():
    transactions = []
    date_range = (END_DATE - START_DATE).days

    for i in range(NUM_TRANSACTIONS):
        account_id = random.randint(1, NUM_ACCOUNTS)
        category = random.choice(CATEGORIES)
        merchant = random.choice(MERCHANTS[category])
        amount = round(random.uniform(5.0, 2000.0), 2)
        txn_date = START_DATE + timedelta(days=random.randint(0, date_range))

        transactions.append({
            'txn_id': i + 1,
            'account_id': account_id,
            'category': category,
            'merchant': merchant,
            'amount': amount,
            'txn_date': txn_date
        })

    return transactions

def generate_accounts():
    account_types = ['checking', 'savings', 'credit']
    accounts = []

    for i in range(1, NUM_ACCOUNTS + 1):
        accounts.append({
            'account_id': i,
            'account_name': f"Account {i}",
            'account_type': random.choice(account_types)
        })

    return accounts

print("Generating transactions...")
transactions = generate_transactions()



with open('transactions.csv', 'w', newline='') as f:
    fieldnames = ['txn_id', 'account_id', 'category', 'merchant', 'amount', 'txn_date']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(transactions)

print(f"Done. {len(transactions)} rows written to transactions.csv")

print("Generating accounts...")
accounts = generate_accounts()

with open('accounts.csv', 'w', newline='') as f:
    fieldnames = ['account_id', 'account_name', 'account_type']
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(accounts)

print(f"Done. {len(accounts)} rows written to accounts.csv")



