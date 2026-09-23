# Collecting vintage Macs — a buyer's guide

Notes for buying old Apple machines that still power on, to keep on a shelf in an office. Nothing to do with the KCNA; parked here so it does not get lost.

The short version: **buy locally, ask whether it has been recapped, and pull the PRAM battery the day it arrives.**

---

## 1. Which machines

Ranked by how well they hold a room, not by rarity.

| Model | Era | Why it works as an object | Working price, roughly |
|---|---|---|---|
| **iMac G4** ("sunflower", "lamp") | 2002–04 | The most sculptural Mac ever shipped. Chrome arm, floating screen, small footprint. Ships in three sizes — 15", 17", 20" — and the 20" costs the most | $150–400 |
| **Power Mac G4 Cube** | 2000 | 8-inch acrylic cube, fanless, in the Museum of Modern Art's permanent collection. Commercial flop, design landmark | $300–700 |
| **Macintosh Classic / Classic II** | 1990–93 | The cheapest way into the compact beige silhouette everyone recognizes | $150–350 |
| **Macintosh SE / SE-30 / Plus** | 1986–91 | Same shape, more provenance. The SE-30 is the collector favourite and priced like it | $200–400, SE-30 $600–1,200 |
| **iMac G3** | 1998–2001 | Bondi Blue or one of the fruit colours. Enormous personality, and an enormous CRT — it is heavy and deep | $100–250 |
| **iBook G3 clamshell** | 1999–2001 | Tangerine and Blueberry. Looks like a toy, closes into a handbag shape | $200–400 |
| **Newton MessagePad / eMate 300** | 1993–98 | Small, odd, conversation-starting. The eMate's translucent green is unmistakable | $150–400 |
| **Macintosh 128K** (the original) | 1984 | The one on the poster. Priced accordingly | $1,500+ |
| **Twentieth Anniversary Mac (TAM)** | 1997 | Vertical, leather palm rest, Bose subwoofer. A genuine collector piece | $2,500+ |

Prices move with condition, yellowing and whether the board has been serviced. Treat them as a starting point, not a quote.

If the office has room for exactly one machine, the **iMac G4** and the **G4 Cube** are the two that read as sculpture to people who do not care about computers. The **compact Mac** is the one that reads as *computer history* to people who do.

---

## 2. Where to buy

**Local first.** CRT machines — every compact Mac, the iMac G3 — travel badly. The tube shifts on its mounts, the case cracks at the corners, and the seller's "double boxed" usually means one box with newspaper. Driving to collect it removes the single largest risk.

| Source | Good for | Watch out for |
|---|---|---|
| **Facebook Marketplace / Craigslist / OfferUp** | Best prices, local pickup, CRTs | Rarely tested properly; bring a power cord and test before paying |
| **eBay** | Deepest selection, buyer protection | Filter to "working/tested"; read whether they actually powered it on or "found it in storage" |
| **[68kMLA forums](https://68kmla.org/) marketplace** | Enthusiast sellers who recap boards before selling | Small supply; worth waiting for |
| **Etsy** | Cleaned-up and restored units, sometimes already staged for display | Priced for the restoration work; check it is not a gutted shell |
| **Vintage Computer Festival** (East / West / Midwest / Southeast / Southwest) | Swap meets — inspect in person, carry it home | Once or twice a year per region |
| **shopgoodwill.com, GovDeals, university surplus** | $40 gambles | Untested, shipped by people who do not know what it is |
| **Yahoo Auctions Japan** (via Buyee or similar proxy) | Unusually clean, un-yellowed machines | Freight cost; voltage is 100V, close enough to US 120V for most, check the PSU |
| **Local e-waste recyclers** | Free to cheap, occasionally remarkable | Call and ask; many are glad to see a machine go somewhere other than a shredder |

Communities worth lurking in before buying: [r/VintageApple](https://www.reddit.com/r/VintageApple/), [r/retrobattlestations](https://www.reddit.com/r/retrobattlestations/), and the [Vintage Computer Federation](https://vcfed.org/) forums.

---

## 3. What to ask a seller

1. **"Has it been recapped?"** The single most useful question for anything made between roughly **1987 and 1997**. Those machines use surface-mount electrolytic capacitors that leak over decades, and the electrolyte eats through logic-board traces. A machine that works today with original caps is a machine on a timer. Recapped means somebody has already replaced them — pay more for it.
2. **"Is the PRAM battery still in it, and has it leaked?"** See below. If the answer is "what battery", assume it is in there.
3. **"Does it chime and boot to a desktop, or just power on?"** These are different claims. Ask for a photo of the machine displaying something.
4. **"Any screen burn-in, and how bad is the yellowing?"** Beige plastics yellow from the bromine flame retardant in them. Retrobrite restoration exists but can go blotchy and often re-yellows, so it is easier to buy a machine that was kept out of the sun.
5. **"Does it come with the original keyboard, mouse and cables?"** ADB peripherals are cheap but annoying to source separately, and the machine looks unfinished without them.

---

## 4. The day it arrives

**Remove the PRAM battery.** This is the one piece of maintenance that matters. Compact Macs and most late-80s/90s Macs carry a 1/2 AA 3.6V lithium cell on the logic board to hold the clock and settings. They leak, and the leak destroys the board underneath. A machine that is going to sit on a shelf has no use for the clock — take the battery out and the machine will outlive you. It is a two-minute job on most models.

**Do not open a CRT compact Mac casually.** The flyback transformer and the tube hold a lethal charge long after the machine is unplugged, and the case needs a long Torx driver to get into. If it needs internal work, pay someone who does this.

**Clean it before it goes on the shelf.** Isopropyl alcohol on the case, compressed air through the vents, and a look inside the floppy drive if it has one — decades of dust is usually what you are smelling when you first power one on.

**Expect the power supply to be the next thing to fail** on anything pre-2000. If it is purely decorative, the safest move is to enjoy it powered off most of the time and switch it on when someone asks.

---

## 5. If you want it to actually show something

A decorative machine that displays something is far better than one that does not, and running the original hardware daily is the fastest way to wear it out. Two common approaches:

- **Raspberry Pi behind the original screen.** The well-trodden mod: a Pi plus a small LCD fitted inside a compact Mac shell, running [Mini vMac](https://www.gryphel.com/c/minivmac/) or [BasiliskII](https://basilisk.cebix.net/) so it boots a real System 7 desktop. The case is untouched and the original board can be kept in a drawer.
- **Leave the hardware original and run it occasionally.** Compact Macs boot from SD-card floppy emulators (BlueSCSI, FloppyEmu) which are far kinder than 35-year-old drives and mean no original media gets worn out.

The iMac G4's screen and arm can be reused with a modern board, but the mod is much more involved than the compact-Mac one and it is a shame to cut into a clean unit.

---

## 6. One shortcut

If it will genuinely never be switched on, **"for parts / not working" units run a third to a half the price of tested ones**, and a clean non-working shell is visually identical on a shelf. The premium is entirely for the electronics. Worth knowing before paying working-machine money for something that is going to sit next to a plant.
