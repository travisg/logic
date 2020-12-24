/*
 * Copyright (c) 2020 Travis Geiselbrecht
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

// Simple 16 bit ALU composed of 4 74181s and a single 74182 carry look ahead

module alu_181 #(parameter WIDTH=16) (
    input [WIDTH-1:0] A_in,
    input [WIDTH-1:0] B_in,
    output [WIDTH-1:0] out,
    input mode, // alu or logical
    input [3:0] op_in, // alu op on the 181s
    input carry_in,
    output carry_out,
    output reg equal_out
);

localparam NUM181 = WIDTH/4; // a 181 for every 4 bits

wire [NUM181-1:0] equals; // equals on the 181s
wire [NUM181-1:0] CP_bar; // P outs on the 181s
wire [NUM181-1:0] CG_bar; // G outs on the 181s
wire [NUM181-2:0] carries; // carry lookaheads from the 182

// set equal_out to true only if all the bits in equal are set.
// use a fancy loop to deal with variable WIDTH
always_comb begin
    int count = 0;
    for (int i = 0; i < NUM181; i++) begin
        if (equals[i])
            count++;
    end
    equal_out = count == NUM181;
end

// stamp out 4 181s and a 182
// NOTE: assumes WIDTH=16.
// TODO: use generate to stamp out a variable number of 181s

// first 181, bits [3:0]
TopLevel74181b ALU0 (
    .S(op_in),
    .M(mode),
    .CNb(carry_in), // carry in from the outside
    .A(A_in[3:0]),
    .B(B_in[3:0]),

    .X(CP_bar[0]),
    .Y(CG_bar[0]),
    .AEB(equals[0]),
    .CN4b(),
    .F(out[3:0])
);

// second 181, bits [7:4]
TopLevel74181b ALU1 (
    .S(op_in),
    .M(mode),
    .CNb(carries[0]),
    .A(A_in[7:4]),
    .B(B_in[7:4]),

    .X(CP_bar[1]),
    .Y(CG_bar[1]),
    .AEB(equals[1]),
    .CN4b(),
    .F(out[7:4])
);

// third 181, bits [11:8]
TopLevel74181b ALU2 (
    .S(op_in),
    .M(mode),
    .CNb(carries[1]),
    .A(A_in[11:8]),
    .B(B_in[11:8]),

    .X(CP_bar[2]),
    .Y(CG_bar[2]),
    .AEB(equals[2]),
    .CN4b(),
    .F(out[11:8])
);

// fourth 181, bits [15:12]
TopLevel74181b ALU3 (
    .S(op_in),
    .M(mode),
    .CNb(carries[2]),
    .A(A_in[15:12]),
    .B(B_in[15:12]),

    .X(CP_bar[3]),
    .Y(CG_bar[3]),
    .AEB(equals[3]),
    .CN4b(carry_out), // carry out of the module
    .F(out[15:12])
);

// a 182 carry look ahead
TopLevel74182b CLA (
    .CN(carry_in),
    .PB(CP_bar),
    .GB(CG_bar),

    .PBo(),
    .GBo(),

    .CNX(carries[0]),
    .CNY(carries[1]),
    .CNZ(carries[2])
);

endmodule

// from https://web.eecs.umich.edu/~jhayes/iscas.restore/74182.html

/****************************************************************************
 *                                                                          *
 *  VERILOG BEHAVIORAL DESCRIPTION OF THE TI 74182 CIRCUIT                  *
 *                                                                          *
 *  Function: Carry Lookahead Generator                                     *
 *                                                                          *
 *  Written by: Mark C. Hansen                                              *
 *                                                                          *
 *  Last modified: Dec 10, 1997                                             *
 *                                                                          *
 ****************************************************************************/

module Circuit74182 (CN, PB, GB, PBo, GBo, CNX, CNY, CNZ);

  input[3:0]    PB, GB;
  input	        CN;

  output	PBo, GBo, CNX, CNY, CNZ;

  TopLevel74182b Ckt74182b (CN, PB, GB, PBo, GBo, CNX, CNY, CNZ);

endmodule /* Circuit74182 */

/*************************************************************************/

module TopLevel74182b (CN, PB, GB, PBo, GBo, CNX, CNY, CNZ);

  input[3:0]	PB, GB;
  input         CN;

  output	PBo, GBo, CNX, CNY, CNZ;

  assign PBo = (PB[0]|PB[1]|PB[2]|PB[3]);
  assign GBo = ((GB[0]&GB[1]&GB[2]&GB[3]) |
                (PB[1]&GB[1]&GB[2]&GB[3]) |
                (PB[2]&GB[2]&GB[3]) |
                (PB[3]&GB[3]));
  assign CNX = ~((PB[0]&GB[0]) |
                 (~CN&GB[0]));
  assign CNY = ~((PB[1]&GB[1]) |
                 (PB[0]&GB[0]&GB[1]) |
                 (~CN&GB[0]&GB[1]));
  assign CNZ = ~((PB[2]&GB[2]) |
                 (PB[1]&GB[1]&GB[2]) |
                 (PB[0]&GB[0]&GB[1]&GB[2]) |
                 (~CN&GB[0]&GB[1]&GB[2]));

endmodule /* TopLevel74182b */

// from https://web.eecs.umich.edu/~jhayes/iscas.restore/74181.html

/****************************************************************************
 *                                                                          *
 *  VERILOG BEHAVIORAL DESCRIPTION OF THE TI 74181 CIRCUIT                  *
 *                                                                          *
 *  Function: 4-bit ALU/Function Generator                                  *
 *                                                                          *
 *  Written by: Mark C. Hansen                                              *
 *                                                                          *
 *  Last modified: Dec 11, 1997                                             *
 *                                                                          *
 ****************************************************************************/

module Circuit74181b (S, A, B, M, CNb, F, X, Y, CN4b, AEB);

  input [3:0] A, B, S;
  input CNb, M;
  output [3:0] F;
  output AEB, X, Y, CN4b;

  TopLevel74181b Ckt74181b (S, A, B, M, CNb, F, X, Y, CN4b, AEB);

endmodule /* Circuit74181b */

/*************************************************************************/

module TopLevel74181b (S, A, B, M, CNb, F, X, Y, CN4b, AEB);

  input [3:0] A, B, S;
  input CNb, M;
  output [3:0] F;
  output AEB, X, Y, CN4b;
  wire [3:0] E, D, C, Bb;

  Emodule Emod1 (A, B, S, E);
  Dmodule Dmod2 (A, B, S, D);
  CLAmodule CLAmod3(E, D, CNb, C, X, Y, CN4b);
  Summodule Summod4(E, D, C, M, F, AEB);

endmodule /* TopLevel74181b */

/*************************************************************************/

module Emodule (A, B, S, E);

  input [3:0] A, B, S;
  output [3:0] E;
  wire [3:0]  ABS3, ABbS2;

  assign ABS3 = A&B&{4{S[3]}};
  assign ABbS2 = A&~B&{4{S[2]}};
  assign E = ~(ABS3|ABbS2);

endmodule /* Emodule */

/*************************************************************************/

module Dmodule (A, B, S, D);

  input [3:0] A, B, S;
  output [3:0] D;
  wire [3:0]  BbS1, BS0;

  assign BbS1 = ~B&{4{S[1]}};
  assign BS0 = B&{4{S[0]}};
  assign D = ~(BbS1|BS0|A);

endmodule /* Dmodule */

/*************************************************************************/

module CLAmodule(Gb, Pb, CNb, C, X, Y, CN4b);

  input [3:0] Gb, Pb;
  input CNb;
  output [3:0] C;
  output X, Y, CN4b;

  assign C[0] = ~CNb;
  assign C[1] = ~(Pb[0]|(CNb&Gb[0]));
  assign C[2] = ~(Pb[1]|(Pb[0]&Gb[1])|(CNb&Gb[0]&Gb[1]));
  assign C[3] = ~(Pb[2]|(Pb[1]&Gb[2])|(Pb[0]&Gb[1]&Gb[2])|(CNb&Gb[0]&Gb[1]&Gb[2]));
  assign X = ~&Gb;
  assign Y = ~(Pb[3]|(Pb[2]&Gb[3])|(Pb[1]&Gb[2]&Gb[3])|(Pb[0]&Gb[1]&Gb[2]&Gb[3]));
  assign CN4b = ~(Y&~(&Gb&CNb));

endmodule /* CLAmodule */

/*************************************************************************/

module Summodule(E, D, C, M, F, AEB);

  input [3:0] E, D, C;
  input M;
  output [3:0] F;
  output AEB;

  assign F = (E ^ D) ^ (C|{4{M}});
  assign AEB = &F;

endmodule /* Summodule */

