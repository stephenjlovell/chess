
# RubyChess

A Chess AI and CLI written in Ruby and C!  Compile with GCC or LLVM.

-----------------------------------------------------------

## CLI Features

Play full games of Chess against the AI!

    2.1.0 :001 > load 'initialize.rb'
    2.1.0 :002 > play
    Welcome to RubyChess!
    Choose your color (w/b):  w
    Starting a new game. AI color: b, Your color: w
    rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1

    -----------------------------------------------------------------------------
    | Move: 0 | Ply: 0 | Turn: w | Castling: KQkq | AI Score: 0 | Your Score: 0 |
    -----------------------------------------------------------------------------

        A   B   C   D   E   F   G   H
      ---------------------------------
    8 | ♜ | ♞ | ♝ | ♛ | ♚ | ♝ | ♞ | ♜ | 8
      ---------------------------------
    7 | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | ♟ | 7
      ---------------------------------
    6 |   |   |   |   |   |   |   |   | 6
      ---------------------------------
    5 |   |   |   |   |   |   |   |   | 5
      ---------------------------------
    4 |   |   |   |   |   |   |   |   | 4
      ---------------------------------
    3 |   |   |   |   |   |   |   |   | 3
      ---------------------------------
    2 | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ | ♙ | 2
      ---------------------------------
    1 | ♖ | ♘ | ♗ | ♕ | ♔ | ♗ | ♘ | ♖ | 1
      ---------------------------------
        A   B   C   D   E   F   G   H
    It's your turn.  Enter a command:      


### Help menu and available commands

    It's your turn.  Enter a command:  help

    -------------------------------------------- RubyChess Help --------------------------------------------
    To move one of your pieces, enter the square you want to move from, 
    and the square the piece is moving to.  For example: a1a2 
    To castle, simply move your king 2 squares to the left or right. 
    The following commands are also available:

    COMMAND               | DESCRIPTION                                                                     
    ----------------------|---------------------------------------------------------------------------------
    help                  | displays a help screen with a list of valid commands... including this one.     
    quit                  | ends the game and exits the program.  you may also enter "q" or "exit" to quit. 
    undo                  | undoes the most recent full move (undoing the most recent action for each side).
    redo                  | replays the next full move.  Only available if move(s) have been undone.        
    print history         | prints a list of the moves made by each player.                                 
    print history details | prints the move list, along with the position in FEN notation.                  
    load <FEN>            | loads the chess position specified by <FEN> in FEN notation.                    
    fen                   | prints out the current position in FEN notation  

-----------------------------------------------------------

## Evaluation Features

Evaluation in RubyChess is symmetric: values for each heuristic are calculated for both sides, and a net score is returned for the current side to move.

- Piece-Square Tables - Small bunuses/penalties are applied based on the type of piece and its location on the board.  Squares close to the center of the board are generally given larger bonuses, emphasizing control of the board.
- King Tropism - A bonus is given for each piece based on its closeness to the enemy king.  The bonus is scaled by the value of the piece, causing the AI to press its attack with stronger pieces and prevent its opponent from getting too close to its king.
- Piece Mobility - Each piece is awarded a bonus based on how many squares it can move to from its current location, not counting squares guarded by enemy pawns.  This makes the AI prefer to position its sliding pieces where they can control the largest amount of space on the board.
- Pawn Structure - The value of a pawn is partly dependent on where the other pawns are.  Pawn values are adjusted by looking for several structures considered in chess to be particularly strong/weak.
    - Passed pawns - If there are no enemy pawns available to block a pawn's advance, it is considered 'passed' and is more likely to eventually get promoted.  A bonus is awarded for each passed pawn based on how close it is to promotion.
    - Isolated pawns - Pawns that are separated from other friendly pawns are vulnerable to capture and may need to be guarded by more valuable pieces, limiting that side's ability to attack.  A small penalty is given for each isolated pawn.  This causes the AI to keep its pawns supporting one another and to break up the opponent's pawn lines where possible.
    - Pawn duos - Pawns that are side by side to one another create an interlocking wall of defended squares.  A small bonus is given to each pawn that has at least one other pawn directly to its left or right.
    - Doubled/Tripled pawns - Having multiple pawns on the same file (column) limits their ability to advance, as they can easily be blocked by a single enemy piece and cannot defend one another.  A penalty is given for each additional pawn when there is more than one pawn on a single file.

-----------------------------------------------------------

## Search Stack Features

- Iterative Deepening - The search is repeatedly called at increasing maximum depth, allowing information from shallower searches to improve the move ordering and reduce the cost of the deeper searches. 
- Dual-Entry Transposition Tables - Nodes are hashed and bounds on their true value are stored for later use.
- Modular search framework - Easily pass in search driver algorithms for testing.

### Available Search Drivers
- MTD(f) - Uses a series of quick 'zero-window' alpha-beta searches to step from an initial guess toward the minimax value
- MTD(f)-Step - Dynamically increases the step size in order to close in on the minimax value with fewer MTD(f) passes
- Aspiration Search - Starts out as a basic 'full-width' alpha-beta search.  Once an accurate guess is established, further searching is done within a narrow window centered on the expected value.  If a value lands outside one of the bounds, the search is repeated with that bound increased/decreased.

### Minimax refinements
- Alpha-Beta Pruning - Bounds on how well each side can expect to do are passed down the call stack and updated as more information is gathered. This allows the engine to prune subtrees that are are unlikely to occur due each side avoiding undesirable outcomes.
- Quiescence Search - Extends the main search by generating only moves that cause large swings in the score (such as captures and promotions).  This allows the search to eventually find 'quiet' nodes for which a reliable hueristic evaluation can be performed.
- Adaptive Null-Move (NM) Pruning - Performs a shallow search to determine the value to the current side of simply skipping a turn. Since there is almost always some move that will improve the position for the current side, If the NM search value exceeds beta, we can safely cut off the search and return the NM value. Not used when in check or during the endgame (when this assumption is less likely to hold). 
- Futility Pruning - At shallow depths, when a node appears unlikely to exceed alpha, 'quiet' nodes can be safely pruned.

### Move Ordering

Before searching each subtree, moves are ordered based on several heuristics.  This reduces the branching factor of the game tree by making alpha/beta cutoffs more likely.

1. Hash Move - If a previous search found a best move, this move is searched first.
- Internal Iterative Deepening (IID) - When no hash move is available, IID is used to guess the best move to try first.  Since this is fairly expensive, IID is only used at higher search depths.
- Pawn Promotions
- Capture Moves
    - Static Exchange Evaluation (SEE) - Expected material gain/loss is calculated for each capture move. This also allows 'losing' captures to be pruned under some circumstances.
    - Most Valuable Victim, Least Valuable Attacker - When expected material gain/loss is the same, the AI will prefer to attack the enemy's most valuable available piece with its least valuable available piece.
- Non-Capture Moves
    - Killer Heuristic - AI maintains a list of moves that have most recently caused beta cutoffs, indexed by depth.
    - History Heuristic - When a move causes a beta cutoff, a history table is incremented by the size of the subtree cutoff. Moves that have caused the largest cutoffs are tried first.

-----------------------------------------------------------

## Move Generation

- Bitboard-based move generation in C - Square occupancy for each piece type and color are encoded in 64-bit unsigned longs corresponding to the 64 squares on the chess board. Bitboard masks are also used to determine what squares a piece can legally reach. This allows RubyChess to generate moves with a handful of bitwise operations and without overhead of branch misprediction or iteratively searching each direction from each origin square.
- Check evasion generator - A separate routine is used when in check to generate only those moves that get the king out of check.  This reduces the liklihood of wasting search effort on illegal moves, and also increases the accuracy of Quiescence search by extending the search until a more stable node is found from which to evaluate.

-----------------------------------------------------------

## Performance Benchmarks

RubyChess currently scores 263/300 on [Win At Chess (WAC)](http://www.amazon.com/Win-at-Chess-Dover/dp/0486418782/ref=sr_1_1?s=books&ie=UTF8&qid=1404847057&sr=1-1 "Win At Chess") for an 8-ply (7.7 second) fixed-depth search.

You can run performance benchmarks against several popular test suites using RSpec:

    rspec spec/search_spec.rb

    ------ Aggregate Search Performance -------

    DEPTH | SCORE | PASSES | M_NODES | Q_NODES | EVALS   | MEMORY  | EFF_BRANCHING      | AVG_EFF_BRANCHING  | ALL_NODES
    ------|-------|--------|---------|---------|---------|---------|--------------------|--------------------|----------
    1     |       | 0      | 12008   | 20848   | 28331   | 373     | 0.0                | 0.0                | 32856    
    2     |       | 0      | 45739   | 73422   | 96358   | 17826   | 3.626765278792306  | 3.626765278792306  | 119161   
    3     |       | 0      | 294793  | 197682  | 397642  | 57436   | 4.1328538699742365 | 3.8715489042429736 | 492475   
    4     |       | 0      | 498738  | 472083  | 793658  | 133469  | 1.9713102187928322 | 3.091539673019375  | 970821   
    5     |       | 0      | 2577551 | 1507897 | 3196783 | 454356  | 4.208240242021959  | 3.3393062423334827 | 4085448  
    6     |       | 0      | 4308495 | 3147710 | 5899298 | 1264114 | 1.82506422796227   | 2.9592430071283213 | 7456205  

    Total AI score: 225/300 (75.0%)
    1.06684769 seconds/search at depth 6
    41108.54224498844 NPS
    N: 13156966; E: 10412070; B: 2.9592430071283213; Efficiency: 25.344319415248275


Recent performance testing against Win At Chess (WAC) suite at various maximum depths:

    Total AI score: 171/300 (56.99999999999999%)
    0.11626264666666666 seconds/search at depth 4
    46312.868501129946 NPS
    N: 1615337; E: 1315964; B: 3.091565148481465; Efficiency: 18.43726308921474

    Total AI score: 225/300 (75.0%)
    1.0238726833333334 seconds/search at depth 6
    42826.4054510293 NPS
    N: 13154636; E: 10409996; B: 2.959282297528506; Efficiency: 25.343982918641288

    Total AI score: 263/300 (87.66666666666667%)
    7.771986543333334 seconds/search at depth 8
    39700.683338333605 NPS
    N: 92565953; E: 71412197; B: 2.8813371966744445; Efficiency: 30.425688033961794






  