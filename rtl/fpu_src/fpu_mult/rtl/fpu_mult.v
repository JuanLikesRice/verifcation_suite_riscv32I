
`timescale 1ns/1ps
`ifndef size_Fp_fmt
`define size_Fp_fmt 3
`endif

module FPU_MULT_I #(
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size = 8
)(
    input  [2:0] rm, 
    input  clk, 
    input  reset,
    input  mult_on,
    input  [PARAM_Fp_size-1:0] A,
    input  [PARAM_Fp_size-1:0] B,
    output valid,
    output [PARAM_Fp_size-1:0] Out
);
    localparam BIAS = 127;

    // unpack
    wire        a_s = A[31];
    wire [7:0]  a_e = A[30:23];
    wire [22:0] a_m = A[22:0];
    wire        b_s = B[31];
    wire [7:0]  b_e = B[30:23];
    wire [22:0] b_m = B[22:0];

    // classify
    wire a_is_zero = (a_e==8'h00) && (a_m==23'd0);
    wire b_is_zero = (b_e==8'h00) && (b_m==23'd0);
    wire a_is_inf  = (a_e==8'hFF) && (a_m==23'd0);
    wire b_is_inf  = (b_e==8'hFF) && (b_m==23'd0);
    wire a_is_nan  = (a_e==8'hFF) && (a_m!=23'd0);
    wire b_is_nan  = (b_e==8'hFF) && (b_m!=23'd0);

    localparam [31:0] QNAN = 32'h7FC0_0000;

    wire res_s = a_s ^ b_s;

    // specials
    reg [31:0] special_out;
    reg        take_special;
    always @* begin
        take_special = 1'b1;
        special_out  = 32'h0000_0000;
        if (a_is_nan || b_is_nan)                         special_out = QNAN;
        else if ((a_is_inf && b_is_zero) ||
                 (b_is_inf && a_is_zero))                 special_out = QNAN;
        else if (a_is_inf || b_is_inf)                    special_out = {res_s,8'hFF,23'd0};
        else if (a_is_zero || b_is_zero)                  special_out = {res_s,8'h00,23'd0};
        else                                              take_special = 1'b0;
    end

    // 24-bit significands
    wire [23:0] sig_a = (a_e==8'h00) ? {1'b0,a_m} : {1'b1,a_m};
    wire [23:0] sig_b = (b_e==8'h00) ? {1'b0,b_m} : {1'b1,b_m};

    // unbiased exponents (subnormals => -126)
    integer ea_unb, eb_unb;
    always @* begin
        ea_unb = (a_e==8'h00) ? -126 : (integer'(a_e) - BIAS);
        eb_unb = (b_e==8'h00) ? -126 : (integer'(b_e) - BIAS);
    end

    // raw product
    wire [47:0] prod_uu = sig_a * sig_b;

    // normalize right if product >= 2.0
    wire        prod_msb  = prod_uu[47];
    wire [47:0] prod_norm = prod_msb ? (prod_uu >> 1) : prod_uu;

    integer e_sum_unb0;
    always @* e_sum_unb0 = ea_unb + eb_unb + (prod_msb ? 1 : 0);

    // extract 24 + 23
    wire [23:0] mant24_pre = prod_norm[46:23];
    wire [22:0] rem23_pre  = prod_norm[22:0];

    // Normal path G/R/S
    wire g_n = rem23_pre[22];
    wire r_n = rem23_pre[21];
    wire s_n = |rem23_pre[20:0];

    function automatic bit inc_rnd;
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

    // pre-round exponent (for subnormals!)
    integer e_biased_pre;
    always @* e_biased_pre = e_sum_unb0 + BIAS;

    // normal rounding (used only when result stays normal)
    wire lsb_norm = mant24_pre[0];
    wire tie_norm = g_n & ~r_n & ~s_n;
    wire do_inc_n = inc_rnd(rm, res_s, lsb_norm, g_n, r_n, s_n, tie_norm);

    wire [24:0] mant25_n = {1'b0,mant24_pre} + {24'd0,do_inc_n};
    wire        carry_n  = mant25_n[24];
    wire [23:0] mant24_n = carry_n ? mant25_n[24:1] : mant25_n[23:0];

    integer e_biased_n;
    always @* e_biased_n = e_biased_pre + (carry_n ? 1 : 0);

    // ---- SUBNORMAL path (use pre-round exponent, no extra bump) ----
    // Build exact 47-bit: {24 kept, 23 rem}
    wire [46:0] sig47 = {mant24_pre, rem23_pre};

    integer k; // shift to e=0 domain: k = 1 - (pre-bias exponent)
    always @* k = 1 - e_biased_pre;

    reg [46:0] shifted47;
    reg        sticky_dn;
    reg [46:0] mask47;
    always @* begin
        if (k <= 0) begin
            shifted47 = sig47;
            sticky_dn = 1'b0;
        end else if (k >= 47) begin
            shifted47 = 47'd0;
            sticky_dn = |sig47;
        end else begin
            shifted47 = sig47 >> k;
            mask47    = (47'd1 << k) - 1;
            sticky_dn = |(sig47 & mask47);
        end
    end

    wire [22:0] frac_dn_pre = shifted47[46:24];
    wire        g_dn        = shifted47[23];
    wire        r_dn        = shifted47[22];
    wire        s_dn_any    = sticky_dn | |shifted47[21:0];

    wire        lsb_dn    = frac_dn_pre[0];
    wire        tie_dn    = g_dn & ~r_dn & ~s_dn_any;
    wire        do_inc_dn = inc_rnd(rm, res_s, lsb_dn, g_dn, r_dn, s_dn_any, tie_dn);

    wire [23:0] frac_dn_inc = {1'b0, frac_dn_pre} + {23'd0, do_inc_dn};
    wire        carry_dn    = frac_dn_inc[23];

    // subnormal rounded overflow -> minimum normal
    wire [7:0]  exp_dn_out  = carry_dn ? 8'd1 : 8'd0;
    wire [22:0] frac_dn_out = carry_dn ? 23'd0 : frac_dn_inc[22:0];

    // ---- Overflow handling per rm/sign ----
    function automatic [31:0] pack_overflow;
        input sgn;
        input [2:0] rm_f;
        reg [31:0] maxfin;
        begin
            maxfin = {sgn, 8'hFE, 23'h7FFFFF};  // largest finite of sign sgn
            case (rm_f)
                3'b001: pack_overflow = maxfin;                 // RTZ
                3'b010: pack_overflow = sgn ? {1'b1,8'hFF,23'd0} : maxfin; // RDN
                3'b011: pack_overflow = sgn ? maxfin : {1'b0,8'hFF,23'd0}; // RUP
                default: pack_overflow = {sgn,8'hFF,23'd0};     // RNE/RMM
            endcase
        end
    endfunction

    // Normal vs subnormal decision must use pre-round exponent
    wire normal_ok = (e_biased_pre > 0);

    reg [31:0] out_main;
    always @* begin
        if (take_special) begin
            out_main = special_out;
        end else if (e_biased_n >= 255) begin
            out_main = pack_overflow(res_s, rm);
        end else if (!normal_ok || (e_biased_n <= 0)) begin
            // subnormal / underflow
            out_main = {res_s, exp_dn_out, frac_dn_out};
        end else begin
            // normal
            out_main = {res_s, e_biased_n[7:0], mant24_n[22:0]};
        end
    end

    assign Out = out_main;
endmodule