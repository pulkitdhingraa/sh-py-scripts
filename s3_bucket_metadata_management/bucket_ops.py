# Objective

# Using the provided JSON file, implement the following:

# Print a summary of each bucket: Name, region, size (in GB), and versioning status
# Identify buckets larger than 80 GB from every region which are unused for 90+ days.
# Generate a cost report: total s3 buckets cost grouped by region and department.
# Highlight buckets with:
    # Size > 50 GB: Recommend cleanup operations.
    # Size > 100 GB and not accessed in 20+ days: Add these to a deletion queue.
# 4. Provide a final list of buckets to delete (from the deletion queue). For archival candidates, suggest moving to Glacier.


# Implementation

# bucket_summary
# buckets > 80GB and last_used > 90 days
# cost_report_by_region, cost_report_by_dept
# print_deletion_queue

import json
from datetime import datetime

COST_STANDARD = 0.023
COST_GLACIER = 0.004

def load_buckets(file_path: str) -> dict:
    with open("buckets.json", "r") as f:
        return json.load(f)

def generate_bucket_summary(buckets: list[dict]) -> None:
    print("\n====== Bucket Summary ======")
    for bucket in buckets:
        print(f"Name: {bucket['name']}, Region: {bucket['region']}, Size: {bucket['sizeGB']} GB, Versioning: {bucket['versioning']}")

def large_unused_buckets(buckets: list[dict], size_threshold: int = 80, days_threshold: int = 90) -> None:
    print("\n====== Unused Buckets ======")
    for bucket in buckets:
        size = bucket['sizeGB']
        last_access_date = bucket.get('lastAccessed', bucket['createdOn'])
        days_passed = (datetime.now() - datetime.strptime(last_access_date, "%Y-%m-%d")).days
        if size > size_threshold and days_passed > 90:
            print(f"Unused bucket with Size: {size} GB not accessed in {days_passed} days")

def generate_cost_report(buckets: list[dict]) -> tuple[dict, dict]:
    region_cost, team_cost = {},{}

    for bucket in buckets:
        size = bucket['sizeGB']
        region = bucket['region']
        team = bucket['tags']['team']

        region_cost[region] = region_cost.get(region, 0) + (size * COST_STANDARD)
        team_cost[team] = team_cost.get(team, 0) + (size * COST_STANDARD)
    
    return region_cost, team_cost

def identify_buckets_for_removal_and_archive(buckets: list[dict]) -> tuple[list[str], list[str]]:
    deletion_queue, glacier_candidates = [], []
    for bucket in buckets: 
        size = bucket['sizeGB']
        last_access_date = bucket.get('lastAccessed', bucket['createdOn'])
        days_passed = (datetime.now() - datetime.strptime(last_access_date, "%Y-%m-%d")).days
        if size > 100 and days_passed > 20:
            deletion_queue.append(bucket['name'])
        elif size > 50:
            glacier_candidates.append(bucket['name'])
    return deletion_queue, glacier_candidates

def estimated_cost_savings(buckets: list[dict], glacier_candidates: list[str]) -> float:
    total_savings = 0.0
    for bucket in buckets:
        if bucket['name'] in glacier_candidates:
            size = bucket['sizeGB']
            savings = (size * COST_STANDARD) - (size * COST_GLACIER)
            print(f"Bucket: {bucket['name']}, Savings: {savings:.2f}$")
            total_savings += savings
    return total_savings

def main():
    buckets = load_buckets("buckets.json")["buckets"]

    generate_bucket_summary(buckets)

    large_unused_buckets(buckets)

    region_cost, team_cost = generate_cost_report(buckets)
    print("\n====== Cost by region =======")
    for region,cost in region_cost.items():
        print(f"Region: {region}, Cost: {cost:.2f}$")
    print("\n====== Cost by team =======")
    for team,cost in team_cost.items():
        print(f"Team: {team}, Cost: {cost:.2f}$") 

    deletion_queue, glacier_candidates = identify_buckets_for_removal_and_archive(buckets)
    print("\n====== Deletion Queue =======")
    for bucket_name in deletion_queue:
        print(f"- {bucket_name}")
    print("\n====== Glacier Candidates =======")
    for bucket_name in glacier_candidates:
        print(f"- {bucket_name}")
    
    print("\n====== Est Cost Savings moving to Glacier ======")
    estimated_cost_savings(buckets, glacier_candidates)

 
if __name__ == "__main__":
    main()