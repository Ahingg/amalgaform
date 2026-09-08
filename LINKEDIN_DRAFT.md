# LinkedIn draft — Game track rotation

Ini draft, bukan naskah final. Potong sesukanya. Angkanya sudah dicek dari repo
per 9 September: 23 system, 13 komponen, ~1.600 baris di sim, ~2.650 di view,
62 gambar, 40 berkas suara, 48 commit.

---

## Versi panjang

Ten working days. One rotation. I had never touched Godot before this.

I picked the Game track knowing I'd be the least prepared person in it. Not
because I wanted a challenge to post about, but because I had a specific
problem I wanted to fix about myself.

A while back I followed a tutorial to build a macOS paint app. It worked. It
looked fine. And I could not explain a single architectural decision inside it,
because I had let AI write all of it. That bothered me for months. So going
into this rotation I made one rule for myself: the simulation and the ECS, I
write. Every component, every system. The rendering, the juice, the tooling,
I delegate. Because that's not the part I'm here to learn.

Ten days. Here's roughly how it went.

**Days 1-2, ideation.** I went in wanting a spell-crafting game. Magicka,
Morrowind's spellmaking, that whole lineage. My first design had machines you
place before the round, a slot economy, crystals to defend. I wrote the full
design doc. Then I read it back and asked what the machine's position was
actually FOR, and the honest answer was nothing. So I threw it out. Rewrote the
design doc three times total before a single line of gameplay code existed.

What survived: hold a key, queue up to four runes, release, then throw. The
first rune decides the SHAPE of the spell. The whole queue decides what's
inside it. Fire first gives you a bullet. Water first gives you a ball that
bursts into a puddle. Wind first gives you a blast. Same three runes, different
order, completely different spell. That grammar is the entire game.

**Days 3-6, the actual ECS.** This is where I spent the most and learned the
most. Entities are bare ints. Components are pure data. Systems are static
functions with no memory between frames. Rules I ended up enforcing on myself:
whatever a system reads goes in its query. Systems never call other systems,
they talk through the World. If something can be derived from the World, it is
never stored anywhere. Anything that controls time uses raw delta.

Sounds tidy written down. In practice I broke every one of those rules at least
once and had to go find out why the game felt wrong.

**The bugs that actually taught me something.**

The wet slow. Water makes enemies 50% slower. I applied the multiplier per
stack, and stacking water twice made enemies walk backwards, because the slow
exceeded 1.0 and velocity went negative. The fix was applying the power to the
multiplier instead of the result. Bounded quantities don't add, they compound.
Ten seconds to type, two hours to understand.

Hit stop. When something takes a hard hit the world freezes for 40ms. Cheapest
impact effect in 2D action games, zero animation frames. Mine did nothing for a
whole evening, and it turned out to be three separate bugs stacked on top of
each other: the system ran after the scaled delta was computed, another system
reset the time scale every frame, and the freeze timer itself ran on the scaled
delta so it froze itself forever. Fixing one never showed progress because the
other two were still there.

And the one that nearly broke me: the wind blast pushing enemies the wrong way.
I spent two and a half hours on it. Turned out Position in my world is the
top-left CORNER of a box, not the center, and three different places had
silently assumed center. For a small bullet the error is invisible. For a 4x4
tile blast it points the push completely wrong, always toward the bottom right.
I only found it after I stopped guessing and wrote a tiny script that fires the
spell in eight directions and prints where it lands. Answer in three seconds
after that.

That's the actual lesson of this whole rotation for me, and it isn't about
Godot. When I'm stuck for two hours, it's almost never that the concept is too
hard. It's that I have no way to SEE what's happening, so I'm guessing. Build
the measuring tool first. I now have five little scripts in tools/ that exist
purely because I got tired of guessing.

**Scope.** I planned to cut hard. Two hand-drawn assets, everything else stays
colored rectangles. I said that in writing on day 2 so I'd be accountable to it.

I did not keep that promise. I drew all 62 of them. Player poses, four enemy
frames, rune stones, fireball layers, water ripples, impact splatters, a
tileable floor. Then I recorded the monster sounds with my own voice at
midnight, wrote a script to trim and level them, and found out my phone records
m4a which Godot flat out doesn't read.

Honest answer on whether that was a scope violation: yes, technically. But it
was the ONE place where going over the line made the thing feel like mine
instead of like a tutorial output, and I'd take that trade again. The mechanics
scope I did hold. No procedural generation, no meta progression, no fourth
rune, no A*. Those were all on the cut list and they stayed cut.

**Where it landed.** 23 systems, 13 components, roughly 1,600 lines of
simulation I can walk you through line by line. Waves, dash, three elements
that each feel different, screen shake, hit stop, death bursts, sound. Some
nights ended at 3am. Two nights I ran on three and a half hours of sleep, which
I don't recommend and would not repeat.

The thing I'm actually taking away isn't the game. It's that I can now open any
file in this project and tell you why it's shaped that way. That was the whole
point, and it's the first time I've been able to say it about something I built.

Repo below. It's a 10 day rotation project, not a product. Be kind.

---

## Versi pendek (kalau yang panjang kepanjangan)

Ten working days. Never touched Godot before.

I picked the Game track specifically because of something that had been
bothering me. A while back I followed a tutorial to build a macOS paint app,
let AI write all of it, and afterwards I couldn't explain a single
architectural decision in my own project. So this time I drew a hard line: the
ECS and the simulation, I write. Rendering and juice, I delegate.

The game is a spell grammar. Hold a key, queue up to four runes, release, throw.
The first rune decides the shape, the whole queue decides the contents. Fire
first is a bullet, water first is a ball that bursts into a puddle, wind first
is a blast. Same runes, different order, different spell.

Hardest two and a half hours: a wind blast that always pushed enemies toward the
bottom right no matter which way I aimed. Position in my world is the corner of
a box, not the center, and three separate places had quietly assumed center. I
only found it after I stopped guessing and wrote a script that fires the spell
in eight directions and prints where it lands. Three seconds after that.

Real lesson, and it has nothing to do with Godot: when I'm stuck for two hours
it's almost never that the concept is hard. It's that I can't SEE what's
happening. Build the measuring tool first.

I planned to draw two assets and keep everything else as colored rectangles. I
drew 62 and recorded the monster sounds with my own voice. That's a scope
violation and I'd do it again.

23 systems, 13 components, ~1,600 lines of simulation I can walk through line
by line. That last part was the entire point.
