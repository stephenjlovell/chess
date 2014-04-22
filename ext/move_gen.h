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

// #define get_ray_attacks_reverse(occ, dir, sq) ((ray_masks[dir][sq] & occ) ?   \
//   (ray_masks[dir][sq]^(ray_masks[dir][msb(ray_masks[dir][sq] & occ)])) :      \
//   (ray_masks[dir][sq]))


// #define get_ray_attacks_forward(occ, dir, sq) ((ray_masks[dir][sq] & occ) ?   \
//   (ray_masks[dir][sq]^(ray_masks[dir][lsb(ray_masks[dir][sq] & occ)])) :      \
//   (ray_masks[dir][sq]))

// #define get_rook_attacks(occ, sq)                                                          \
//   (get_ray_attacks_forward(occ, NORTH, sq)  | get_ray_attacks_forward(occ, EAST, sq)      \
// //    | get_ray_attacks_reverse(occ, SOUTH, sq) | get_ray_attacks_reverse(occ, WEST, sq))

// #define get_bishop_attacks(occ, sq)                                                     \
//   (get_ray_attacks_forward(occ, NW, sq)   | get_ray_attacks_forward(occ, NE, sq)        \
//    | get_ray_attacks_reverse(occ, SW, sq) | get_ray_attacks_reverse(occ, SE, sq))

// #define get_queen_attacks(occ, sq) (get_bishop_attacks(occ, sq)|get_rook_attacks(occ, sq))

#define build_move(id, from, to, cls, strategy, moves) do {                 \
  strategy = rb_class_new_instance(0, NULL, cls);                           \
  VALUE args[4];                                                            \
  args[0] = id;                                                             \
  args[1] = INT2NUM(from);                                                  \
  args[2] = INT2NUM(to);                                                    \
  args[3] = strategy;                                                       \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));             \
} while(0);     

#define build_castle(id, from, to, r_id, r_from, r_to, strategy, moves) do {        \
  VALUE args[4];                                                                    \
  args[0] = r_id;                                                                   \
  args[1] = INT2NUM(r_from);                                                        \
  args[2] = INT2NUM(r_to);                                                          \
  strategy = rb_class_new_instance(3, args, cls_castle);                            \
  args[0] = id;                                                                     \
  args[1] = INT2NUM(from);                                                          \
  args[2] = INT2NUM(to);                                                            \
  args[3] = strategy;                                                               \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));                     \
} while(0);  

#define build_capture(id, from, to, cls, strategy, sq_board, moves) do {      \
  VALUE args[4];                                                              \
  args[0] = rb_ary_entry(sq_board, to);                                       \
  strategy = rb_class_new_instance(1, args, cls);                             \
  args[0] = id;                                                               \
  args[1] = INT2NUM(from);                                                    \
  args[2] = INT2NUM(to);                                                      \
  args[3] = strategy;                                                         \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));               \
} while(0);

#define build_promotion(id, from, to, color, cls, strategy, moves) do {   \
  VALUE args[4];                                                                    \
  args[0] = color;                                                                  \
  strategy = rb_class_new_instance(1, args, cls);                                   \
  args[0] = id;                                                                     \
  args[1] = INT2NUM(from);                                                          \
  args[2] = INT2NUM(to);                                                            \
  args[3] = strategy;                                                               \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));                     \
} while(0);


#define build_enp_capture(id, from, to, cls, strategy, target, sq_board, moves) do {      \
  VALUE args[4];                                                                          \
  args[0] = rb_ary_entry(sq_board, target);                                               \
  args[1] = INT2NUM(target);                                                              \
  strategy = rb_class_new_instance(2, args, cls);                                         \
  args[0] = id;                                                                           \
  args[1] = INT2NUM(from);                                                                \
  args[2] = INT2NUM(to);                                                                  \
  args[3] = strategy;                                                                     \
  rb_ary_push(moves, rb_class_new_instance(4, args, cls_move));                           \
} while(0);


VALUE get_non_captures(VALUE self, VALUE color, VALUE castle_rights, VALUE moves);
VALUE get_captures(VALUE self, VALUE color, VALUE sq_board, VALUE enp_target, VALUE moves, VALUE captures);

VALUE get_checks(VALUE self, VALUE color, VALUE moves);
VALUE get_check_evasions(VALUE self, VALUE color, VALUE moves);

extern void Init_move_gen();



#endif






