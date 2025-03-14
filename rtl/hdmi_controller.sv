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
    input logic             clk,
    input logic             rstn,

    output logic            o_pixel_inc,

    input logic     [$clog2(HMAX)-1:0]  i_hcount,
    input logic     [$clog2(VMAX)-1:0]  i_vcount,

    output logic            o_hsync,
    output logic            o_vsync,
    output logic            o_data_en
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

assign o_hsync = hsync;
assign o_vsync = vsync;
assign o_data_en = data_en;

endmodule
