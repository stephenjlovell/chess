//-----------------------------------------------------------------------------------
// Copyright (c) 2013 Stephen J. Lovell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//-----------------------------------------------------------------------------------

#ifndef MOVE_GEN
#define MOVE_GEN

#include "shared.h"
#include "board.h"
#include "bitwise_math.h"

extern const int C_WQ;
extern const int C_WK;
extern const int C_BQ;
extern const int C_BK;

extern BB castle_queenside_intervening[2];
extern BB castle_kingside_intervening[2];

static VALUE mod_chess;
static VALUE mod_move;
static VALUE mod_move_gen;
static VALUE cls_move;
static VALUE cls_move_strategy;

static VALUE cls_regular_move;
static VALUE cls_regular_capture;

static VALUE cls_king_move;
static VALUE cls_king_capture;
static VALUE cls_castle;

static VALUE cls_pawn_move;
static VALUE cls_enp_advance;
static VALUE cls_enp_capture;

static VALUE cls_promotion;
static VALUE cls_promotion_capture;


#define blockers(dir, sq, occ)           (ray_masks[dir][sq] & occ)
#define unblocked_down(dir, sq, blocked) (ray_masks[dir][sq]^ray_masks[dir][msb(blocked)])
#define unblocked_up(dir, sq, blocked)   (ray_masks[dir][sq]^ray_masks[dir][lsb(blocked)])

#define scan_down(occ, dir, sq) (blockers(dir, sq, occ)?unblocked_down(dir, sq, blockers(dir, sq, occ)):(ray_masks[dir][sq]))
#define scan_up(occ, dir, sq)   (blockers(dir, sq, occ)?unblocked_up(dir, sq, blockers(dir, sq, occ)):(ray_masks[dir][sq]))

#define rook_attacks(occ, sq)   (scan_up(occ, NORTH, sq)|scan_up(occ, EAST, sq)|scan_down(occ, SOUTH, sq)|scan_down(occ, WEST, sq))
#define bishop_attacks(occ, sq) (scan_up(occ, NW, sq)|scan_up(occ, NE, sq)|scan_down(occ, SW, sq)|scan_down(occ, SE, sq))
#define queen_attacks(occ, sq)  (bishop_attacks(occ, sq)|rook_attacks(occ, sq))

// BB bishop_attacks(BB occ, enumSq sq);
// BB rook_attacks(BB occ, enumSq sq);
// BB queen_attacks(BB occ, enumSq sq);
// BB scan_up(BB occ, enumDir dir, enumSq sq);
// BB scan_down(BB occ, enumDir dir, enumSq sq);

static void build_move(VALUE id, int from, int to, VALUE cls, VALUE moves);
static void build_castle(VALUE id, int from, int to, VALUE r_id, int r_from, int r_to, VALUE moves);
static void build_capture(VALUE id, int from, int to, VALUE cls, VALUE sq_board, VALUE moves);

static void build_promotions(VALUE id, int from, int to, VALUE color, VALUE cls, VALUE moves);
static void build_promotion_captures(VALUE id, int from, int to, VALUE color, VALUE cls, VALUE sq_board, VALUE promotions);

static void build_enp_capture(VALUE id, int from, int to, VALUE cls, int target, VALUE sq_board, VALUE moves);

static VALUE get_non_captures(VALUE self, VALUE p_board, VALUE color, VALUE castle_rights, VALUE moves, VALUE in_check);

static VALUE get_captures(VALUE self, VALUE p_board, VALUE color, VALUE sq_board, 
                          VALUE enp_target, VALUE moves, VALUE promotions);

static VALUE get_winning_captures(VALUE self, VALUE p_board, VALUE color, VALUE sq_board, 
                                  VALUE enp_target, VALUE moves, VALUE promotions);

static VALUE get_evasions(VALUE self, VALUE p_board, VALUE color, VALUE sq_board, VALUE enp_target,
                          VALUE promotions, VALUE captures, VALUE moves);


extern void Init_move_gen();



#endif






