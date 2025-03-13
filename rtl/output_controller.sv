// hdmi_controller.sv

module hdmi_controller #(
    parameter int HA = 640,
    parameter int HF = 16,
    parameter int HS = 96,
    parameter int HB = 48,
    parameter int VA = 480,
    parameter int VF = 10,
    parameter int VS = 2,
    parameter int VB = 33
)(
    input logic             clk,
    input logic             rstn,

    output logic            o_inc,

    input logic     [11:0]  i_hcount,
    input logic     [11:0]  i_vcount,

    output logic            o_hsync,
    output logic            o_vsync,
    output logic            o_data_en
);

always_ff @(posedge clk) begin
   o_next_pixel <= 1;
   
   if (!rstn) begin
    o_next_pixel <= 0;
   end
end

logic hsync = 0;
logic vsync = 0;
logic data_en = 0;

always_ff @(posedge clk) begin
    hsync <= (i_hcount >= (HD + HF)) && (i_hcount < (HD + HF + HS));
    vsync <= (i_vcount >= (VD + VF)) && (i_vcount < (VD + VF + VS));
    data_en <= (i_hcount < HD) && (i_vcount < VD);

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
