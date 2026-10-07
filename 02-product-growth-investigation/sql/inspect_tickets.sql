SELECT
    subject,
    priority,
    COUNT(ticket_id) AS ticket_count
FROM 'data/tickets.csv'
GROUP BY subject, priority
ORDER BY ticket_count DESC
LIMIT 15;