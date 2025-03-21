// hdmi_controller.sv

module hdmi_controller #(
    parameter int HA = 640,
    parameter int HF = 16,
    parameter int HS = 96,
    parameter int HB = 48,
    parameter int HMAX = HA + HF + HS + HB,
    parameter int VA = 480,
    parameter int VF = 10,
    parameter int VS = 2,
    parameter int VB = 33,
    parameter int VMAX = VA + VF + VS + VB
)(
    input logic                         clk,
    input logic                         rstn,

    // input stream
    input logic                         i_rgb_valid,
    input logic     [7:0]               i_rgb_red,
    input logic     [7:0]               i_rgb_grn,
    input logic     [7:0]               i_rgb_blu,

    // configuration interface
    input logic                         i_cfg_valid,
    input logic     [31:0]              i_cfg_data,

    // pixel counter control
    input logic     [$clog2(HMAX)-1:0]  i_hcount,
    input logic     [$clog2(VMAX)-1:0]  i_vcount,
    output logic                        o_pixel_inc,

    // test pattern data
    input logic     [7:0]               i_test_pattern_red,
    input logic     [7:0]               i_test_pattern_grn,
    input logic     [7:0]               i_test_pattern_blu,

    // tmds encoding control
    output logic                        o_hsync,
    output logic                        o_vsync,
    output logic                        o_data_en,
    output logic    [7:0]               o_red,
    output logic    [7:0]               o_grn,
    output logic    [7:0]               o_blu

);

localparam int HLen = $clog2(HMAX);
localparam int VLen = $clog2(VMAX);

always_ff @(posedge clk) begin
   o_pixel_inc <= 1;
   
   if (!rstn) begin
    o_pixel_inc <= 0;
   end
end

logic hsync = 0;
logic vsync = 0;
logic data_en = 0;

always_ff @(posedge clk) begin
    hsync <= (i_hcount >= (HA[HLen-1:0] + HF[HLen-1:0])) && (i_hcount < (HA[HLen-1:0] + HF[HLen-1:0] + HS[HLen-1:0]));
    vsync <= (i_vcount >= (VA[VLen-1:0] + VF[VLen-1:0])) && (i_vcount < (VA[VLen-1:0] + VF[VLen-1:0] + VS[VLen-1:0]));
    data_en <= (i_hcount < HA[HLen-1:0]) && (i_vcount < VA[VLen-1:0]);

    if (!rstn) begin
        hsync <= 0;
        vsync <= 0;
        data_en <= 0;
    end    
end

localparam bit TestPatternInit = 1'b1;
logic [31:0]    cfg_data = {31'b0, TestPatternInit};
logic           test_pattern_en;

assign test_pattern_en = cfg_data[0];

always_ff @(posedge clk) begin
    if (i_cfg_valid) begin
        cfg_data <= i_cfg_data;
    end
    if (!rstn) begin
        cfg_data <= {31'b0, TestPatternInit};
    end
end

logic [7:0] red = 0;
logic [7:0] grn = 0;
logic [7:0] blu = 0;
always_ff @(posedge clk) begin
    if (test_pattern_en) begin
        red <= i_test_pattern_red;
        grn <= i_test_pattern_grn;
        blu <= i_test_pattern_blu;
    end else begin
        if (i_rgb_valid) begin
            red <= i_rgb_red;
            grn <= i_rgb_grn;
            blu <= i_rgb_blu;
        end
    end
    if (!rstn) begin
        red <= 8'b0;
        grn <= 8'b0;
        blu <= 8'b0;
    end
end

assign o_red = red;
assign o_grn = grn;
assign o_blu = blu;

assign o_hsync = hsync;
assign o_vsync = vsync;
assign o_data_en = data_en;

endmodule
