// Verilog-2005
// FP32 pipelined adder: unpack → align → add/sub → normalize → round/pack
// RISC-V rounding: rm(2:0); rm=111 => use frm CSR.
// Special cases handled: NaN propagation, Inf +/- Inf, Inf +/- finite, zeros,
// subnormals, overflow to Inf. Underflow: denormalizes with sticky then rounds.
module fp32_add_pipe (
    input  wire        clk,
    input  wire        rst,          // sync reset, active high
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  rm,           // per-instruction rm
    input  wire [2:0]  frm,          // CSR frm if rm==3'b111
    output wire [31:0] result
);

    // ===== Helpers =====
    // pack 24-bit mantissa (with hidden bit in [23]) into 27-bit with GRS=0
    function [26:0] pack_ext;
        input [23:0] mant24;
        begin
            pack_ext = {mant24, 3'b000};
        end
    endfunction

    // Right shift with sticky for 27-bit value by up to 31
    function [26:0] shr_sticky27;
        input [26:0] x;
        input [5:0]  sh; // use [5:0] to guard >27
        reg   [26:0] y;
        reg          stk;
        integer      k;
        begin
            if (sh == 0) begin
                shr_sticky27 = x;
            end else if (sh <= 27) begin
                y   = x >> sh;
                stk = 1'b0;
                for (k = 0; k < sh; k = k + 1)
                    stk = stk | x[k];
                y[0] = y[0] | stk; // fold into sticky bit
                shr_sticky27 = y;
            end else begin
                // all bits shift out; sticky = any(x)
                stk = 1'b0;
                for (k = 0; k < 27; k = k + 1)
                    stk = stk | x[k];
                shr_sticky27 = {27{1'b0}};
                shr_sticky27[0] = stk;
            end
        end
    endfunction

    // Leading zero count for 24-bit (bits [23:0]); returns 0..24
    function [4:0] lzc24;
        input [23:0] v;
        integer i;
        begin
            lzc24 = 24;
            for (i = 23; i >= 0; i = i - 1)
                if (v[i]) lzc24 = 23 - i;
        end
    endfunction

    // ===== Stage 1: Unpack + specials =====
    reg        s1_sa, s1_sb;
    reg [7:0]  s1_ea, s1_eb;
    reg [22:0] s1_fa, s1_fb;
    reg [23:0] s1_ma, s1_mb;  // mant with hidden
    reg [7:0]  s1_ea_eff, s1_eb_eff; // exp for align (subnormals -> 1)
    reg [2:0]  s1_rm, s1_frm;

    // Special-case resolution at S1
    reg        s1_has_spec;
    reg [31:0] s1_spec;

    wire a_is_nan = (a[30:23]==8'hFF) && (a[22:0]!=23'b0);
    wire b_is_nan = (b[30:23]==8'hFF) && (b[22:0]!=23'b0);
    wire a_is_inf = (a[30:23]==8'hFF) && (a[22:0]==23'b0);
    wire b_is_inf = (b[30:23]==8'hFF) && (b[22:0]==23'b0);

    localparam [31:0] QNAN = 32'h7FC0_0000;

    always @(posedge clk) begin
        if (rst) begin
            s1_sa <= 0; s1_sb <= 0;
            s1_ea <= 0; s1_eb <= 0;
            s1_fa <= 0; s1_fb <= 0;
            s1_ma <= 0; s1_mb <= 0;
            s1_ea_eff <= 0; s1_eb_eff <= 0;
            s1_rm <= 3'b000; s1_frm <= 3'b000;
            s1_has_spec <= 1'b0; s1_spec <= 32'h0;
        end else begin
            s1_sa <= a[31];  s1_sb <= b[31];
            s1_ea <= a[30:23]; s1_eb <= b[30:23];
            s1_fa <= a[22:0];  s1_fb <= b[22:0];

            // mantissas with hidden bits (0 for subnormals)
            s1_ma <= (a[30:23]==8'd0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
            s1_mb <= (b[30:23]==8'd0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
            // effective exponents for alignment
            s1_ea_eff <= (a[30:23]==8'd0) ? 8'd1 : a[30:23];
            s1_eb_eff <= (b[30:23]==8'd0) ? 8'd1 : b[30:23];

            s1_rm  <= rm;
            s1_frm <= frm;

            // specials
            if (a_is_nan || b_is_nan) begin
                s1_has_spec <= 1'b1; s1_spec <= QNAN;
            end else if (a_is_inf && b_is_inf) begin
                if (a[31] ^ b[31]) begin
                    s1_has_spec <= 1'b1; s1_spec <= QNAN; // +Inf + -Inf = NaN
                end else begin
                    s1_has_spec <= 1'b1; s1_spec <= {a[31], 8'hFF, 23'h0};
                end
            end else if (a_is_inf) begin
                s1_has_spec <= 1'b1; s1_spec <= {a[31], 8'hFF, 23'h0};
            end else if (b_is_inf) begin
                s1_has_spec <= 1'b1; s1_spec <= {b[31], 8'hFF, 23'h0};
            end else begin
                s1_has_spec <= 1'b0; s1_spec <= 32'h0;
            end
        end
    end

    // ===== Stage 2: Align, choose magnitude =====
    reg        s2_sign_large, s2_sign_small;
    reg [23:0] s2_mant_large, s2_mant_small;
    reg [7:0]  s2_exp_large,  s2_exp_small;
    reg [26:0] s2_large_ext,  s2_small_ext;
    reg [7:0]  s2_exp_base;
    reg        s2_op_add;
    reg [2:0]  s2_rm, s2_frm;
    reg        s2_has_spec; reg [31:0] s2_spec;

    always @(posedge clk) begin
        if (rst) begin
            s2_sign_large <= 0; s2_sign_small <= 0;
            s2_mant_large <= 0; s2_mant_small <= 0;
            s2_exp_large  <= 0; s2_exp_small  <= 0;
            s2_large_ext  <= 0; s2_small_ext  <= 0;
            s2_exp_base   <= 0; s2_op_add    <= 0;
            s2_rm <= 0; s2_frm <= 0;
            s2_has_spec <= 1'b0; s2_spec <= 32'h0;
        end else begin
            s2_has_spec <= s1_has_spec;
            s2_spec     <= s1_spec;

            // choose larger by (exp_eff, mant)
            if (s1_ea_eff > s1_eb_eff) begin
                s2_sign_large <= s1_sa; s2_sign_small <= s1_sb;
                s2_mant_large <= s1_ma; s2_mant_small <= s1_mb;
                s2_exp_large  <= s1_ea_eff; s2_exp_small <= s1_eb_eff;
            end else if (s1_ea_eff < s1_eb_eff) begin
                s2_sign_large <= s1_sb; s2_sign_small <= s1_sa;
                s2_mant_large <= s1_mb; s2_mant_small <= s1_ma;
                s2_exp_large  <= s1_eb_eff; s2_exp_small <= s1_ea_eff;
            end else begin
                // exponents equal: tie-breaker on mantissa
                if (s1_ma >= s1_mb) begin
                    s2_sign_large <= s1_sa; s2_sign_small <= s1_sb;
                    s2_mant_large <= s1_ma; s2_mant_small <= s1_mb;
                    s2_exp_large  <= s1_ea_eff; s2_exp_small <= s1_eb_eff;
                end else begin
                    s2_sign_large <= s1_sb; s2_sign_small <= s1_sa;
                    s2_mant_large <= s1_mb; s2_mant_small <= s1_ma;
                    s2_exp_large  <= s1_eb_eff; s2_exp_small <= s1_ea_eff;
                end
            end

            s2_op_add   <= (s1_sa == s1_sb);
            s2_exp_base <= (s1_ea_eff > s1_eb_eff) ? s1_ea_eff :
                           (s1_ea_eff < s1_eb_eff) ? s1_eb_eff : s1_ea_eff;

            // build 27-bit with GRS and align small with sticky
            begin : align_blk
                reg [5:0] delta;
                delta = s2_exp_large - s2_exp_small;
                s2_large_ext <= pack_ext(s2_mant_large);
                s2_small_ext <= shr_sticky27(pack_ext(s2_mant_small), delta);
            end

            s2_rm  <= s1_rm;
            s2_frm <= s1_frm;
        end
    end

    // ===== Stage 3: Add/Sub =====
    reg        s3_sign;
    reg [7:0]  s3_exp_base;
    reg [27:0] s3_sumext; // 28-bit to hold carry on add
    reg        s3_is_add;
    reg [2:0]  s3_rm, s3_frm;
    reg        s3_has_spec; reg [31:0] s3_spec;

    always @(posedge clk) begin
        if (rst) begin
            s3_sign <= 0; s3_exp_base <= 0; s3_sumext <= 0; s3_is_add <= 0;
            s3_rm <= 0; s3_frm <= 0; s3_has_spec <= 1'b0; s3_spec <= 32'h0;
        end else begin
            s3_has_spec <= s2_has_spec; s3_spec <= s2_spec;

            s3_is_add   <= s2_op_add;
            s3_sign     <= s2_sign_large;  // sign of larger magnitude
            s3_exp_base <= s2_exp_base;

            if (s2_op_add) begin
                s3_sumext <= {1'b0, s2_large_ext} + {1'b0, s2_small_ext};
            end else begin
                // large - small (both 27b)
                s3_sumext <= {1'b0, s2_large_ext} - {1'b0, s2_small_ext};
            end

            s3_rm  <= s2_rm;
            s3_frm <= s2_frm;
        end
    end

    // ===== Stage 4: Normalize (right for add carry, left for sub) + handle under/overflow prep =====
    reg        s4_sign;
    reg [7:0]  s4_exp;
    reg [26:0] s4_mext;   // normalized mantissa with GRS (27b)
    reg [2:0]  s4_rm, s4_frm;
    reg        s4_has_spec; reg [31:0] s4_spec;
    reg        s4_overflow; // to Inf

    always @(posedge clk) begin
        if (rst) begin
            s4_sign <= 0; s4_exp <= 0; s4_mext <= 0; s4_rm <= 0; s4_frm <= 0;
            s4_has_spec <= 1'b0; s4_spec <= 32'h0; s4_overflow <= 1'b0;
        end else begin
            s4_has_spec <= s3_has_spec; s4_spec <= s3_spec;
            s4_rm <= s3_rm; s4_frm <= s3_frm;

            s4_overflow <= 1'b0;
            s4_sign     <= s3_sign;

            if (s3_is_add) begin
                // Add: possible carry at bit 27
                if (s3_sumext[27]) begin
                    s4_exp  <= s3_exp_base + 8'd1;
                    s4_mext <= s3_sumext[27:1]; // shift right by 1; GRS preserved
                end else begin
                    s4_exp  <= s3_exp_base;
                    s4_mext <= s3_sumext[26:0];
                end
            end else begin
                // Sub: may need left-normalization
                if (s3_sumext[26:0] == 27'b0) begin
                    // exact zero
                    s4_exp  <= 8'd0;
                    s4_mext <= 27'b0;
                    s4_sign <= 1'b0; // +0
                end else begin
                    // count leading zeros in the 24 MSBs (exclude GRS)
                    // target to place leading 1 at bit 26 of mext
                    // m[26:3] is 24-bit field
                    reg [23:0] m24;
                    reg [4:0]  shl;
                    reg [26:0] tmp;
                    m24 = s3_sumext[26:3];
                    shl = lzc24(m24);           // 0..24
                    tmp = s3_sumext[26:0] << shl;
                    // new exponent
                    if (s3_exp_base > shl[7:0]) begin
                        s4_exp  <= s3_exp_base - shl[7:0];
                        s4_mext <= tmp;
                    end else begin
                        // becomes subnormal: right shift to exp==0 preserving sticky
                        // shift right amount d = 1 - (s3_exp_base - shl) = shl + 1 - s3_exp_base
                        reg [5:0] d;
                        reg [26:0] den;
                        d   = (shl + 6'd1) - {2'b00, s3_exp_base}; // safe width
                        den = shr_sticky27(tmp, d);
                        s4_exp  <= 8'd0;
                        s4_mext <= den;
                    end
                end
            end

            // overflow to Inf if exponent exceeds max after add-right-normalize
            if (s4_exp >= 8'hFF) begin
                s4_overflow <= 1'b1;
                s4_exp  <= 8'hFF;
                s4_mext <= 27'b0;
            end
        end
    end

    // ===== Stage 5: Round + Pack (all RM) =====
    reg [31:0] s5_res_r;
    assign result = s5_res_r;

    always @(posedge clk) begin
        if (rst) begin
            s5_res_r <= 32'h0;
        end else if (s4_has_spec) begin
            s5_res_r <= s4_spec;
        end else if (s4_overflow) begin
            s5_res_r <= {s4_sign, 8'hFF, 23'h0}; // ±Inf
        end else begin
            // Effective rounding mode
            reg [2:0] eff_rm;
            reg [23:0] mant24;
            reg [22:0] frac23;
            reg [7:0]  exp_r;
            reg        G, Rb, S;
            reg        inc;
            reg [24:0] mant25; // for rounding increment and carry
            reg        carry_up;

            eff_rm = (s4_rm == 3'b111) ? s4_frm : s4_rm;

            // Extract normalized mantissa+GRS
            mant24 = s4_mext[26:3]; // includes hidden bit at [23] if normal
            G      = s4_mext[2];
            Rb     = s4_mext[1];
            S      = s4_mext[0];

            exp_r  = s4_exp;

            // Decide increment
            // LSB for tie-breaking is mant24[0] (LSB of stored 23-bit fraction region)
            inc = 1'b0;
            case (eff_rm)
                3'b000: inc = (G && (Rb | S | mant24[0]));                 // RNE
                3'b001: inc = 1'b0;                                        // RTZ
                3'b010: inc = (s4_sign && (G | Rb | S));                   // RDN
                3'b011: inc = (!s4_sign && (G | Rb | S));                  // RUP
                3'b100: inc = G;                                           // RMM
                default: inc = (G && (Rb | S | mant24[0]));                // treat as RNE
            endcase

            mant25   = {1'b0, mant24} + {24'b0, inc};
            carry_up = mant25[24];

            if (carry_up) begin
                // renormalize due to rounding carry
                // shift right by 1 -> mant24 = 1.000...0
                mant24 = 24'h800000;
                exp_r  = exp_r + 8'd1;
            end else begin
                mant24 = mant25[23:0];
            end

            // If exponent overflowed due to rounding
            if (exp_r >= 8'hFF) begin
                s5_res_r <= {s4_sign, 8'hFF, 23'h0}; // ±Inf
            end else begin
                // If exp==0 but mant24[23]==1 after rounding, promote to min normal
                if (exp_r == 8'd0 && mant24[23]) begin
                    exp_r  = 8'd1;
                end
                // Pack: for exp!=0, hidden bit is dropped; for exp==0, hidden is 0 (mant24[23] should be 0)
                frac23   = mant24[22:0];
                s5_res_r <= {s4_sign, exp_r, frac23};
            end
        end
    end

endmodule
