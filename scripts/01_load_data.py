"""Load the raw Online Retail II Excel file into a DuckDB database.

The Excel file has two sheets (2009-2010 and 2010-2011). We stack them into
one table, `raw_transactions`, so every later step can be done in SQL.

Run from the project folder:
    python scripts/01_load_data.py
"""
from pathlib import Path

import duckdb
import pandas as pd

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
EXCEL_FILE = DATA_DIR / "online_retail_II.xlsx"
DB_FILE = DATA_DIR / "retail.duckdb"

print(f"Reading {EXCEL_FILE.name} (takes a minute or two)...")
sheets = pd.read_excel(EXCEL_FILE, sheet_name=None, dtype={"Invoice": str, "StockCode": str})
raw = pd.concat(sheets.values(), ignore_index=True)

# Friendlier column names for SQL: no spaces, lower case
raw.columns = ["invoice", "stock_code", "description", "quantity",
               "invoice_date", "price", "customer_id", "country"]

con = duckdb.connect(str(DB_FILE))
con.execute("CREATE OR REPLACE TABLE raw_transactions AS SELECT * FROM raw")
rows = con.execute("SELECT COUNT(*) FROM raw_transactions").fetchone()[0]
print(f"Loaded {rows:,} rows into {DB_FILE.name}")
con.close()
