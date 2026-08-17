---
name: annotate-after-db-change
description: Run annotaterb after every database change. Use after creating, editing, or running migrations, changing db/schema.rb, adding or removing columns/tables/indexes, or otherwise changing the Active Record schema.
---

# Annotate after database change

After any database schema change, refresh model annotations with annotaterb.

## When to run

Run this after finishing the schema work, not before:

- adding, editing, or removing a migration
- running `db:migrate`, `db:rollback`, or `db:schema:load`
- changing `db/schema.rb`
- adding or removing tables, columns, indexes, or foreign keys

## Command

```bash
bundle exec annotaterb models
```

Include the updated annotated model files (and any annotaterb config the command changes) with the rest of the database work.

Do not skip this step when the migration already ran. The gem hook may annotate after `db:migrate`; if it did not, run the command above.
