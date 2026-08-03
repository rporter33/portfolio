# Excel CES — Cost Estimating System

A mobile-first progressive web app that replaced a Denver-area roofing contractor's
cost-estimating workbook.

**Stack:** Next.js 15 (App Router) · Prisma 6 · PostgreSQL via Supabase · Clerk v7 ·
Tailwind CSS · Vitest · Vercel

---

## The problem

The company priced every job out of a shared Excel workbook — roughly 700 interlocking
formulas covering labor rates, material costs, tax, overhead, permits, and financing.
It worked, but it was a desktop artifact in a field job. Project managers were standing on
roofs with measurements in their heads and no way to produce a number until they got back
to a laptop. Every copy of the workbook drifted from every other copy, and there was no
record of what a price had been when a bid went out.

## What I built

A PWA the PM can install on a phone, use on site, and hand a printable bid sheet to a
homeowner from.

### The pricing engine is the core

The whole project lives or dies on producing exactly the number the workbook produced.
Formulas were ported deliberately rather than approximated:

| Workbook formula | App equivalent |
|---|---|
| `=(C*D*E)/$G$6` | `rawCost / (1 - markupPct)` |
| `=F184*0.083` | `rawMaterialCost * taxRate` |
| `=MIN(2000,G192*0.1)` | `MIN(overheadCap, base * overheadPct)` |
| `=PMT(7.99%/12,60,G15)` | `pmt(0.0799, 60, financedAmount)` |
| `=ROUNDDOWN(K4,0)*1.02` | `Math.floor(squares) * 1.02` |

Composed into:

```
baseEstimate = (rawMat + rawLabor) / (1 - markupPct)
overhead     = min(overheadCap, baseEstimate × overheadPct)
cashPrice    = baseEstimate + materialTax + fuelCharge + overhead + permitCost
```

Tax applies only to raw material cost. Permit cost passes through unmarked-up. The engine
is unit-tested and was **validated against five real completed CES workbooks with 0.00
error** before anyone was asked to trust it.

### Decisions worth defending

**Price snapshotting.** Estimate line items store `unitCost` at save time. When the product
catalog gets repriced, historical estimates don't silently change underneath a bid that's
already with a customer. Catalog edits are separately written to a `ProductPriceHistory`
audit log — old price, new price, who changed it, when — before the write lands.

**A real role model, not an admin flag.** Five roles (PROJECT_MANAGER, SENIOR_PM,
OFFICE_ADMIN, OPS_MANAGER, SYSTEM_ADMIN) across four capabilities. A project manager sees
only their own projects. All checks live in one `permissions.ts` module; role strings are
never inlined in server actions, so the permission surface can be read in one sitting.

**Graceful auth degradation.** If Clerk isn't configured, `getCurrentDbUser()` returns null
and the app runs unauthenticated in dev instead of crashing. Onboarding a new user is an
explicit claim step — the signup flow matches a Clerk identity to an existing unlinked
database record rather than silently creating duplicates.

**Multi-tenancy as a nullable scaffold.** `organizationId` exists on the models but isn't
enforced, sitting behind a `MULTI_COMPANY` feature flag. Zero runtime cost today, no
migration archaeology when it's needed.

### Documented trade-offs

The architecture reference carries a standing table of accepted trade-offs, each with a
trigger for revisiting it. A sample:

| Decision | Trade-off | When to revisit |
|---|---|---|
| `prisma db push`, no migrations | Fast iteration, no rollback history | Before any shared staging or team database |
| Price snapshot at save | Historical accuracy over live repricing | If users need an explicit "re-price" action |
| No background jobs | Simple deploy, no queue infrastructure | When PDF generation ships |
| Clerk hosted UI | Fast auth, limited brand control | If brand guidelines require custom auth screens |

I'd rather write down why a shortcut was taken and what would invalidate it than pretend
it wasn't a shortcut.

---

## Scope

Fifteen-value project status enum running LEAD_RECEIVED → CLOSED, with estimate saves
auto-advancing status. Roof measurement entry with computed square footage. Mobile-first
layout — bottom navigation on phones, sidebar on desktop. Auto-saving estimate builder.
Printable bid sheet. Role-gated catalog price editor. PWA manifest for home-screen install.
