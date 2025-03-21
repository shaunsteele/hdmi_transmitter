// hdmi_transmitter_core.sv

module hdmi_transmitter_core #(
    parameter string    RESOLUTION = "VGA"
)(
    input logic             clk,
    input logic             rstn,

    // pixel stream
    input logic             i_rgb_valid,
    input logic     [7:0]   i_rgb_red,
    input logic     [7:0]   i_rgb_grn,
    input logic     [7:0]   i_rgb_blu,

    // configuration
    input logic             i_cfg_valid,
    input logic     [31:0]  i_cfg_data,

    // tmds encoded pixel stream
    output logic    [9:0]   o_tmds_red,
    output logic    [9:0]   o_tmds_grn,
    output logic    [9:0]   o_tmds_blu
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
logic [7:0] test_pattern_red;
logic [7:0] test_pattern_grn;
logic [7:0] test_pattern_blu;
test_pattern_generator #(
    .HMAX   (HTotal),
    .VMAX   (VTotal),
    .HA     (HActivePixels),
    .VA     (VActivePixels)
) u_TP (
    .clk        (clk),
    .rstn       (rstn),
    .i_hcount   (hcount),
    .i_vcount   (vcount),
    .o_red      (test_pattern_red),
    .o_grn      (test_pattern_grn),
    .o_blu      (test_pattern_blu)
);


logic           pixel_inc;
pixel_counter #(
    .HMAX   (HTotal),
    .VMAX   (VTotal)
) u_PC (
    .clk        (clk),
    .rstn       (rstn),
    .i_inc      (pixel_inc),
    .o_hcount   (hcount),
    .o_vcount   (vcount)
);

logic tmds_hsync;
logic tmds_vsync;
logic tmds_data_en;
logic [7:0] red;
logic [7:0] grn;
logic [7:0] blu;

hdmi_controller #(
    .HA         (HActivePixels),
    .HF         (HFrontPorch),
    .HS         (HSyncWidth),
    .HB         (HBackPorch),
    .VA         (VActivePixels),
    .VF         (VFrontPorch),
    .VS         (VSyncWidth),
    .VB         (VBackPorch)
) u_HC (
    .clk                (clk),
    .rstn               (rstn),
    .i_rgb_valid        (i_rgb_valid),
    .i_rgb_red          (i_rgb_red),
    .i_rgb_grn          (i_rgb_grn),
    .i_rgb_blu          (i_rgb_blu),
    .i_cfg_valid        (i_cfg_valid),
    .i_cfg_data         (i_cfg_data),
    .i_hcount           (hcount),
    .i_vcount           (vcount),
    .o_pixel_inc        (pixel_inc),
    .i_test_pattern_red (test_pattern_red),
    .i_test_pattern_grn (test_pattern_grn),
    .i_test_pattern_blu (test_pattern_blu),
    .o_hsync            (tmds_hsync),
    .o_vsync            (tmds_vsync),
    .o_data_en          (tmds_data_en),
    .o_red              (red),
    .o_grn              (grn),
    .o_blu              (blu)
);


// TMDS Encoders
logic [3:0] ctl;
assign ctl = 4'b0;

tmds_encoder u_RED (
    .clk            (clk),
    .i_data_en      (tmds_data_en),
    .i_data         (red),
    .i_ctrl         (ctl[3:2]),
    .o_q            (o_tmds_red)
);

tmds_encoder u_GRN (
    .clk            (clk),
    .i_data_en      (tmds_data_en),
    .i_data         (grn),
    .i_ctrl         (ctl[1:0]),
    .o_q            (o_tmds_grn)
);

tmds_encoder u_BLU (
    .clk            (clk),
    .i_data_en      (tmds_data_en),
    .i_data         (blu),
    .i_ctrl         ({tmds_hsync, tmds_vsync}),
    .o_q            (o_tmds_blu)
);

endmodule
