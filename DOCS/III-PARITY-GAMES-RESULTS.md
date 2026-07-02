# Parity-game novel-decider probe results (oracle = verified Zielonka, 0/400 vs brute force)
REFUTED as deciders (they LIE):
- uniform-random discounted resolvent over R((eps)) : 35-40% node-disagreement
- scalar "highest-forceable-priority" single fixpoint: 15-17% node-disagreement
NO COMPRESSION:
- standard bisimulation quotient on random games: ~n/n (6->5.9, 30->30.0); does not shrink
SOUND but INCOMPLETE (never lie; gap/core grows with n):
- one-player angelic/demonic sandwich: 0/1500 soundness violations; undecided gap 82%->98.8% (n6->n20)
- confluent winner-preserving reduction core (self-loop + 1-step forcing): 0/2100 unsound; core 50%->63% (n6->n30)
- naive sandwich iteration: barely closes gap AND sink-redirect was unsound (11/6/2 at n6/8/10)

(softmu probe family — soft/discounted mu-valuation variants incl. hard-instance and convergence sweeps —
belongs to the REFUTED discounted-resolvent class above: node-level mismatches vs the Zielonka oracle with
vanishing decision gaps; the probes printed per-(n,d,beta) mismatch tables and were retired with the root
Python purge, reunification W1. This doc is the durable record of that arc.)
