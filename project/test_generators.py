from generate_transactions import generate_accounts, generate_dim_account

def test_dim_account():
    accounts_data = generate_accounts()
    result = generate_dim_account(accounts_data)
    
    # Check row count
    assert len(result) == 100, f"Expected 100 rows, got {len(result)}"
    
    # Check columns exist
    assert 'account_id' in result[0], "Missing account_id"
    assert 'account_name' in result[0], "Missing account_name"
    assert 'account_type' in result[0], "Missing account_type"
    
    # Check no duplicates
    ids = [r['account_id'] for r in result]
    assert len(ids) == len(set(ids)), "Duplicate account_ids found"
    
    print(f"All tests passed — {len(result)} rows, no duplicates")
    print(result[:3])

test_dim_account()