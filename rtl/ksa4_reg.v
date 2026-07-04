// 4-bit Kogge-Stone adder, registered I/O (flopped inputs and outputs).
// Prefix tree: bit-level G/P -> level 1 (span 1) -> level 2 (span 2).
// cin is folded into the bit-0 generate so the tree produces all carries.
module ksa4_reg (
    input        clk,
    input        rst_n,
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output reg [3:0] sum,
    output reg       cout
);

    // ---- input registers ----
    reg [3:0] a_q, b_q;
    reg       cin_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_q   <= 4'b0;
            b_q   <= 4'b0;
            cin_q <= 1'b0;
        end else begin
            a_q   <= a;
            b_q   <= b;
            cin_q <= cin;
        end
    end

    // ---- bit-level generate / propagate ----
    wire [3:0] g0 = a_q & b_q;
    wire [3:0] p0 = a_q ^ b_q;

    // fold cin into bit-0 generate
    wire [3:0] g0c;
    assign g0c[0]   = g0[0] | (p0[0] & cin_q);
    assign g0c[3:1] = g0[3:1];

    // ---- prefix level 1 (span 1) ----
    wire [3:0] g1, p1;
    assign g1[0] = g0c[0];
    assign p1[0] = p0[0];
    assign g1[1] = g0c[1] | (p0[1] & g0c[0]);
    assign p1[1] = p0[1] & p0[0];
    assign g1[2] = g0c[2] | (p0[2] & g0c[1]);
    assign p1[2] = p0[2] & p0[1];
    assign g1[3] = g0c[3] | (p0[3] & g0c[2]);
    assign p1[3] = p0[3] & p0[2];

    // ---- prefix level 2 (span 2) ----
    wire [3:0] g2;
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign g2[3] = g1[3] | (p1[3] & g1[1]);

    // ---- sum / carry-out ----
    wire [3:0] sum_c  = p0 ^ {g2[2:0], cin_q};
    wire       cout_c = g2[3];

    // ---- output registers ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum  <= 4'b0;
            cout <= 1'b0;
        end else begin
            sum  <= sum_c;
            cout <= cout_c;
        end
    end

endmodule
