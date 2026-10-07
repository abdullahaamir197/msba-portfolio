# Horizon B2B Systems
## Data Model Architecture

> **Phase:** Phase II — Product & Growth Investigation  
> **Architecture:** Kimball star schema  
> **Analytical engines:** DuckDB and Power BI Desktop  
> **Status:** Governed and implementation-ready

## Purpose

This specification defines the analytical model used to investigate retention, pipeline conversion, support-driven churn, and plan-level economics. It establishes table grains, key ownership, and relationship rules so that metrics remain consistent across SQL analysis and the Power BI semantic model.

## Dimensional model

```text
                         ┌──────────────────────────┐
                         │         dim_date         │
                         │  1 row = 1 calendar day  │
                         └────────────┬─────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
             ┌──────────────┐                   ┌───────────────┐
             │  fact_deals  │                   │ fact_tickets  │
             │ Sales events │                   │Support events │
             └──────┬───────┘                   └───────┬───────┘
                    │                                   │
                    └──────────────┬────────────────────┘
                                   ▼
                         ┌────────────────────┐
                         │   dim_companies    │
                         │ 1 row = 1 account  │
                         └─────────┬──────────┘
                                   │
                                   ▼
                         ┌────────────────────┐
                         │    dim_contacts    │
                         │  1 row = 1 person  │
                         └────────────────────┘

                         ┌────────────────────┐
                         │    dim_products    │
                         │ 1 row = 1 product  │
                         └────────────────────┘
```

## Tables and grain

| Table | Type | Grain | Primary key | Foreign keys |
| --- | --- | --- | --- | --- |
| `dim_companies` | Dimension | One customer account profile | `company_id` | — |
| `dim_contacts` | Dimension | One individual stakeholder | `contact_id` | `company_id` |
| `dim_products` | Dimension | One product or pricing tier | `product_id` | — |
| `dim_date` | Conformed dimension | One contiguous calendar day | `date_key` | — |
| `fact_deals` | Transaction fact | One sales opportunity or contract event | `deal_id` | `company_id`, `contact_id`, `close_date` |
| `fact_tickets` | Transaction fact | One customer-support incident | `ticket_id` | `associated_company_id`, `associated_contact_id`, `createdate`, `closed_date` |

## Relationship and filter rules

- Dimensions filter facts in a single direction: **one-to-many**.
- `dim_companies` is the shared account dimension for deals and tickets.
- `dim_date` is role-playing: it filters deal dates and ticket dates through the appropriate date key.
- Fact tables must not be joined directly to one another for additive measures unless the query explicitly controls grain and duplication.
- Measures involving both deals and tickets must aggregate each fact independently before combining results.
- Orphan foreign keys must be surfaced during data-quality checks rather than silently excluded.

## Analytical conventions

1. **Revenue:** Recognize realized revenue from `Closed Won` deals only.
2. **Win rate:** Use `Closed Won / (Closed Won + Closed Lost)`; exclude open pipeline stages from the denominator.
3. **Retention:** Define the cohort from the first qualifying `Closed Won` deal and measure subsequent activity by account.
4. **Ticket latency:** Calculate elapsed time between `createdate` and `closed_date`; open tickets remain unresolved.
5. **Currency and dates:** Preserve source values at row level and apply reporting-period logic through `dim_date`.

## Repository implementation

- SQL analyses: [`sql/`](./sql/)
- Source data: [`data/`](./data/)
- Research matrices: [`research/`](./research/)
- Power BI report: [`power-bi/horizon_analytics.pbix`](./power-bi/horizon_analytics.pbix)
- KPI definitions: [`KPI_GOVERNANCE.md`](./KPI_GOVERNANCE.md)
