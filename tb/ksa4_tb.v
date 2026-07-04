// Exhaustive functional testbench for ksa4_reg: all 16 x 16 x 2 = 512
// input combinations. Two-cycle latency (input flop + output flop).
`timescale 1ns/1ps
module ksa4_tb;

    reg        clk, rst_n;
    reg  [3:0] a, b;
    reg        cin;
    wire [3:0] sum;
    wire       cout;

    ksa4_reg dut (
        .clk(clk), .rst_n(rst_n),
        .a(a), .b(b), .cin(cin),
        .sum(sum), .cout(cout)
    );

    always #5 clk = ~clk;

    integer ia, ib, ic;
    integer pass_count, fail_count;
    reg [4:0] expected;

    initial begin
        clk = 0; rst_n = 0;
        a = 0; b = 0; cin = 0;
        pass_count = 0; fail_count = 0;

        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        for (ia = 0; ia < 16; ia = ia + 1) begin
            for (ib = 0; ib < 16; ib = ib + 1) begin
                for (ic = 0; ic < 2; ic = ic + 1) begin
                    @(negedge clk);
                    a   = ia[3:0];
                    b   = ib[3:0];
                    cin = ic[0];
                    expected = ia + ib + ic;
                    // inputs captured at next posedge, outputs one edge later
                    @(posedge clk);
                    @(posedge clk);
                    #1;
                    if ({cout, sum} !== expected) begin
                        fail_count = fail_count + 1;
                        $display("MISMATCH: a=%0d b=%0d cin=%0d -> got {%b,%b} expected %b",
                                 ia, ib, ic, cout, sum, expected);
                    end else begin
                        pass_count = pass_count + 1;
                    end
                end
            end
        end

        $display("RESULT: %0d passed, %0d failed out of %0d vectors",
                 pass_count, fail_count, pass_count + fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
