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

// // blockers ? (ray ^ blocked_pieces) : ray
// #define scan_up(occ,dir,sq) ((ray_masks[dir][sq] & occ)?(ray_masks[dir][sq]^(ray_masks[dir][lsb(ray_masks[dir][sq])])):(ray_masks[dir][sq]))

// #define scan_down(occ,dir,sq) ((ray_masks[dir][sq] & occ)?(ray_masks[dir][sq]^(ray_masks[dir][msb(ray_masks[dir][sq])])):(ray_masks[dir][sq]))

// #define rook_attacks(occ, sq) (scan_up(occ, NORTH, sq)|scan_up(occ, EAST, sq)|scan_down(occ, SOUTH, sq)|scan_down(occ, WEST, sq))

// #define bishop_attacks(occ, sq) (scan_up(occ, NW, sq)|scan_up(occ, NE, sq)|scan_down(occ, SW, sq)|scan_down(occ, SE, sq))

// #define queen_attacks(occ, sq) (bishop_attacks(occ, sq)|rook_attacks(occ, sq))

BB bishop_attacks(BB occ, enumSq sq);
BB rook_attacks(BB occ, enumSq sq);
BB queen_attacks(BB occ, enumSq sq);

#define build_move(id, from, to, cls, moves) do {                           \
  VALUE strategy = rb_class_new_instance(0, NULL, cls);                     \
  VALUE args[4];                                                            \
  args[0] = id;                                                             \
  args[1] = INT2NUM(from);                                                  \
  args[2] = INT2NUM(to);                                                    \
  args[3] = strategy;                                                       \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));             \
} while(0);     

#define build_castle(id, from, to, r_id, r_from, r_to, moves) do {                  \
  VALUE args[4];                                                                    \
  args[0] = r_id;                                                                   \
  args[1] = INT2NUM(r_from);                                                        \
  args[2] = INT2NUM(r_to);                                                          \
  VALUE strategy = rb_class_new_instance(3, args, cls_castle);                      \
  args[0] = id;                                                                     \
  args[1] = INT2NUM(from);                                                          \
  args[2] = INT2NUM(to);                                                            \
  args[3] = strategy;                                                               \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));                     \
} while(0);  

#define build_capture(id, from, to, cls, sq_board, moves) do {                \
  VALUE args[4];                                                              \
  args[0] = rb_ary_entry(sq_board, to);                                       \
  VALUE strategy = rb_class_new_instance(1, args, cls);                       \
  args[0] = id;                                                               \
  args[1] = INT2NUM(from);                                                    \
  args[2] = INT2NUM(to);                                                      \
  args[3] = strategy;                                                         \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));               \
} while(0);

#define build_promotion(id, from, to, color, cls, moves) do {                       \
  VALUE args[4];                                                                    \
  args[0] = color;                                                                  \
  VALUE strategy = rb_class_new_instance(1, args, cls);                             \
  args[0] = id;                                                                     \
  args[1] = INT2NUM(from);                                                          \
  args[2] = INT2NUM(to);                                                            \
  args[3] = strategy;                                                               \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));                     \
} while(0);


#define build_enp_capture(id, from, to, cls, target, sq_board, moves) do {                \
  VALUE args[4];                                                                          \
  args[0] = rb_ary_entry(sq_board, target);                                               \
  args[1] = INT2NUM(target);                                                              \
  VALUE strategy = rb_class_new_instance(2, args, cls);                                   \
  args[0] = id;                                                                           \
  args[1] = INT2NUM(from);                                                                \
  args[2] = INT2NUM(to);                                                                  \
  args[3] = strategy;                                                                     \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));                           \
} while(0);

BB scan_up(BB occ, enumDir dir, enumSq sq);
BB scan_down(BB occ, enumDir dir, enumSq sq);

static VALUE get_non_captures(VALUE self, VALUE p_board, VALUE color, VALUE castle_rights, VALUE moves);

static VALUE get_captures(VALUE self, VALUE p_board, VALUE color, VALUE sq_board, 
                          VALUE enp_target, VALUE moves, VALUE promotions);

static VALUE get_evasions(VALUE self, VALUE p_board, VALUE color, VALUE sq_board, VALUE enp_target,
                          VALUE promotions, VALUE captures, VALUE moves);

VALUE get_checks(VALUE self, VALUE color, VALUE moves);
VALUE get_check_evasions(VALUE self, VALUE color, VALUE moves);

extern void Init_move_gen();



#endif






