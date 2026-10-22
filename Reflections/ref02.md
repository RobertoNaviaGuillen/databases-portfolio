# Reflection 2 (Module 2): Data Contracts & Reading Legacy Schemas

Back to [Module 2](../module-02/README.md)

## What worked?

Understanding that **every many-to-many relationship needs a junction (bridge) table**. It clicked when I had to explain it back to a pod mate, and then I proved it myself: in my m:n sketch, order 1 uses 2 parts **and** part P-1001 is used by 2 orders, and the junction table rejects the same part twice on one order. Finding defects by eye first (the `unknown` date, the duplicated part) and then proving them with queries also worked well.

## What broke? What was difficult?

This module was harder for me than Module 1. The most difficult parts were the basic concepts I had to ask about: what an entity, an attribute and a relationship are, and what 1:1, 1:n and m:n mean. In Task B I got two of four scenarios wrong: I chose a list column for an m:n relationship and treated the technician as just a name. Those are exactly the defects of the legacy schema, so I made the same mistakes as its original designer.

## How did my mental model shift?

Before, I thought that when a database looks up information it goes **only to the correct data**, as if it checked the data by itself. Now I know that a database returns **whatever was stored**, including wrong data, unless someone wrote the rules: the legacy schema accepted a job on a machine that does not exist, a duplicated part, a price stored as text and the word `unknown` as a date, without any error. That is why tables have to be built with a lot of attention to detail, and why the contract needs two guards: the database (foreign keys, `UNIQUE`) and the application (Pydantic, for formats like real dates).

## How did I verify AI suggestions?

I used an AI assistant (Claude) to explain the concepts and to check my pod's EER diagram, and I did not take its answers on trust: every cardinality is proved with a `COUNT` on `legacy.db`, every defect with a query and its result, and the EER explanation was compared with the workbook and with Leviscus's study log. One answer was over-confident: the AI called machine ↔ serial number an "accidental 1:1", but the counts only describe this sample; nothing in the schema enforces it. Details in my [study log](../module-02/study-log.md#4-llm-qa-claude-and-how-i-verified-it).

## Help and extra work

- My pod ([Leviscus Njeru](https://github.com/leviscusgnjeru/databases), Ian Okach, Chanbopha Rin) explained the EER overlap example; Leviscus made and shared the image we used in Task C.
- I used **Claude (AI)** as an assistant to build the database, run the queries and write the contract, and it explained each result to me in simple terms.
