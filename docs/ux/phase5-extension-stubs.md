# Phase 5 Extension Stubs

These are intentionally lightweight stubs so core rental UX remains stable.

## Voice search stub
- Add route-level placeholder for command-driven search.
- Future intent examples: "Find customer Priya", "Return rental REN-3001".

## Business templates
- **First launch:** empty DB requires choosing an industry template; the full pack seeds inventory and Home modules (no skip-empty in this pass).
- Afterward, **More → Business Templates**: pick an industry pack, multi-select starter items, then merge into inventory (duplicate names skipped).
- Packs: Library, Camera Rental, Farm Equipment, Event Rental, Construction/Tools, Office Assets, Beauty Parlour, Boutique, Gym Membership.
- Vocabulary/label presets (Library Edition-style relabeling) remain a later extension.

### Suggested packs (not implemented yet)
Candidates for later industry packs:
- Medical / mobility equipment (wheelchair, oxygen concentrator)
- Sports & adventure gear (bikes, tents, bats)
- Kids toys / party games
- Costume / theatre wardrobe
- Furniture / appliance rental
- Vehicle / two-wheeler short hire
- Wedding décor extras (beyond Event)
- Electronics loaner (phone/laptop while in repair)
- Coaching / tuition seat packs (monthly fees, like gym)
- Pet care boarding kennels / grooming packages

## AI suggestions stub
- Add non-intrusive suggestion panel on Home with actionable prompts.
- Keep suggestions read-only until confidence and explainability are defined.
