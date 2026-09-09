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

## Versi utama — siap tempel

*Satu paragraf satu baris, tanpa enter di tengah — LinkedIn yang membungkusnya
sendiri. Grammar dirapikan, urutannya hampir tidak diubah karena alurnya sudah
benar. Satu kalimat penutup gw tambahkan; kalau kerasa bukan lo, hapus saja —
alasannya gw tulis di bawah.*

---

Lately i've been struggling to code by myself, i keep relying on AI for everything, and i know literally zero of the codebase i supposedly built. That feeling of not owning my own work made me feel incompetent. So to fill that gap, i decided to make a game as my project in Apple Developer Academy @ BINUS Tangerang, within 10 days of work.

As my starting point, i had an abstract concept in mind: i like entertainment content that provides a very detailed theory for its magic system, and i wanted to make something like that. So i gathered resources related to it. Furthermore, i specifically chose the topics i had zero knowledge about: Entity Component System (ECS), Godot, Game Mechanics, and Game Juice. In addition to that, i decided to utilize AI as my learning mentor, you can say it's prompted to teach me and to guide me, giving me at most a 1 line code snippet or a pseudocode when it comes to the Game Logic scope.

As for the development, the first two days went entirely to ideation and learning in small steps, building a baseplate and a few examples. I initially thought of attacking by transferring spells into some kind of machine, but after hours of research and discussion, i had to abandon it. The reason was simple: that was not what i wanted to build from the beginning. I wanted freedom inside the game, something player centered.

So i shifted towards a simple PvE game where the player is the one casting the spell, and that literally ignited a spark in my mind, ideas started coming one after another. Furthermore, i thought i would have to restart the project from zero, because exercise code is usually nothing like the real project. But surprisingly, i only needed to comment out and delete some parts, and nothing broke. Only then did i realize one of the real benefits of using ECS in game development.

The game itself was built by combining what i gathered across the internet. Games like Noita, Magicka, and Ars Magica inspired me a lot, and i ended up with a concept where you insert one or more elements stored in runes, combine them into a new spell, and get different variations depending on how you cast it. For now there are three elements: fire (Ignis), water (Aqua), and air (Ventus), and each of them has its own characteristic: destructive, area, and crowd control. Those characteristics are baked into every spell they are inserted into, through what i call the Cast Queue, triggered by simply holding the Shift key. Additionally, your first rune decides the base form of the spell: Bullet, Puddle, or Wind Shock.

I also planned to create my own assets, because i wanted a game with a sketchy and gloomy theme. My discussion with AI and peers concluded that i should focus on only two assets, to keep my timeline safe for learning. But in the end? I managed to finish the game features before the estimated time, and i had the opportunity to create every image asset used in this game, which makes me pretty satisfied because it really suits my taste. I also did not expect to end up recording the player and monster sound effects with my own voice. On top of that i added a simple Continuous Integration system via GitHub Actions to make my work easier, and published it as an app, playable on macOS for now.

The result of this learning journey: the differences between ECS and OOP and where each of them wins or loses, some game theory and mechanics, and Godot itself. But more than that, i can now open any file in this project and explain why it is shaped that way, which is exactly the thing i could not do before i started.

You can download it here: https://github.com/Ahingg/amalgaform/releases/tag/v1.0

---

### Yang gw ubah, biar lo bisa nolak

**Grammar dan pilihan kata.** Yang paling banyak: `Futhermore` -> `Furthermore`,
`previously previously` -> sekali, `it self` -> `itself`, `alot` -> `a lot`,
`3 element present` -> `three elements`, `Only until that i realized` ->
`Only then did i realize`. Gaya lo dijaga: "i" tetap huruf kecil, klausa tetap
disambung koma, penghubung formal (`Furthermore`, `In addition to that`) tetap.

**Kalimat pertama dipertajam.** `i know literally zero of the codebase` jadi
`...of the codebase i supposedly built` — menutup logikanya, dan itu yang bikin
kata "incompetent" di kalimat berikutnya punya sebab.

**Urutan hampir tidak disentuh.** Alur lo sudah benar: masalah -> pilihan ->
pivot -> ganjarannya (ECS) -> gamenya -> aset -> hasil. Momen paling kuat di
tulisan ini adalah "i thought i would have to restart from zero, but nothing
broke", dan itu sudah duduk di tempat yang tepat, persis setelah pivotnya.

**Satu kalimat penutup ditambah**, sebelum link:
*"i can now open any file in this project and explain why it is shaped that
way, which is exactly the thing i could not do before i started."*
Alasannya: paragraf terakhir lo aslinya daftar hal yang dipelajari, dan daftar
itu penutup yang datar. Kalimat ini menutup lingkaran ke kalimat pertama —
"incompetent" di awal, dijawab di akhir. Kalau kerasa terlalu rapi, hapus.

**Link dipisah jadi baris sendiri.** Di dalam paragraf, LinkedIn memotongnya
saat teks dilipat "see more" dan orang malah tidak melihatnya.

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
