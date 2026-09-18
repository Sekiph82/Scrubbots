# M27 Work Package 01 — Proof State & Transition Kernel
Tasks: SB-M27-001..012

Build the detached deterministic proof-state model and legal transition kernel.

Required:
- isolated gameplay-domain reconstruction, no UI Nodes;
- exact M23 queue/front semantics for 3/4/5 columns;
- exact M24 five-slot rightmost-empty placement/full rejection;
- exact batch remaining/WAITING/placement sequence;
- production targetability/routing, Railroad V1/V07;
- deterministic serial claim->route-valid->clear proof transition;
- ACTIVE->CLEARED board evolution;
- WAITING revival after corridor opening;
- canonical deterministic state serialization/key;
- direct equivalence tests against small runtime M24/M25/routing fixtures.

Do not implement final search/generator policy until the kernel is correct.
