// top.sv

module top(
    input logic             clk,
    input logic             rstn,

    output logic            o_tmds_red_p,
    output logic            o_tmds_red_n,
    output logic            o_tmds_grn_p,
    output logic            o_tmds_grn_n,
    output logic            o_tmds_blu_p,
    output logic            o_tmds_blu_n,
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

logic [9:0] tmds_red;
logic [9:0] tmds_grn;
logic [9:0] tmds_blu;
// logic tmds_c;
hdmi_transmitter_core #(
    .RESOLUTION ("VGA")
) u_HDMI_TX (
    .clk            (pixel_clk),
    .rstn           (rstn),
    .i_rgb_valid    (1'b0),
    .i_rgb_red      (8'b0),
    .i_rgb_grn      (8'b0),
    .i_rgb_blu      (8'b0),
    .i_cfg_valid    (1'b0),
    .i_cfg_data     (32'b0),
    .o_tmds_red     (tmds_red),
    .o_tmds_grn     (tmds_grn),
    .o_tmds_blu     (tmds_blu)
);

// output serializer
logic [9:0] tmds_c;
assign tmds_c = 10'b00_0001_1111;   // pixel clock

logic serdes_reset = 1;
always_ff @(posedge pixel_clk) begin
    serdes_reset <= 0;
end

logic [9:0] tmds_parallel[4];
assign tmds_parallel = {tmds_c, tmds_red, tmds_grn, tmds_blu};

logic tmds_serial_c;
logic tmds_serial_red;
logic tmds_serial_grn;
logic tmds_serial_blu;
logic [3:0] tmds_serial;
assign {tmds_serial_blu, tmds_serial_grn, tmds_serial_red, tmds_serial_c} = tmds_serial[3:0];

logic [1:0] oserdes_shift[4];

genvar i;
generate
    for (i=0; i<4; i++) begin: g_oserdes
        OSERDESE2 #(
            .DATA_RATE_OQ("DDR"),
            .DATA_RATE_TQ("SDR"),
            .DATA_WIDTH(10),
            .SERDES_MODE("MASTER"),
            .TRISTATE_WIDTH(1),
            .TBYTE_CTL("FALSE"),
            .TBYTE_SRC("FALSE")
        ) u_OSERDES0 (
            .OQ(tmds_serial[i]),
            .OFB(),
            .TQ(),
            .TFB(),
            .SHIFTOUT1(),
            .SHIFTOUT2(),
            .TBYTEOUT(),
            .CLK(ddr_clk),
            .CLKDIV(pixel_clk),
            .D1(tmds_parallel[i][0]),
            .D2(tmds_parallel[i][1]),
            .D3(tmds_parallel[i][2]),
            .D4(tmds_parallel[i][3]),
            .D5(tmds_parallel[i][4]),
            .D6(tmds_parallel[i][5]),
            .D7(tmds_parallel[i][6]),
            .D8(tmds_parallel[i][7]),
            .TCE(1'b0),
            .OCE(1'b1),
            .TBYTEIN(1'b0),
            .RST(serdes_reset),
            .SHIFTIN1(oserdes_shift[i][0]),
            .SHIFTIN2(oserdes_shift[i][1]),
            .T1(1'b0),
            .T2(1'b0),
            .T3(1'b0),
            .T4(1'b0)
        );
        OSERDESE2 #(
            .DATA_RATE_OQ("DDR"),
            .DATA_RATE_TQ("SDR"),
            .DATA_WIDTH(10),
            .SERDES_MODE("SLAVE"),
            .TRISTATE_WIDTH(1),
            .TBYTE_CTL("FALSE"),
            .TBYTE_SRC("FALSE")
        ) u_OSERDES1 (
            .OQ(),
            .OFB(),
            .TQ(),
            .TFB(),
            .SHIFTOUT1(oserdes_shift[i][0]),
            .SHIFTOUT2(oserdes_shift[i][1]),
            .TBYTEOUT(),
            .CLK(ddr_clk),
            .CLKDIV(pixel_clk),
            .D1(1'b0),
            .D2(1'b0),
            .D3(tmds_parallel[i][8]),
            .D4(tmds_parallel[i][9]),
            .D5(1'b0),
            .D6(1'b0),
            .D7(1'b0),
            .D8(1'b0),
            .TCE(1'b0),
            .OCE(1'b1),
            .TBYTEIN(1'b0),
            .RST(serdes_reset),
            .SHIFTIN1(1'b0),
            .SHIFTIN2(1'b0),
            .T1(1'b0),
            .T2(1'b0),
            .T3(1'b0),
            .T4(1'b0)
        );
    end
endgenerate

OBUFDS #(.IOSTANDARD("TMDS_33")) u_RBUF (.O(o_tmds_red_p),  .OB(o_tmds_red_n),  .I(tmds_serial_red));
OBUFDS #(.IOSTANDARD("TMDS_33")) u_GBUF (.O(o_tmds_grn_p),  .OB(o_tmds_grn_n),  .I(tmds_serial_grn));
OBUFDS #(.IOSTANDARD("TMDS_33")) u_BBUF (.O(o_tmds_blu_p),  .OB(o_tmds_blu_n),  .I(tmds_serial_blu));
OBUFDS #(.IOSTANDARD("TMDS_33")) u_CBUF (.O(o_tmds_c_p),    .OB(o_tmds_c_n),    .I(tmds_serial_c));

endmodule
