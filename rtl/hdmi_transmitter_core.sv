// hdmi_transmitter_core.sv

module hdmi_transmitter_core #(
    parameter string RESOLUTION = "VGA"
)(
    input logic                         clk,
    input logic                         rstn,

    // input logic                         i_rgb_valid,
    // input logic     [COLOR_DEPTH-1:0]   i_rgb_pixel,

    // serializer
    input logic                         ddr_clk,
    output logic    [2:0]               o_tmds,
    output logic                        o_tmds_c
);

generate
    // VGA
    // 640x480 active
    // 800x600 total
    // if (RESOLUTION == "VGA") begin
        localparam int HActivePixels = 640;
        localparam int HFrontPorch = 16;
        localparam int HSyncWidth = 96;
        localparam int HBackPorch = 48;

        localparam int VActivePixels = 480;
        localparam int VFrontPorch = 10;
        localparam int VSyncWidth = 2;
        localparam int VBackPorch = 33;
    // end
endgenerate

localparam int HTotal = HActivePixels + HFrontPorch + HSyncWidth + HBackPorch;
localparam int VTotal = VActivePixels + VFrontPorch + VSyncWidth + VBackPorch;

logic [$clog2(HTotal)-1:0]    hcount;
logic [$clog2(VTotal)-1:0]    vcount;
logic [7:0] buffer_blu;
logic [7:0] buffer_grn;
logic [7:0] buffer_red;
test_pattern_generator #(
    .HMAX   (HTotal),
    .VMAX   (VTotal),
    .HA (HActivePixels),
    .VA (VActivePixels)
) u_TP (
    .clk        (clk),
    .rstn       (rstn),
    .i_hcount   (hcount),
    .i_vcount   (vcount),
    .o_blu      (buffer_blu),
    .o_grn      (buffer_grn),
    .o_red      (buffer_red)
);


logic           pixel_inc;
pixel_counter #(
    .HMAX   (HTotal),
    .VMAX   (VTotal)
) u_PC (
    .clk            (clk),
    .rstn           (rstn),
    .i_inc          (pixel_inc),
    .o_hcount       (hcount),
    .o_vcount       (vcount)
);

logic tmds_hsync;
logic tmds_vsync;
logic tmds_data_en;
hdmi_controller #(
    .HA (HActivePixels),
    .HF (HFrontPorch),
    .HS (HSyncWidth),
    .HB (HBackPorch),
    .VA (VActivePixels),
    .VF (VFrontPorch),
    .VS (VSyncWidth),
    .VB (VBackPorch)
) u_HC (
    .clk            (clk),
    .rstn           (rstn),
    .o_pixel_inc    (pixel_inc),
    .i_hcount       (hcount),
    .i_vcount       (vcount),
    .o_hsync        (tmds_hsync),
    .o_vsync        (tmds_vsync),
    .o_data_en      (tmds_data_en)
);


logic [3:0] ctl;
assign ctl = 4'b0;

logic [9:0] tmds_d[4];

tmds_encoder u_BLU (
    .clk            (clk),
    .i_data_en      (tmds_data_en),
    .i_data         (buffer_blu),
    .i_ctrl         ({tmds_hsync, tmds_vsync}),
    .o_q            (tmds_d[0])
);
tmds_encoder u_GRN (
    .clk            (clk),
    .i_data_en      (tmds_data_en),
    .i_data         (buffer_grn),
    .i_ctrl         (ctl[1:0]),
    .o_q            (tmds_d[1])
);
tmds_encoder u_RED (
    .clk            (clk),
    .i_data_en      (tmds_data_en),
    .i_data         (buffer_red),
    .i_ctrl         (ctl[3:2]),
    .o_q            (tmds_d[2])
);
assign tmds_d[3] = 10'b0000011111;

logic [1:0] cascade[4];

logic [3:0] tmds_channels;
assign {o_tmds_c, o_tmds[2], o_tmds[1], o_tmds[0]} = tmds_channels[3:0];

logic serdes_reset = 1;
always_ff @(posedge clk) begin
    serdes_reset <= 0;
end

genvar i;
generate
    for (i=0; i<4; i++) begin: g_tmds_serdes
        OSERDESE2 #(
            .DATA_RATE_OQ("DDR"),
            .DATA_RATE_TQ("SDR"),
            .DATA_WIDTH(10),
            .SERDES_MODE("MASTER"),
            .TRISTATE_WIDTH(1),
            .TBYTE_CTL("FALSE"),
            .TBYTE_SRC("FALSE")
        ) u_OSERDES0 (
            .OQ(tmds_channels[i]),
            .OFB(),
            .TQ(),
            .TFB(),
            .SHIFTOUT1(),
            .SHIFTOUT2(),
            .TBYTEOUT(),
            .CLK(ddr_clk),
            .CLKDIV(clk),
            .D1(tmds_d[i][0]),
            .D2(tmds_d[i][1]),
            .D3(tmds_d[i][2]),
            .D4(tmds_d[i][3]),
            .D5(tmds_d[i][4]),
            .D6(tmds_d[i][5]),
            .D7(tmds_d[i][6]),
            .D8(tmds_d[i][7]),
            .TCE(1'b0),
            .OCE(1'b1),
            .TBYTEIN(1'b0),
            .RST(serdes_reset),
            .SHIFTIN1(cascade[i][0]),
            .SHIFTIN2(cascade[i][1]),
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
            .SHIFTOUT1(cascade[i][0]),
            .SHIFTOUT2(cascade[i][1]),
            .TBYTEOUT(),
            .CLK(ddr_clk),
            .CLKDIV(clk),
            .D1(1'b0),
            .D2(1'b0),
            .D3(tmds_d[i][8]),
            .D4(tmds_d[i][9]),
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

endmodule