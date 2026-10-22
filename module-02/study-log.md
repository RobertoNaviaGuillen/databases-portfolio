# Module 2: Study log

Back to [Module 2](README.md)

## Task A: Study in my pod

### 1. References I used

| Source | The one concept I understood best from it |
|---|---|
| [Module 2 workbook](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/02-data-contracts-and-legacy-schemas.md) | The cardinality table: 1:1, 1:n and m:n, and how each becomes a table |
| My pod's explanations ([Leviscus Njeru](https://github.com/leviscusgnjeru/databases), Ian Okach, Chanbopha Rin) | The EER overlap example: one person can be both student and lecturer |
| Explaining it back to a pod mate | **Every m:n relationship needs a junction (bridge) table.** Having to say it out loud is when it clicked |
| AI assistant (Claude), see the Q&A below | Entity vs. attribute: if it repeats across many rows and has its own data, it is a table |

### 2. Things I googled

Almost nothing; I used the AI assistant instead of searching, and checked its answers against the workbook and against queries on `legacy.db`.

### 3. Remarkable things

- **Tables need a lot of attention to detail.** Small design shortcuts (a name instead of a foreign key, a comma list, a number stored as text) let wrong and overlapping information in, and the database does not complain.
- **Defects multiply each other.** The duplicate `P-1003` row made job 2 appear twice in the join, while job 1 (`P-1001,P-1002`) silently disappeared.
- **SQLite accepted `'unknown'` in a `DATE` column**, and it ignores foreign keys unless `PRAGMA foreign_keys = ON`.
- My own wrong answers in Task B (a list column for m:n, technician as plain text) were exactly the legacy schema's defects: the same mistakes the original designer made.

### 4. LLM Q&A (Claude), and how I verified it

| My question | Summary of the answer | How I verified it |
|---|---|---|
| What are an entity, an attribute and a relationship, and what do 1:1, 1:n and m:n mean? | An entity is a thing with its own existence (Machine, Part, Technician); an attribute describes it (serial number); cardinality says "how many with how many" (passport, mother and children, students and courses) | Proved each cardinality on `legacy.db` with counts ([cardinality.sql](cardinality.sql)): 4 jobs on 3 machines (1:n), job 1 with 2 parts **and** P-1001 in 2 jobs (m:n) |
| Which errors does the legacy database have? (after I listed the ones I saw by eye) | Confirmed my three (`unknown` date, duplicate part, suspicious `RANDOM-NAME`) and pointed to three I missed (orphan `cnc-05`, comma list, price as text) | Did not take the list on trust: every defect is proved with a query and its result ([defects.sql](defects.sql)) |
| Is my pod's EER overlap diagram correct? | Correct; it does not show total vs. partial specialization, and classic EER draws overlap with a circle and an "o" | Compared with the workbook's EER section and with Leviscus's own study log, which notes the same total/partial gap |

**Where the AI was over-confident:** it called machine ↔ serial number an "accidental 1:1" in the legacy schema. The counts only show 4 machines with 4 distinct serials **in this sample**; nothing in the schema enforces it (`serial_no` is not `UNIQUE`). Leviscus wrote that the legacy schema represents no 1:1 at all. Both readings are defensible, and the count alone cannot prove a rule.

### 5. My two best ER sketches

I did not hunt for external sketches; the two that taught me the most came from my pod and from this module's own data:

1. **EER overlap example** by Leviscus Njeru (shown in Task C below): it taught me supertype/subtype and that subtypes can overlap.
2. **The reconstructed maintenance model** in [er-audit.md](er-audit.md#2-reconstructed-er-diagram-what-the-designer-meant): it taught me what the junction table `JOB_PART` looks like in a real repair, next to the broken `parts_used` column it replaces.

## Task B: From words to sketch

Done in [er-examples.md](er-examples.md): my answers to the four scenarios (two right, two wrong, with why), the four sketches, and the `CREATE TABLE` + `COUNT` proof of the m:n sketch ([er-proof.sql](er-proof.sql)).

## Task C: Explain & share with another pod

**When and who:** 17 October 2026, two days after I joined my Task Pod on 15 October ([Leviscus Njeru](https://github.com/leviscusgnjeru/databases), Ian Okach, Chanbopha Rin). I took part in the pod discussion and in the exchange with the neighbouring pod. Honestly, I did not fully understand the example during the discussion; I understood it afterwards by reviewing it on my own.

**The shared image:** the pod pair chose an EER example about a university. The image below was made and posted by **Leviscus Njeru** in our Discord channel (`#in-class-tasks`, 17 October 2026, 19:37); it is reused here with credit, as the image our pods agreed on. His documentation of the discussion is in [his study log](https://github.com/leviscusgnjeru/databases/blob/main/Module02/study-log.md).

![EER Overlap Example: PERSON as supertype, STUDENT and LECTURER as overlapping subtypes. Image by Leviscus Njeru.](pictures/EER_Overlap_Example.png)

### What the example shows (in my own words)

- **PERSON** is the general entity (the *supertype*). It holds what every person has: `person_id` and `full_name`.
- **STUDENT** and **LECTURER** are *subtypes*: special kinds of person with their own extra data (`student_number`, `staff_number`). They inherit `person_id` and `full_name` from PERSON, so those are not repeated.
- **"Overlap allowed"** means one person can be **both** at the same time, for example a lecturer who is also enrolled in a master's programme. The opposite would be **disjoint**: a person could be only one of the two.
- In tables, this means `STUDENT` and `LECTURER` each have a `person_id` that points to `PERSON`, and the **same `person_id` may appear in both**. The person is stored once, not twice.

### What I checked on my own afterwards

- **The diagram does not say whether every person must be a student or a lecturer** (total vs. partial specialization). Could the university store a person who is neither, for example an administrator? That is a separate business rule the picture does not answer.
- **Notation:** the triangle is a UML-style generalization symbol. In classic EER notation, overlap is drawn as a circle with an **"o"** and disjointness with a **"d"**. Same meaning, different notation.
- **Mermaid's `erDiagram` cannot draw inheritance** (the workbook says so), which is why the example is a separate image or a `classDiagram`.

### Agreed learning (pod discussion)

1. Shared data goes in the supertype (PERSON) and role-specific data in the subtypes (STUDENT, LECTURER).
2. Student and Lecturer **overlap**: one person can hold both roles, so the subtypes are not mutually exclusive.
3. In a relational design, both subtype tables reference the same `PERSON.person_id`, which avoids storing the same person twice.

**Left open:** whether every person must belong to at least one subtype (total) or not (partial); the example does not state it.
