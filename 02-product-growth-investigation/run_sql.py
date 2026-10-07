import os
import sys
import duckdb

# Keep query outputs together so results are easy to review and compare.
RESULTS_DIR = os.path.join("sql", "results")
os.makedirs(RESULTS_DIR, exist_ok=True)

if len(sys.argv) > 1:
    sql_path = sys.argv[1]
    with open(sql_path, "r") as f:
        query = f.read()

    # Execute the selected query and materialize the result as a dataframe.
    df = duckdb.query(query).df()

    # Match the output filename to the source query.
    base_name = os.path.splitext(os.path.basename(sql_path))[0]
    output_csv = os.path.join(RESULTS_DIR, f"{base_name}_output.csv")

    # Save to CSV
    df.to_csv(output_csv, index=False)

    print(f"\nQuery completed: {sql_path}")
    print(f"Result saved to: {output_csv} ({len(df)} rows)")
    print(df.head(10))
else:
    print("Please provide a SQL file path, for example: python run_sql.py sql/my_query.sql")