// tmds_encoder.sv

module tmds_encoder(
    input logic             clk,
    input logic             i_data_en,
    input logic     [7:0]   i_data,
    input logic     [1:0]   i_ctrl,
    output logic    [9:0]   o_q
);

function logic signed [7:0] countones(input logic [7:0] d);
    countones = 0;
    foreach (d[i]) begin
        countones += {7'b0, d[i] == 1};
    end
endfunction

function logic [7:0] countzeroes(input logic [7:0] d);
    countzeroes = 0;
    foreach (d[i]) begin
        countzeroes += {7'b0, d[i] == 0};
    end
endfunction

logic [8:0] q_m;
logic signed [7:0] q_m_ones;
always_comb begin
    q_m_ones = countones(i_data);

    q_m[0] = i_data[0];
    if ((q_m_ones > 4) || ((q_m_ones == 4) && (!i_data[0]))) begin
        q_m[1] = ~(q_m[0] ^ i_data[1]);
        q_m[2] = ~(q_m[1] ^ i_data[2]);
        q_m[3] = ~(q_m[2] ^ i_data[3]);
        q_m[4] = ~(q_m[3] ^ i_data[4]);
        q_m[5] = ~(q_m[4] ^ i_data[5]);
        q_m[6] = ~(q_m[5] ^ i_data[6]);
        q_m[7] = ~(q_m[6] ^ i_data[7]);
        q_m[8] = 1'b0;
    end else begin
        for(int i=1; i < 8; i++) begin
            q_m[i] = q_m[i - 1] ^ i_data[i];
        end
        q_m[8] = 1'b1;
    end
end

logic signed [7:0] cnt;
logic signed [7:0] cnt_prev = 0;

always_ff @(posedge clk) begin
    cnt_prev <= cnt;
end

logic [9:0] q;
logic signed [7:0] q_ones;
logic signed [7:0] q_zeroes;

always_comb begin
    q_ones = countones(q_m[7:0]);
    q_zeroes = countzeroes(q_m[7:0]);

    if (i_data_en) begin
        if ((cnt_prev == 0) || (q_ones == q_zeroes)) begin
            q[9] = ~q_m[8];
            q[8] = q_m[8];
            q[7:0]  = (q_m[8]) ? q_m[7:0] : ~q_m[7:0];
            if (q_m[8]) begin
                cnt = cnt_prev + (q_ones - q_zeroes);
            end else begin
                cnt = cnt_prev + (q_zeroes - q_ones);
            end
        end else begin
            if (((cnt_prev > 0) && (q_ones > q_zeroes)) ||
            ((cnt_prev < 0) && (q_ones < q_zeroes))) begin
                q[9] = 1'b1;
                q[8] = q_m[8];
                q[7:0] = ~q_m[7:0];
                cnt = cnt_prev + signed'({6'b0, q_m[8], 1'b0}) + (q_zeroes - q_ones);
            end else begin
                q[9] = 1'b0;
                q[8] = q_m[8];
                q[7:0] = q_m[7:0];
                cnt = cnt_prev - signed'({6'b0, ~q_m[8], 1'b0}) + (q_ones - q_zeroes);
            end
        end
    end else begin
        unique case (i_ctrl)
            0: q = 10'b0010101011;
            1: q = 10'b1101010100;
            2: q = 10'b0010101010;
            3: q = 10'b1101010101;
        endcase
        cnt = 0;
    end
end

assign o_q = q;

endmodule
