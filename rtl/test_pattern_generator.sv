// test_pattern_generator.sv

module test_pattern_generator #(
    parameter int HMAX = 800,
    parameter int VMAX = 600,
    parameter int HA = 640,
    parameter int VA = 480
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

always_ff @(posedge clk) begin
    if (en) begin
        if (i_vcount < 128) begin
        // sixteen shades of gray
            o_blu <= {{(2){i_hcount[8]}}, {(2){i_hcount[7]}}, {(2){i_hcount[6]}}, {(2){i_hcount[5]}}};
            o_grn <= {{(2){i_hcount[8]}}, {(2){i_hcount[7]}}, {(2){i_hcount[6]}}, {(2){i_hcount[5]}}};
            o_red <= {{(2){i_hcount[8]}}, {(2){i_hcount[7]}}, {(2){i_hcount[6]}}, {(2){i_hcount[5]}}};
        end else if (i_vcount < 256) begin
        // 8 prime colors 50% intensity
            o_blu <= {{(4){i_hcount[8]}}, 4'b0};
            o_grn <= {{(4){i_hcount[7]}}, 4'b0};
            o_red <= {{(4){i_hcount[6]}}, 4'b0};
        end else begin
        // continuous color spectrum
            unique case (i_hcount[9:7])
                3'b000: begin
                    o_blu <= 8'h00;
                    o_grn <= i_hcount[9:2];
                    o_red <= 8'hFF;
                end
                3'b001: begin
                    o_blu <= 8'h00;
                    o_grn <= 8'hFF;
                    o_red <= ~i_hcount[9:2];
                end
                3'b010: begin
                    o_blu <= i_hcount[9:2];
                    o_grn <= 8'hFF;
                    o_red <= 8'h00;
                end
                3'b011: begin
                    o_blu <= 8'hFF;
                    o_grn <= ~i_hcount[9:2];
                    o_red <= 8'h00;
                end
                3'b100: begin
                    o_blu <= 8'hFF;
                    o_grn <= 8'h00;
                    o_red <= i_hcount[9:2];
                end
                3'b101: begin
                    o_blu <= ~i_hcount[9:2];
                    o_grn <= 8'h00;
                    o_red <= 8'hFF;
                end
                default: begin
                    o_blu <= 8'hFF;
                    o_grn <= 8'hFF;
                    o_red <= 8'hFF;
                end
            endcase
        end
    end
    if (!rstn) begin
        o_blu <= 8'h00;
        o_grn <= 8'h00;
        o_red <= 8'h00;
    end
end


endmodule
