# ENTERPRISE PROJECT CHARTER & GOVERNANCE SPECIFICATION
**Project Name:** Olist Logistics Network Operational Transformation  
**Project Code:** OLIST-OPS-2026-Q1  
**Project Sponsor:** Chief Operating Officer (COO) & Chief Financial Officer (CFO)  
**Lead Business Decision Architect:** [Your Name]  
**Effective Date:** Phase I Execution Window  

---

## 1. Project Purpose & Business Case
Over consecutive operating quarters, Olist experienced a 73% deterioration in operating 
profitability alongside escalating customer delivery complaints, despite steady top-line GMV growth. 

Carrier freight expenditures escalated to R$ 2,250,000, driven by uncontrolled cross-country 
shipments and uncoordinated multi-seller orders. This project authorizes a comprehensive data 
investigation and software-driven operational transformation to restore unit economics without 
expanding physical infrastructure.

---

## 2. Measurable Business Objectives & Success Criteria
The project will be certified as successful upon achieving the following verifiable targets:
1. **Operating Cost Reduction:** Achieve a minimum **12.0% reduction in quarterly logistics spend** 
   (minimum baseline savings of **R$ 270,000 / quarter**).
2. **Delivery SLA Recovery:** Increase on-time delivery SLA compliance from 65% to **$\ge 85\%$**.
3. **Customer Satisfaction:** Reduce delivery-related 1-star reviews by at least **35%**.
4. **Rapid Capital Payback:** One-time software implementation cost (R$ 39,800) must pay for itself 
   within **under 30 days** of full deployment.

---

## 3. Management Constraints & Non-Negotiables
Executive leadership and the Board of Directors have established five binding constraints:
* **Constraint 1 (Headcount):** Zero additional operational, support, or engineering headcount authorized.
* **Constraint 2 (CapEx / Real Estate):** Zero leasing or acquisition of physical warehouse real estate (strict asset-light execution).
* **Constraint 3 (Delivery Integrity):** Customer delivery transit times cannot deteriorate as a result of cost cuts.
* **Constraint 4 (Timeline):** Full analytical diagnosis, process redesign, BRD specification, and backlog delivery completed within **one single fiscal quarter (12 weeks)**.
* **Constraint 5 (Toolchain Cost):** Zero software license expenditure; all architecture must execute on open-source, community, or free-tier platforms.

---

## 4. Scope Boundaries

### In-Scope:
* Forensic SQL audit of 100,000 production transactions across the Olist database.
* End-to-end process remodeling using BPMN 2.0 (As-Is and To-Be architectures).
* Engineering of the automated Order Management System (OMS) regional geo-fencing algorithm.
* Implementation of the automated Margin Floor Guardrail engine (R$ 15.00 threshold).
* Construction of an Agile Jira Scrum Backlog (Epics, Stories, Story Points, Sprint 1).
* Dynamic 3-scenario operational financial engine with sensitivity modeling.

### Out-of-Scope:
* Physical fleet acquisition or private truck operations.
* Front-end consumer UI redesign of partner marketplace checkout flows.
* Renegotiating national postal carrier master freight contracts.

---

## 5. Governance & Stakeholder RACI Matrix

| Stakeholder Role | Function | Project RACI Designation |
| :--- | :--- | :---: |
| **Chief Operating Officer (COO)** | Executive Sponsor | **Accountable (A)** |
| **Chief Financial Officer (CFO)** | Financial Sponsor & Budget Approver | **Accountable (A)** |
| **Lead Business Decision Architect** | Turnaround Design, Analytics & Engineering Specs | **Responsible (R)** |
| **VP of Logistics & Transportation** | Carrier Contracts & Ground Freight Operations | **Consulted (C)** |
| **Head of Merchant Operations** | Partner Seller Compliance & Packaging Discipline | **Consulted (C)** |
| **Customer Support Lead** | CRM Webhooks & Exception Resolution Workflows | **Informed (I)** |
| **Engineering Lead / Scrum Master** | Sprint Backlog Execution & Deployment | **Responsible (R)** |

*RACI Definitions:*  
* **R (Responsible):** The role that does the work to achieve the deliverable.  
* **A (Accountable):** The executive who holds ultimate veto and approval authority.  
* **C (Consulted):** Domain experts whose inputs and feedback are mandatory.  
* **I (Informed):** Teams kept updated on progress and deployment schedules.

---

## 6. Phased Milestone Schedule

| Phase Milestone | Target Deliverable | Status |
| :--- | :--- | :---: |
| **Milestone 1: Investigation** | Cleaned SQL schema, 5 core investigative queries, evidence register | **Complete** |
| **Milestone 2: Process Design** | As-Is and To-Be BPMN 2.0 diagrams with automated control gateways | **Complete** |
| **Milestone 3: Requirements** | Formal EARS Business Requirements Document (BRD) & Gherkin AC | **Complete** |
| **Milestone 4: Agile Backlog** | 29-point Jira Scrum Backlog across 3 Epics with Sprint 1 planned | **Complete** |
| **Milestone 5: Financial Model**| Dynamic Excel engine proving R$ 271,860 savings (12.08%) & sensitivity | **Complete** |
| **Milestone 6: Publication** | Flagship Case Study 01 README documentation on GitHub | **Active** |

---

## 7. Risk & Mitigation Register

| Risk Event | Severity | Probability | Planned Mitigation Strategy |
| :--- | :---: | :---: | :--- |
| **Carrier Rate Spike** | High | Low | Margin floor dynamically evaluates live freight; halts orders if shipping exceeds commission. |
| **Seller Packaging Delays** | Medium | Medium | Automated 48-hour background SLA audit job flags delinquent merchants and penalizes ranking. |
| **Carrier API Outages** | High | Medium | Circuit-breaker pattern implemented in `OLIST-8` with fallback to internal static rate cards. |
| **Customer Substitute Rejection**| Medium | Low | Automated 48-hour timeout triggers clean 100% refund with R$ 10 goodwill credit voucher. |

---

## 8. Executive Approvals & Sign-Off

```text
Approved by: _____________________________       Date: _______________
             Chief Operating Officer (COO)

Approved by: _____________________________       Date: _______________
             Chief Financial Officer (CFO)

Certified by: _____________________________      Date: _______________
             Lead Business Decision Architect