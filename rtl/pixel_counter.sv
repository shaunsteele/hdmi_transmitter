// pixel_counter.sv

module pixel_counter # (
    parameter int HMAX = 800,   // Horizontal Max Count
    parameter int VMAX = 600,   // Vertical Max Count
    parameter int HLEN = $clog2(HMAX),
    parameter int VLEN = $clog2(VMAX)
)(
    input logic                 clk,
    input logic                 rstn,

    input logic                 i_inc,
    // input logic                 i_clr,

    output logic    [HLEN-1:0]  o_hcount,
    output logic    [VLEN-1:0]  o_vcount//,
    // output logic                o_frame_start,
    // output logic                o_frame_end
);

logic [HLEN-1:0]    hc = 0;
logic [HLEN-1:0]    hc_next;
logic [VLEN-1:0]    vc = 0;
logic [VLEN-1:0]    vc_next;

always_ff @(posedge clk) begin
    if (!rstn) begin
        hc <= 0;
        vc <= 0;
    // end else if (i_clr) begin
    //     hc <= 0;
    //     vc <= 0;
    end else begin
        hc <= hc_next;
        vc <= vc_next;
    end
end

logic hc_max;
logic vc_max;
always_comb begin
    hc_max = hc == (HMAX[HLEN-1:0] - 1'b1);
    vc_max = vc == (VMAX[VLEN-1:0] - 1'b1);
end

always_comb begin
    if (i_inc) begin
        if (hc_max) begin
            hc_next = 0;
        end else begin
            hc_next = hc + 1;
        end
    end else begin
        hc_next = hc;
    end
end

always_comb begin
    if (i_inc && hc_max) begin
        if (vc_max) begin
            vc_next = 0;
        end else begin
            vc_next = vc + 1;
        end
    end else begin
        vc_next = vc;
    end
end

assign o_hcount = hc;
assign o_vcount = vc;

// logic fs;
// logic fe;

// always_comb begin
//     fs = (hc == 0) & (vc == 0);
//     fe = hc_max && vc_max;
// end

// assign o_frame_start = fs;
// assign o_frame_end = fe;

endmodule
