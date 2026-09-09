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

## Versi utama — Challenge / Choice / Result

*Dua paragraf pertama punya lo, gw cuma rapiin yang bikin kebaca dua kali.
Sisanya gw tulis ngikutin pola lo: "i" huruf kecil, klausa disambung koma,
penghubung formal dicampur nada santai. Kalau ada kalimat yang kerasa bukan
lo, itu gw yang meleset — coret aja.*

---

Lately i've been struggling to code by myself, i keep relying on AI for
everything, and i know literally zero of the codebase. That feeling of not
owning my own work made me feel incompetent. So to fill that gap, i decided to
make a game as my project in Apple Developer Academy @ BINUS Tangerang, within
10 days of work.

As my initial point developing the game, i had some abstract concept in my
mind: i like entertainment content that provides a very detailed theory for
their magic system, and i want to make something like that. So i gathered
resources that correlate with it. Furthermore, i specifically chose the terms
that i have zero knowledge about previously: Entity Component System (ECS),
Godot, Game Mechanics, and Game Juice. In addition to that, for this learning,
i have decided to utilize AI as my learning mentor, you can say it's prompted
to teach me and to guide me, giving me at most only a 1 line code snippet or a
pseudocode when it comes to the Game Logic scope.

The game itself is about spell grammar. You hold a key, the world slows down,
and you queue up to four runes before you release and throw it. The first rune
decides the shape of the spell, and the whole queue decides what is inside it:
fire first gives you a bullet, water first gives you a ball that bursts into a
lingering puddle, wind first gives you a blast that pushes everything away. So
the same three runes in a different order will give you a completely different
spell, and that grammar is basically the entire game.

As for the development, the first two days went entirely to ideation, and i
rewrote the design document three times before writing a single line of
gameplay code. My first concept had machines you place before the round and
crystals to defend, then i read it back and asked what the machine position was
actually for, and the honest answer was nothing, so i threw it away. The days
after that went to the ECS itself, and this is where most of my learning
happened: entities are just integers, components are pure data, and systems are
functions that remember nothing between frames. On paper those rules sound
tidy, in practice i broke almost all of them at least once and had to find out
the hard way why the game felt wrong.

The hardest one took me two and a half hours: a wind blast that always pushed
enemies to the bottom right, no matter where i aimed. It turned out that
Position in my world is the top left corner of a box and not the center, and
three different places had quietly assumed center. i only found it after i
stopped guessing and wrote a small script that fires the spell in eight
directions and prints where it lands, and three seconds after that i had the
answer. That is probably my biggest takeaway from this rotation, and it has
nothing to do with Godot: when i am stuck for hours it is almost never because
the concept is too hard, it is because i have no way to see what is happening,
so i am just guessing. Build the measuring tool first.

i also planned to scope down hard on the visuals, two hand drawn assets and
everything else stays as colored rectangles, and i wrote that down on day two
so i would be accountable to it. i did not keep that promise. i ended up
drawing all 62 assets myself, and i recorded the monster sounds with my own
voice at midnight then wrote a script to trim and level them. Technically that
is a scope violation, but it is the one place where going over the line made
this project feel like mine instead of a tutorial output.

Where it landed: 23 systems, 13 components, and around 1,600 lines of
simulation that i can walk through line by line. Waves, dash, three elements
that each feel different, hit stop, screen shake, and sound. Some nights ended
at 3am and that part i do not recommend. But the thing i am actually taking
away is not the game, it is that i can open any file in this project and tell
you why it is shaped that way. That was the whole point from the beginning.

---

## Cadangan — versi panjang pertama
Lately i've been struggling to code by myself, i keep relying on AI for everything, and i know literally zero of the codebase. This feeling of lack of work things made me feel incompetence. So to fill that gap, i decided to make a game as my project in Apple Developer Academy @ BINUS Tangerang, within 10 days of work. 
As my initial point developing the game, i had some abstract concept in my mind: i like entertainment content that provide a very  detailed theory for their magic system and i want to make something like that. So gathered resources that correlates with that Futhermore, i specifically chose the terms that have zero knowledge about previously previously: Entity Component System (ECS), Godot, Game Mechanics, and Game Juices. In addition to that, for this learning, i have decided to utilize AI as my learning mentor, you can say it's prompted to teach me and to guide me, giving me at most only the 1 line code snippet or a pseudocode when it comes to the Game Logic Scope. 

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
