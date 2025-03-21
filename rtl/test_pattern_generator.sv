// test_pattern_generator.sv

module test_pattern_generator #(
    parameter int                       HMAX = 800,
    parameter int                       VMAX = 600,
    parameter bit [$clog2(HMAX)-1:0]    HA = 640,
    parameter bit [$clog2(VMAX)-1:0]    VA = 480
)(
    input logic             clk,
    input logic             rstn,

    input logic     [$clog2(HMAX)-1:0]  i_hcount,
    input logic     [$clog2(VMAX)-1:0]  i_vcount,

    output logic    [7:0]   o_blu,
    output logic    [7:0]   o_grn,
    output logic    [7:0]   o_red
);

logic en;
always_comb begin
    en = (i_hcount < HA) && (i_vcount < VA);
end

// SMPTE ECR 1-1978 Color Bars
localparam bit [$clog2(VMAX)-1:0] VTop = $clog2(VMAX)'(int'(0.67 * VA));
localparam bit [$clog2(VMAX)-1:0] VMid = $clog2(VMAX)'(VTop + int'(0.08 * VA));

localparam bit [$clog2(HMAX)-1:0] HX0 = $clog2(HMAX)'(HA / 7);
localparam bit [$clog2(HMAX)-1:0] HX1 = HX0 + HX0;
localparam bit [$clog2(HMAX)-1:0] HX2 = HX1 + HX0;
localparam bit [$clog2(HMAX)-1:0] HX3 = HX2 + HX0;
localparam bit [$clog2(HMAX)-1:0] HX4 = HX3 + HX0;
localparam bit [$clog2(HMAX)-1:0] HX5 = HX4 + HX0;

localparam bit [$clog2(HMAX)-1:0] HY0 = $clog2(HMAX)'(int'(HA * 5/28)); // 5/4 * 1/7
localparam bit [$clog2(HMAX)-1:0] HY1 = HY0 + HY0;
localparam bit [$clog2(HMAX)-1:0] HY2 = HY1 + HY0;
localparam bit [$clog2(HMAX)-1:0] HY3 = HY2 + HY0;
localparam bit [$clog2(HMAX)-1:0] HY4 = HY3 + $clog2(HMAX)'(int'(int'(HA) / 21)); // 1/7 * 1/3
localparam bit [$clog2(HMAX)-1:0] HY5 = HY4 + $clog2(HMAX)'(int'(int'(HA) / 21));
localparam bit [$clog2(HMAX)-1:0] HY6 = HY5 + $clog2(HMAX)'(int'(int'(HA) / 21));

// always_ff @(posedge clk) begin
always_comb begin
    if (en) begin
        if (i_vcount < VTop) begin
            if (i_hcount < HX0) begin
                // 40% gray
                o_red = 8'd104;
                o_grn = 8'd104;
                o_blu = 8'd104;
            end else if (i_hcount < HX1) begin
                // 75% yellow
                o_red = 8'd180;
                o_grn = 8'd180;
                o_blu = 8'd16;
            end else if (i_hcount < HX2) begin
                // 75% cyan
                o_red = 8'd16;
                o_grn = 8'd180;
                o_blu = 8'd180;
            end else if (i_hcount < HX3) begin
                // 75% green
                o_red = 8'd16;
                o_grn = 8'd180;
                o_blu = 8'd16;
            end else if (i_hcount < HX4) begin
                // 75% magenta
                o_red = 8'd180;
                o_grn = 8'd16;
                o_blu = 8'd180;
            end else if (i_hcount < HX5) begin
                // 75% red
                o_red = 8'd180;
                o_grn = 8'd16;
                o_blu = 8'd16;
            end else begin
                // 75% blue
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd180;
            end
        end else if (i_vcount < VMid) begin
            if (i_hcount < HX0) begin
                // 75% blue
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd180;
            end else if (i_hcount < HX1) begin
                // 75% black
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd16;
            end else if (i_hcount < HX2) begin
                // 75% magenta
                o_red = 8'd180;
                o_grn = 8'd16;
                o_blu = 8'd180;
            end else if (i_hcount < HX3) begin
                // 75% black
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd16;
            end else if (i_hcount < HX4) begin
                // 75% cyan
                o_red = 8'd16;
                o_grn = 8'd180;
                o_blu = 8'd180;
            end else if (i_hcount < HX5) begin
                // 75% black
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd16;
            end else begin
                // 40% gray
                o_red = 8'd104;
                o_grn = 8'd104;
                o_blu = 8'd104;
            end
        end else begin
            if (i_hcount < HY0) begin
                // -I
                o_red = 8'd16;
                o_grn = 8'd70;
                o_blu = 8'd106;
            end else if (i_hcount < HY1) begin
                // 100% white
                o_red = 8'd235;
                o_grn = 8'd235;
                o_blu = 8'd235;
            end else if (i_hcount < HY2) begin
                // +Q
                o_red = 8'd72;
                o_grn = 8'd16;
                o_blu = 8'd118;
            end else if (i_hcount < HY3) begin
                // 75% black
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd16;
            end else if (i_hcount < HY4) begin
                // black -4%
                o_red = 8'd26;
                o_grn = 8'd26;
                o_blu = 8'd26;
            end else if (i_hcount < HY5) begin
                // 75% black
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd16;
            end else if (i_hcount < HY6) begin
                // black +4%
                o_red = 8'd6;
                o_grn = 8'd6;
                o_blu = 8'd6;
            end else begin
                // 75% black
                o_red = 8'd16;
                o_grn = 8'd16;
                o_blu = 8'd16;
            end
        end
    end else begin
        o_blu = 8'h0;
        o_grn = 8'h0;
        o_red = 8'h0;
    end
end


endmodule
