// rtl/fpu_adder.v
// FP32 multiplier with same IO as your ADD block, so it is testbench-compatible.
// RISC-V rm[2:0]: 000 RNE, 001 RTZ, 010 RDN, 011 RUP, 100 RMM.
// Notes: full special-case handling for NaN/Inf/Zero; rounding for normalized results
// for all rm. Subnormal output path is simplified; overflow always -> Inf.
// FP32 multiplier with RISC-V rm[2:0]: 000 RNE, 001 RTZ, 010 RDN, 011 RUP, 100 RMM.
// Combinational; handles NaN/Inf/Zero; normalized rounding for all rm.
`timescale 1ns/1ps
`ifndef size_Fp_fmt
`define size_Fp_fmt 3
`endif

module FPU_ADDER_I #(
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size = 8
)(
    input  [`size_Fp_fmt-1:0] rm,
    input  [PARAM_Fp_size-1:0] A,
    input  [PARAM_Fp_size-1:0] B,
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
        if (a_is_nan || b_is_nan)                     special_out = QNAN;
        else if ((a_is_inf && b_is_zero) ||
                 (b_is_inf && a_is_zero))             special_out = QNAN;
        else if (a_is_inf || b_is_inf)                special_out = {res_s,8'hFF,23'd0};
        else if (a_is_zero || b_is_zero)              special_out = {res_s,8'h00,23'd0};
        else                                          take_special = 1'b0;
    end

    // significands (24b) and unbiased exponents
    wire [23:0] sig_a = (a_e==8'h00) ? {1'b0,a_m} : {1'b1,a_m};
    wire [23:0] sig_b = (b_e==8'h00) ? {1'b0,b_m} : {1'b1,b_m};
    integer ea_unb, eb_unb;
    always @* begin
        ea_unb = (a_e==8'h00) ? -126 : (integer'(a_e) - BIAS);
        eb_unb = (b_e==8'h00) ? -126 : (integer'(b_e) - BIAS);
    end

    // 24x24
    wire [47:0] prod_uu = sig_a * sig_b;

    // normalize
    wire        prod_msb  = prod_uu[47];
    wire [47:0] prod_norm = prod_msb ? (prod_uu >> 1) : prod_uu;
    integer     e_sum_unb0;
    always @* e_sum_unb0 = ea_unb + eb_unb + (prod_msb ? 1 : 0);

    // keep 24, G/R/S
    wire [23:0] mant24_pre = prod_norm[46:23];
    wire        bit_guard  = prod_norm[22];
    wire        bit_round  = prod_norm[21];
    wire        bit_sticky = |prod_norm[20:0];

    // rounding
    wire lsb_kept = mant24_pre[0];
    wire any_rem  = bit_guard | bit_round | bit_sticky;
    wire tie_half = bit_guard & ~bit_round & ~bit_sticky;

    reg inc;
    always @* begin
        case (rm)
            3'b000: inc = (bit_guard & (bit_round | bit_sticky)) | (tie_half & lsb_kept); // RNE
            3'b001: inc = 1'b0;                                                           // RTZ
            3'b010: inc =  res_s & any_rem;                                               // RDN
            3'b011: inc = ~res_s & any_rem;                                               // RUP
            3'b100: inc =  bit_guard;                                                     // RMM
            default:inc = (bit_guard & (bit_round | bit_sticky)) | (tie_half & lsb_kept);
        endcase
    end

    wire [24:0] mant25_round = {1'b0,mant24_pre} + {24'd0,inc};
    wire        carry_up     = mant25_round[24];
    wire [23:0] mant24_rnd   = carry_up ? mant25_round[24:1] : mant25_round[23:0];

    integer e_sum_unb1;
    always @* e_sum_unb1 = e_sum_unb0 + (carry_up ? 1 : 0);

    // pack
    reg  [31:0] out_main;
    reg  [7:0]  out_exp;
    reg  [22:0] out_frac;
    always @* begin
        if (take_special) begin
            out_main = special_out;
        end else begin
            integer e_biased;
            e_biased = e_sum_unb1 + BIAS;

            // overflow -> Inf
            if (e_biased >= 255) begin
                out_main = {res_s, 8'hFF, 23'd0};
            end
            // underflow/subnormal (simplified)
            else if (e_biased <= 0) begin
                integer sh;
                reg [47:0] sticky_src;
                reg [47:0] shifted;
                reg [47:0] mask;
                reg        sticky_dn;

                // build sticky source: kept 24 bits + 23 remainder
                sticky_src = {mant24_rnd, prod_norm[22:0]};

                sh = 1 - e_biased;           // >= 1 here
                if (sh >= 48) begin
                    shifted   = 48'd0;
                    sticky_dn = |sticky_src;
                end else begin
                    shifted   = sticky_src >> sh;
                    // mask of lower sh bits without variable part-select
                    if (sh == 0) mask = 48'd0;
                    else         mask = (48'd1 << sh) - 1;
                    sticky_dn = |(sticky_src & mask);
                end

                out_exp  = 8'h00;
                out_frac = shifted[46:24];   // 23 bits

                // minimal directed bump for RTZ/RDN/RUP on subnormals
                if (sticky_dn) begin
                    if (rm==3'b011 && ~res_s) begin
                        if (out_frac != 23'h7FFFFF) out_frac = out_frac + 1'b1; // RUP
                    end else if (rm==3'b010 &&  res_s) begin
                        if (out_frac != 23'h7FFFFF) out_frac = out_frac + 1'b1; // RDN
                    end
                end
                out_main = {res_s, out_exp, out_frac};
            end
            // normal
            else begin
                out_exp  = e_biased[7:0];
                out_frac = mant24_rnd[22:0];
                out_main = {res_s, out_exp, out_frac};
            end
        end
    end

    assign Out = out_main;
endmodule
