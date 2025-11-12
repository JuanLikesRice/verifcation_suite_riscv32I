`timescale 1ns/1ps
`ifndef size_Fp_fmt
`define size_Fp_fmt 3
`endif

module FPU_MULT_I #(
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size = 8
)(
    input                           clk,
    input                           rst,
    input                           req_in,
    input      [`size_Fp_fmt-1:0]   rm,
    input      [PARAM_Fp_size-1:0]  A,
    input      [PARAM_Fp_size-1:0]  B,
    output     [PARAM_Fp_size-1:0]  Out,
    output                          valid_out
);
    // constants
    localparam [31:0] QNAN = 32'h7FC0_0000;

    // ------------------------------
    // valid pipeline s0..s4
    // ------------------------------
    reg v0,v1,v2,v3,v4;
    always @(posedge clk) begin
        if (rst) {v4,v3,v2,v1,v0} <= 5'b0;
        else     {v4,v3,v2,v1,v0} <= {v3,v2,v1,v0,req_in};
    end
    assign valid_out = v4;

    // ==============================
    // s0: capture
    // ==============================
    reg [31:0] A_s0, B_s0;
    reg [`size_Fp_fmt-1:0] rm_s0;
    always @(posedge clk) begin
        if (rst) begin
            A_s0  <= 32'd0;
            B_s0  <= 32'd0;
            rm_s0 <= {`size_Fp_fmt{1'b0}};
        end else if (req_in) begin               // capture only on valid request
            A_s0  <= A;
            B_s0  <= B;
            rm_s0 <= rm;
        end
    end

    // ==============================
    // s1: unpack + classify
    // ==============================
    wire        a_s = A_s0[31];
    wire [7:0]  a_e = A_s0[30:23];
    wire [22:0] a_m = A_s0[22:0];
    wire        b_s = B_s0[31];
    wire [7:0]  b_e = B_s0[30:23];
    wire [22:0] b_m = B_s0[22:0];

    wire a_is_zero = (a_e==8'h00) && (a_m==23'd0);
    wire b_is_zero = (b_e==8'h00) && (b_m==23'd0);
    wire a_is_inf  = (a_e==8'hFF) && (a_m==23'd0);
    wire b_is_inf  = (b_e==8'hFF) && (b_m==23'd0);
    wire a_is_nan  = (a_e==8'hFF) && (a_m!=23'd0);
    wire b_is_nan  = (b_e==8'hFF) && (b_m!=23'd0);

    wire        res_s_s1_w = a_s ^ b_s;
    reg         take_special_s1_w;
    reg [31:0]  special_out_s1_w;
    always @* begin
        take_special_s1_w = 1'b1;
        special_out_s1_w  = 32'h0000_0000;
        if (a_is_nan || b_is_nan)                         special_out_s1_w = QNAN;
        else if ((a_is_inf && b_is_zero) ||
                 (b_is_inf && a_is_zero))                 special_out_s1_w = QNAN;
        else if (a_is_inf || b_is_inf)                    special_out_s1_w = {res_s_s1_w,8'hFF,23'd0};
        else if (a_is_zero || b_is_zero)                  special_out_s1_w = {res_s_s1_w,8'h00,23'd0};
        else                                              take_special_s1_w = 1'b0;
    end

    wire [23:0] sig_a_s1_w = (a_e==8'h00) ? {1'b0,a_m} : {1'b1,a_m}; // subnormals get hidden 0
    wire [23:0] sig_b_s1_w = (b_e==8'h00) ? {1'b0,b_m} : {1'b1,b_m};

    // unbiased exponents (subnormal => -126)
    wire signed [9:0] ea_unb_s1_w = (a_e==8'h00) ? -10'sd126 : $signed({2'b00,a_e}) - 10'sd127;
    wire signed [9:0] eb_unb_s1_w = (b_e==8'h00) ? -10'sd126 : $signed({2'b00,b_e}) - 10'sd127;

    reg [`size_Fp_fmt-1:0] rm_s1;
    reg        res_s_s1, take_special_s1;
    reg [31:0] special_out_s1;
    reg [23:0] sig_a_s1, sig_b_s1;
    reg signed [9:0] ea_unb_s1, eb_unb_s1;
    always @(posedge clk) begin
        if (rst) begin
            rm_s1           <= 0;
            res_s_s1        <= 0;
            take_special_s1 <= 0;
            special_out_s1  <= 0;
            sig_a_s1        <= 0;
            sig_b_s1        <= 0;
            ea_unb_s1       <= 0;
            eb_unb_s1       <= 0;
        end else begin
            rm_s1           <= rm_s0;
            res_s_s1        <= res_s_s1_w;
            take_special_s1 <= take_special_s1_w;
            special_out_s1  <= special_out_s1_w;
            sig_a_s1        <= sig_a_s1_w;
            sig_b_s1        <= sig_b_s1_w;
            ea_unb_s1       <= ea_unb_s1_w;
            eb_unb_s1       <= eb_unb_s1_w;
        end
    end

    // ==============================
    // s2: 24x24 product + coarse normalize
    // ==============================
    wire [47:0] prod_uu_s2_w   = sig_a_s1 * sig_b_s1;
    wire        prod_msb_s2_w  = prod_uu_s2_w[47];                 // 1 for [2,4), 0 for [1,2)
    wire [47:0] prod_norm_s2_w = prod_msb_s2_w ? (prod_uu_s2_w >> 1) : prod_uu_s2_w;

    wire signed [10:0] e_sum_unb_s2_w    = $signed(ea_unb_s1) + $signed(eb_unb_s1) + (prod_msb_s2_w ? 11'sd1 : 11'sd0);
    wire signed [10:0] e_biased_pre_s2_w = e_sum_unb_s2_w + 11'sd127;

    wire [23:0] mant24_pre_s2_w = prod_norm_s2_w[46:23];           // includes hidden 1
    wire [22:0] rem23_pre_s2_w  = prod_norm_s2_w[22:0];            // GRS source

    reg [`size_Fp_fmt-1:0] rm_s2;
    reg        res_s_s2, take_special_s2;
    reg [31:0] special_out_s2;
    reg signed [10:0] e_biased_pre_s2;
    reg [23:0] mant24_pre_s2;
    reg [22:0] rem23_pre_s2;
    always @(posedge clk) begin
        if (rst) begin
            rm_s2            <= 0;
            res_s_s2         <= 0;
            take_special_s2  <= 0;
            special_out_s2   <= 0;
            e_biased_pre_s2  <= 0;
            mant24_pre_s2    <= 0;
            rem23_pre_s2     <= 0;
        end else begin
            rm_s2            <= rm_s1;
            res_s_s2         <= res_s_s1;
            take_special_s2  <= take_special_s1;
            special_out_s2   <= special_out_s1;
            e_biased_pre_s2  <= e_biased_pre_s2_w;
            mant24_pre_s2    <= mant24_pre_s2_w;
            rem23_pre_s2     <= rem23_pre_s2_w;
        end
    end

    // ==============================
    // helpers: rounding + overflow pack
    // ==============================
    function [0:0] inc_rnd;
        input [2:0] rm_f;
        input sgn, lsb, g, r, s, is_mid;
        begin
            case (rm_f)
                3'b000: inc_rnd = (g & (r|s)) | (is_mid & lsb); // RNE
                3'b001: inc_rnd = 1'b0;                         // RTZ
                3'b010: inc_rnd =  sgn & (g|r|s);               // RDN
                3'b011: inc_rnd = ~sgn & (g|r|s);               // RUP
                3'b100: inc_rnd =  g;                           // RMM
                default: inc_rnd = (g & (r|s)) | (is_mid & lsb);
            endcase
        end
    endfunction

    function [31:0] pack_overflow;
        input sgn;
        input [2:0] rm_f;
        reg [31:0] maxfin;
        begin
            maxfin = {sgn, 8'hFE, 23'h7FFFFF};
            case (rm_f)
                3'b001: pack_overflow = maxfin;                                   // RTZ
                3'b010: pack_overflow = sgn ? {1'b1,8'hFF,23'd0} : maxfin;        // RDN
                3'b011: pack_overflow = sgn ? maxfin : {1'b0,8'hFF,23'd0};        // RUP
                default: pack_overflow = {sgn,8'hFF,23'd0};                        // RNE/RMM
            endcase
        end
    endfunction

    // ==============================
    // s3: normal rounding prep
    // ==============================
    wire g_n   = rem23_pre_s2[22];
    wire r_n   = rem23_pre_s2[21];
    wire s_n   = |rem23_pre_s2[20:0];
    wire lsb_n = mant24_pre_s2[0];
    wire tie_n = g_n & ~r_n & ~s_n;

    wire do_inc_n = inc_rnd(rm_s2, res_s_s2, lsb_n, g_n, r_n, s_n, tie_n);

    wire [24:0] mant25_n = {1'b0,mant24_pre_s2} + {24'd0,do_inc_n};
    wire        carry_n  = mant25_n[24];
    wire [23:0] mant24_n = carry_n ? mant25_n[24:1] : mant25_n[23:0];

    wire signed [10:0] e_biased_n_s3_w = e_biased_pre_s2 + (carry_n ? 11'sd1 : 11'sd0);

    wire normal_ok_s3_w = (e_biased_pre_s2 > 0);         // >0 means normal domain possible

    // for subnormal path
    wire [46:0] sig47_s3_w = {mant24_pre_s2, rem23_pre_s2};
    wire signed [10:0] k_s3_w = 11'sd1 - e_biased_pre_s2; // shift amount into exp=0

    reg [`size_Fp_fmt-1:0] rm_s3;
    reg        res_s_s3, take_special_s3;
    reg [31:0] special_out_s3;
    reg [23:0] mant24_n_s3;
    reg signed [10:0] e_biased_n_s3, e_biased_pre_s3;
    reg        normal_ok_s3;
    reg [46:0] sig47_s3;
    reg signed [10:0] k_s3;
    always @(posedge clk) begin
        if (rst) begin
            rm_s3           <= 0;
            res_s_s3        <= 0;
            take_special_s3 <= 0;
            special_out_s3  <= 0;
            mant24_n_s3     <= 0;
            e_biased_n_s3   <= 0;
            e_biased_pre_s3 <= 0;
            normal_ok_s3    <= 0;
            sig47_s3        <= 0;
            k_s3            <= 0;
        end else begin
            rm_s3           <= rm_s2;
            res_s_s3        <= res_s_s2;
            take_special_s3 <= take_special_s2;
            special_out_s3  <= special_out_s2;
            mant24_n_s3     <= mant24_n;
            e_biased_n_s3   <= e_biased_n_s3_w;
            e_biased_pre_s3 <= e_biased_pre_s2;
            normal_ok_s3    <= normal_ok_s3_w;
            sig47_s3        <= sig47_s3_w;
            k_s3            <= k_s3_w;
        end
    end

    // ==============================
    // s4: subnormal path + final select
    // ==============================
    reg [46:0] shifted47;
    reg        sticky_dn;
    reg [46:0] mask47;
    always @* begin
        if (k_s3 <= 0) begin
            shifted47 = sig47_s3;
            sticky_dn = 1'b0;
        end else if (k_s3 >= 11'sd47) begin
            shifted47 = 47'd0;
            sticky_dn = |sig47_s3;
        end else begin
            shifted47 = sig47_s3 >> k_s3[5:0];
            mask47   = (47'd1 << k_s3[5:0]) - 1;
            sticky_dn = |(sig47_s3 & mask47);
        end
    end

    wire [22:0] frac_dn_pre = shifted47[46:24];
    wire        g_dn        = shifted47[23];
    wire        r_dn        = shifted47[22];
    wire        s_dn_any    = sticky_dn | |shifted47[21:0];

    wire        lsb_dn      = frac_dn_pre[0];
    wire        tie_dn      = g_dn & ~r_dn & ~s_dn_any;
    wire        do_inc_dn   = inc_rnd(rm_s3, res_s_s3, lsb_dn, g_dn, r_dn, s_dn_any, tie_dn);

    wire [23:0] frac_dn_inc = {1'b0, frac_dn_pre} + {23'd0, do_inc_dn};
    wire        carry_dn    = frac_dn_inc[23];

    wire [7:0]  exp_dn_out  = carry_dn ? 8'd1 : 8'd0;
    wire [22:0] frac_dn_out = carry_dn ? 23'd0 : frac_dn_inc[22:0];

    wire [31:0] normal_out  = {res_s_s3, e_biased_n_s3[7:0], mant24_n_s3[22:0]};
    wire [31:0] subnorm_out = {res_s_s3, exp_dn_out,         frac_dn_out};

    wire        overflow    = (e_biased_n_s3 >= 11'sd255);
    wire        take_sub    = (!normal_ok_s3) || (e_biased_n_s3 <= 0);

    reg [31:0] out_s4;
    always @* begin
        if (take_special_s3) out_s4 = special_out_s3;
        else if (overflow)   out_s4 = pack_overflow(res_s_s3, rm_s3);
        else if (take_sub)   out_s4 = subnorm_out;
        else                 out_s4 = normal_out;
    end

    // ==============================
    // s5: final register aligned to v4
    // ==============================
    reg [31:0] Out_r;
    always @(posedge clk) begin
        if (rst) Out_r <= 32'd0;
        else if (v4)   Out_r <= out_s4;
    end
    assign Out = Out_r;

endmodule
