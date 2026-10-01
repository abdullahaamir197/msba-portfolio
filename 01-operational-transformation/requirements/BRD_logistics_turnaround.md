# BUSINESS REQUIREMENTS DOCUMENT (BRD)
## Project: Olist Marketplace Logistics Turnaround & Routing Optimization
**Document Version:** 1.0  
**Status:** Certified Architecture Specification  
**Author:** Lead Business Decision Architect  
**Stakeholders:** Chief Operating Officer (COO), Chief Financial Officer (CFO), VP Logistics, VP Customer Support  

---

## 1. Executive Summary & Business Context
Between 2016 and 2018, Olist experienced rapid top-line transaction growth across Brazil, accompanied 
by severe operational margin decay and customer satisfaction degradation. 

Our SQL root-cause investigation across 99,441 production orders revealed:
* **The Freight Leak:** Over 65% of freight expenditure was burned on cross-state interstate shipping, 
  with long-haul parcels costing up to R$ 45–85+ compared to R$ 15 for local fulfillment.
* **The Transit Bottleneck:** Sellers achieved an average dispatch latency of 2.8 days (meeting 
  internal packaging SLAs 88% of the time). Delivery SLA breaches were 100% driven by carrier transit times (12.5 to 25+ days).
* **The Customer Impact:** Late deliveries resulted in a catastrophic drop in review score 
  from 4.29 stars down to 1.64 stars, with 56.2% of late orders generating toxic 1-star reviews.

Executive leadership has authorized an operational turnaround to implement automated routing 
guardrails, seller SLA controls, and proactive customer exception handling.

---

## 2. Business Objectives & Success Metrics (KPIs)
All requirements in this document must directly serve five board-level constraints:
1. **Logistics Cost Reduction:** Reduce total freight and fulfillment operating expenses by **12.0%** 
   (minimum quarterly savings of **R$ 270,000**).
2. **Delivery SLA Compliance:** Increase on-time delivery rate from 65% to **$\ge 85\%$**.
3. **Customer CSAT Recovery:** Reduce the volume of delivery-related 1-star reviews by at least **35%**.
4. **Headcount Boundary:** Zero additional operational or engineering headcount.
5. **CapEx Boundary:** Zero physical warehouse acquisition or real estate leasing.

---

## 3. Project Scope

### In-Scope:
* Order Management System (OMS) regional seller geo-matching logic.
* Automated Order Margin Floor Guardrail calculation engine.
* Automated 48-Hour Seller Dispatch SLA monitoring service.
* CRM webhook integration for automated customer hold notifications and refund processing.

### Out-of-Scope:
* Building or leasing physical cross-dock warehouses (asset-light platform execution only).
* Redesigning marketplace front-end checkout UI.
* Renegotiating national postal carrier master freight contracts.

---

## 4. Functional Requirements (EARS Syntax)

### FR-01: Regional Geo-Fencing & Seller Matching
* **Trigger (Event-Driven):**  
  **WHEN** a customer places an order, the Olist OMS **SHALL** query the inventory database and 
  identify all active sellers stocking the requested SKU.
* **Logic:**  
  **IF** one or more sellers are located within the same state as the customer (`seller_state == customer_state`),  
  **THEN** the OMS **SHALL** assign the order to the local seller with the highest historical fulfillment rating.

### FR-02: Margin Floor Economic Guardrail
* **Calculation:**  
  **WHEN** no in-state seller is available, the OMS **SHALL** calculate the projected contribution margin:  
  $$\text{Margin} = \text{Marketplace Commission} - \text{Estimated Carrier Freight}$$
* **Exception Rule (Unwanted Event):**  
  **IF** the projected contribution margin is less than **R$ 15.00**,  
  **THEN** the OMS **SHALL** block automated carrier label generation,  
  **AND** update the order status to `'LOGISTICS_HOLD'`,  
  **AND** dispatch an automated webhook payload to the Support CRM system.

### FR-03: Seller Dispatch SLA Monitoring
* **SLA Rule:**  
  **IF** a seller has not confirmed package handoff to the carrier within **48 hours** of order assignment,  
  **THEN** the system **SHALL** update the order status to `'DISPATCH_BREACH'`,  
  **AND** generate an urgent priority escalation ticket in the merchant management queue.

### FR-04: Automated Customer Exception Resolution
* **Resolution Rule:**  
  **WHILE** an order remains in `'LOGISTICS_HOLD'`, the CRM system **SHALL** present the customer with 
  an automated digital choice: (A) accept a verified in-region substitute SKU, or (B) receive an 
  immediate 100% refund with an automated R$ 10 goodwill marketplace voucher.

---

## 5. Non-Functional Requirements (NFRs)
* **NFR-01 (Routing Latency):** The regional seller geo-matching and margin calculation engine 
  **SHALL** execute in less than **350 milliseconds** per order under standard load.
* **NFR-02 (Throughput Capacity):** The routing service **SHALL** support a sustained throughput of 
  at least **1,200 concurrent order evaluations per minute** during promotional peak events.
* **NFR-03 (System Availability):** The OMS routing engine and decision services **SHALL** maintain 
  a minimum uptime of **99.95%** outside scheduled maintenance windows.
* **NFR-04 (Data Privacy):** All customer shipping addresses and geographic coordinates **SHALL** 
  be encrypted in transit (TLS 1.3) and at rest (AES-256), adhering to Brazilian LGPD compliance.

---

## 6. System Dependencies & Integrations
* **OMS $\leftrightarrow$ Merchant WMS:** REST API over HTTPS for real-time order dispatch notifications.
* **OMS $\leftrightarrow$ Carrier Freight Engine:** Real-time rate calculation API to estimate shipping costs based on package weight and postal zone.
* **OMS $\leftrightarrow$ Support CRM:** Webhook publisher to broadcast order status changes (`'LOGISTICS_HOLD'`, `'DISPATCH_BREACH'`) directly to Zendesk/customer support queues.

---

## 7. Acceptance Criteria (Gherkin Scenarios)

### Scenario 1: Successful Local Route Assignment
* **GIVEN** a customer in São Paulo (`SP`) places an order for Product `P-100`,
* **AND** Seller `S-01` in São Paulo (`SP`) has Product `P-100` in stock,
* **WHEN** the OMS routing algorithm processes the order,
* **THEN** the order **SHALL** be assigned to Seller `S-01`,
* **AND** the shipping route type **SHALL** be stamped as `'INTRASTATE_LOCAL'`,
* **AND** the delivery SLA target **SHALL** be set to 4 business days.

### Scenario 2: Unprofitable Interstate Order Blocked
* **GIVEN** a customer in Bahia (`BA`) places an order with a gross profit commission of R$ 10.00,
* **AND** the nearest available seller is in São Paulo (`SP`) with estimated freight of R$ 35.00 *(Projected Margin = -R$ 25.00)*,
* **WHEN** the OMS evaluates the order against the margin floor,
* **THEN** the order status **SHALL** be updated to `'LOGISTICS_HOLD'`,
* **AND** automated carrier dispatch **SHALL** be prevented,
* **AND** a notification payload **SHALL** be received by the CRM within 1,000ms.