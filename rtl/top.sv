// top.sv

module top(
    input logic             clk,
    input logic             rstn,

    output logic    [2:0]   o_tmds_p,
    output logic    [2:0]   o_tmds_n,
    output logic            o_tmds_c_p,
    output logic            o_tmds_c_n
);

logic pixel_clk;
logic ddr_clk;

clk_wiz_0 u_CLKS (
    .pixel_clk(pixel_clk),
    .ddr_clk(ddr_clk),
    .resetn(rstn),
    .locked(),
    .clk_in1(clk)
);

logic [2:0] tmds;
logic tmds_c;
hdmi_transmitter_core #(
    .RESOLUTION ("VGA")
) u_HDMI_TX (
    .clk        (pixel_clk),
    .rstn       (rstn),
    .ddr_clk    (ddr_clk),
    .o_tmds     (tmds),
    .o_tmds_c   (tmds_c)
);

OBUFDS #(.IOSTANDARD("TMDS_33")) u_DIFF_0 (.O(o_tmds_p[0]), .OB(o_tmds_n[0]), .I(tmds[0]));
OBUFDS #(.IOSTANDARD("TMDS_33")) u_DIFF_1 (.O(o_tmds_p[1]), .OB(o_tmds_n[1]), .I(tmds[1]));
OBUFDS #(.IOSTANDARD("TMDS_33")) u_DIFF_2 (.O(o_tmds_p[2]), .OB(o_tmds_n[2]), .I(tmds[2]));
OBUFDS #(.IOSTANDARD("TMDS_33")) u_DIFF_C (.O(o_tmds_c_p), .OB(o_tmds_c_n), .I(tmds_c));

endmodule
