# Household template packs (seven businesses)

Short fit matrix for the high-fit household IndustryTemplate packs. Same engine as [ADR-004](decisions/ADR-004-business-resources.md): ResourceType + workflow + FieldDef — no schema forks.

| Business | Pack id | Engine | Notes |
|----------|---------|--------|--------|
| Marriage Decorations | `marriage_decor` | Rental | Chairs, stage, flowers, lights, fans, generator |
| Birthday Decorations | `birthday_decor` | Rental | Balloon gear, frames, LED numbers |
| Tractor / Harvest / Tanker | `farm` (extended) | Rental | Tractor, harvester, water tanker; fields: driver, village, hours, acres |
| Temple | `temple` | Rental (+ sale) | Chairs, sound, hall booking; optional donation sale line |
| Mobile repair | `mobile_repair` | Job + sale | Repair jobs + parts; fields: IMEI, notes |
| Laptop repair | `laptop_repair` | Job + sale | Repair jobs + accessories; fields: password note, notes |
| Tailor | `tailor` | Job (+ sale) | Stitching jobs; fields: measurements, trial/delivery dates |
| Beauty Parlour | `parlour` / `salon` (enhanced) | Service + job + membership (+ sale) | Packages, products, membership |

Out of scope for this slice: water can, gas, caterer, laundry, milkman, and other household verticals not listed above.
