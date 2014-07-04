
# RubyChess

A Chess AI and basic GUI written in Ruby and C!

-----------------------------------------------------------

## Search Stack Features

- Iterative Deepening
- Dual-Entry Transposition Tables
- Modular search framework - Easily switch out search driver algorithms

### Available Search Drivers
- MTD(f)
- MTD(f)-Step
- Aspiration Search

### Minimax refinements
- Alpha-Beta Pruning
- Adaptive Null-Move Pruning
- Futility Pruning
- Quiescence Search

### Move Ordering

Before searching each subtree, moves are ordered according to the following heuristics:

1. Hash Move - If a previous search found a best move, this move is searched first.
- Capture Moves
    - Static Exchange Evaluation - Material gain/loss calculated for each capture move
    - Most Valuable Victim, Least Valuable Attacker - When material gain is the same, the AI will prefer to attack with its least valuable piece.
- Non-Capture Moves
    - Killer Heuristic - AI maintains a list of moves that have most recently caused cutoffs, indexed by depth.
    - History Heuristic - When a move causes a search cutoff, a history table is incremented by the size of the subtree cutoff. Moves that have caused the largest cutoffs are tried first.


-----------------------------------------------------------

## Evaluation Features

- Piece-Square Tables
- King Tropism
- Piece Mobility
- Pawn Structure
    - Passed pawns
    - Isolated pawns
    - Pawn duos
    - Doubled/Tripled pawns   

-----------------------------------------------------------

## Move Generation

- Bitboard-based move generation in C
- Check evasion generator
- Separate capture generation

  