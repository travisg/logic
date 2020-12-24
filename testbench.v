/*
 * Copyright (c) 2011-2014 Travis Geiselbrecht
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
`timescale 1ns/1ns

module testbench(
    input clk
);

localparam trace = 0;

int count = 0;
wire rst = count < 5;

always_ff @(posedge clk) begin
    count <= count + 1;
end

always_comb begin
    if (trace)
        $display("count %d, rst %d", count, rst);
end

/// test of our ALU module
reg [15:0] A = 0;
reg [15:0] B = 1;
reg C_in = 1; // carry in
reg [3:0] select = 'b1001; // add
reg mode = 0; // alu ops

wire [15:0] out;
wire C_out;
wire Equal;

alu_181 alu(
    .A_in(A),
    .B_in(B),
    .out(out),
    .mode(mode),
    .op_in(select),
    .carry_in(C_in),
    .carry_out(C_out),
    .equal_out(Equal)
);

always_ff @(posedge clk) begin
    A <= A + 1;
    //A <= $random;
    //B <= $random;
    //A <= out;
    $display("A 0x%x, B 0x%x, out 0x%x, carry_out %d", A, B, out, C_out);
end

endmodule // testbench
