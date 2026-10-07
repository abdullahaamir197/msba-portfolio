# Horizon B2B Systems
## Enterprise KPI Governance Standard

> **Document reference:** SSOT-GOV-2025-Q3  
> **Effective date:** Q3 post-mortem audit  
> **Owner:** Lead Business Decision Architect  
> **Approvers:** CFO, Head of Sales, VP of Product, Head of Customer Support  
> **Status:** Active and binding

## 1. Governance mandate

This standard is the single source of truth for commercial, product, and support metrics. It prevents departments from changing numerators, denominators, or reporting windows to produce incompatible results.

Any change to a metric definition requires documented architectural review and approval from the owning stakeholder.

## 2. Departmental rules

1. **Sales:** Calculate win rate only from completed opportunities (`Closed Won` and `Closed Lost`). Open stages such as `Prospecting`, `Negotiation`, and `Demo Scheduled` are excluded from realized revenue and win-rate denominators.
2. **Customer Support:** Calculate resolution latency from `createdate` to `closed_date`. Priority must reflect operational severity and may not be downgraded to meet an SLA.
3. **Finance:** Recognize realized ARR from payment-confirmed `Closed Won` deals, not projected pipeline value.

## 3. Enterprise metric dictionary

| Metric | Definition | Technical logic | Source | Cadence | Owner |
| --- | --- | --- | --- | --- | --- |
| **Closed Won Revenue** | Cash value of successfully won contracts. | `SUM(amount) WHERE stage = 'Closed Won'` | `fact_deals.amount` | Monthly / quarterly | Sales and Finance |
| **Deal Win Rate** | Percentage of completed opportunities won. | `Closed Won / (Closed Won + Closed Lost) * 100` | `fact_deals.stage` | Monthly | Head of Sales |
| **Pipeline Drop-Off Rate** | Percentage of opportunities that reach `Closed Lost`. | `Closed Lost / COUNT(deal_id) * 100` | `fact_deals.stage` | Monthly | Head of Sales |
| **Repeat Account Retention** | Percentage of cohort accounts closing a second deal within 180 days of the first. | `Retained cohort accounts / starting cohort accounts * 100` | `fact_deals.company_id`, `fact_deals.close_date` | Cohort-based (M0–M6) | Product and Sales |
| **Ticket Resolution Latency** | Average elapsed time from ticket creation to resolution. | `AVG((closed_date - createdate) in hours)` | `fact_tickets.createdate`, `fact_tickets.closed_date` | Weekly / monthly | Head of Customer Support |
| **High-Priority Ticket Backlog** | Open urgent or high-priority incidents. | `COUNT(ticket_id) WHERE priority IN ('High', 'Urgent') AND status <> 'Closed'` | `fact_tickets.priority`, `fact_tickets.status` | Daily / continuous | Head of Customer Support |
| **Support Churn-Risk Lead Time** | Advance warning between a qualifying support issue and a lost deal or cancellation. | `deal_close_date - ticket_createdate` in days where resolution exceeds 24 hours | `fact_deals.close_date`, `fact_tickets.createdate` | Monthly audit | Decision Architect |

## 4. Quality controls

- Use `NULLIF` when calculating ratios to prevent divide-by-zero errors.
- Validate that date fields are parseable before calculating elapsed time.
- Reconcile dashboard totals to the source CSVs after each refresh.
- Document any filter, cohort, or stage change in the relevant SQL and Power BI measure.

## Related assets

- Data model: [`DATA_MODEL_ARCHITECTURE.md`](./DATA_MODEL_ARCHITECTURE.md)
- SQL analyses: [`sql/`](./sql/)
- Power BI report: [`power-bi/horizon_analytics.pbix`](./power-bi/horizon_analytics.pbix)
