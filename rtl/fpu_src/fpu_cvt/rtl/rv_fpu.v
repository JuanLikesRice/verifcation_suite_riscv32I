`include "params.vh"

// `timescale 1ns/1ps



module rv_FPU #(    
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size =  8
    )  (
    input                                         clk, 
    input                                         rst,
    input        [6:0]                 fp_instruction,
    input                                 req_valid_i,
    output                                req_taken_o,
    input      [2:0]                         rm      ,    
    input      [2:0]                         csr_rm  ,    
    input      [PARAM_Fp_size-1:0]           rs1_data,
    input      [PARAM_Fp_size-1:0]           rs2_data, 
    input      [PARAM_Fp_size-1:0]           rs3_data,
                                                     
    input      [5:0]                          rs1_idx,
    input      [5:0]                          rs2_idx, 
    input      [5:0]                          rs3_idx,

    output  [PARAM_Fp_size-1:0]             result_s1,
    output  [4:0]                           exception, 
    output                               valid_out_ov
);


wire [PARAM_Fp_size-1:0]  A_rs1_w, B_rs2_w, C_rs2_w;
wire [PARAM_Fp_size-1:0]  result_s1_w, result_s2;
wire [3:0]                exception_w;
wire                      valid_out_ov_w;

wire                      ADD_req_in_w;
wire [2:0]                ADD_rm_w;
wire [PARAM_Fp_size-1:0]  ADD_Out_w;
wire                      ADD_valid_out_w;
wire [4:0]                ADD_exception_w;


wire                      MULT_req_in_w;
wire [2:0]                MULT_rm_w;
wire [PARAM_Fp_size-1:0]  MULT_Out_w;
wire                      MULT_valid_out_w;
wire [4:0]                MULT_exception_w;

// Instantiate controller
rv_FPU_ctrl #(
    .PARAM_Fp_size      (PARAM_Fp_size),
    .PARAM_Mantissa_size(PARAM_Mantissa_size),
    .PARAM_Exponent_size(PARAM_Exponent_size)
) u_rv_FPU_ctrl (
    .clk            (clk),
    .rst            (rst),
    .fp_instruction (fp_instruction),
    .req_valid_i    (req_valid_i),
    .req_taken_o    (req_taken_o),
    .rm             (rm),
    .csr_rm         (csr_rm),
    .rs1_data       (rs1_data),
    .rs2_data       (rs2_data),
    .rs3_data       (rs3_data),
    .result_s1      (result_s1),
    .result_s2      (result_s2),
    .exception      (exception),
    .valid_out_ov   (valid_out_ov),

    .A_rs1          (A_rs1_w),
    .B_rs2          (B_rs2_w),
    .C_rs2          (C_rs2_w),

    .ADD_req_in     (ADD_req_in_w),
    .ADD_rm         (ADD_rm_w),
    .ADD_Out        (ADD_Out_w),
    .ADD_valid_out  (ADD_valid_out_w),
    .ADD_exception  (ADD_exception_w),

    .MULT_req_in    (MULT_req_in_w),
    .MULT_rm        (MULT_rm_w),
    .MULT_Out       (MULT_Out_w),
    .MULT_valid_out (MULT_valid_out_w),
    .MULT_exception (MULT_exception_w)
);



FPU_ADDER_I  #(    
.PARAM_Fp_size      (PARAM_Fp_size      ),
.PARAM_Mantissa_size(PARAM_Mantissa_size),
.PARAM_Exponent_size(PARAM_Exponent_size)
    ) FPU_ADDER_FP32  (
.clk      (clk             )       ,
.rst      (rst             )       ,
.req_in   (ADD_req_in_w    )       ,    
.rm       (ADD_rm_w        )       ,    
.A        (A_rs1_w         )       ,
.B        (B_rs2_w         )       ,
.Out      (ADD_Out_w       )       ,
.valid_out(ADD_valid_out_w )       ,      
.exception(ADD_exception_w )       
);

 FPU_MULT_I #(
.PARAM_Fp_size      (PARAM_Fp_size      ),
.PARAM_Mantissa_size(PARAM_Mantissa_size),
.PARAM_Exponent_size(PARAM_Exponent_size)
) FPU_MULT_FP32 (

    .clk      (clk               ) ,
    .rst      (rst               ) ,
    .req_in   (MULT_req_in_w     ) ,    
    .rm       (MULT_rm_w         ) ,    
    .A        (A_rs1_w           ) ,
    .B        (B_rs2_w           ) ,
    .Out      (MULT_Out_w        ) ,
    .valid_out(MULT_valid_out_w  ) ,      
    .exception(MULT_exception_w  ) 

);

endmodule



module rv_FPU_ctrl #(    
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size =  8
    )  (
    input                                          clk, 
    input                                          rst,
    input                     [6:0]     fp_instruction,
    input                                  req_valid_i,
    output                                 req_taken_o,
    input                     [2:0]                 rm,    
    input                     [2:0]             csr_rm,
        
    input      [PARAM_Fp_size-1:0]            rs1_data,
    input      [PARAM_Fp_size-1:0]            rs2_data, 
    input      [PARAM_Fp_size-1:0]            rs3_data,

    output  [PARAM_Fp_size-1:0]             result_s1,
    output  [PARAM_Fp_size-1:0]             result_s2,

    output [4:0]                            exception, 
    output                               valid_out_ov,

// SHARED_FPU VAL
    // output                  [`size_Fp_fmt-1:0]   rm ,    
    output                [PARAM_Fp_size-1:0]  A_rs1  ,
    output                [PARAM_Fp_size-1:0]  B_rs2  , 
    output                [PARAM_Fp_size-1:0]  C_rs2  , 
// ADD
    output                                 ADD_req_in,
    output             [2:0]               ADD_rm,
    input              [PARAM_Fp_size-1:0] ADD_Out,
    input                                  ADD_valid_out,
    input               [4:0]              ADD_exception, 

 // ADD
    output                                 MULT_req_in,
    output             [2:0]               MULT_rm,
    input              [PARAM_Fp_size-1:0] MULT_Out,
    input                                  MULT_valid_out,
    input               [4:0]              MULT_exception 
);

localparam S_IDLE    = 2'b01;
localparam S_PROCESS = 2'b10;
reg [1:0] current_state, next_state;
wire req_done;
reg req_taken;
assign req_taken_o = req_taken;


assign result_s1 = ({PARAM_Fp_size{ ADD_valid_out}}&( ADD_Out) ) |
                   ({PARAM_Fp_size{MULT_valid_out}}&(MULT_Out) ) ;

                //    ({PARAM_Fp_size{MULT_valid_out}}&(SUB_Out)| 
                //    ) ;

assign A_rs1 = rs1_data;
assign B_rs2 = rs2_data;
assign C_rs2 = rs3_data;

// always @(*) begin 
//     case(fp_instruction)
//     FPU_OP_ADD:begin 
//     end  
//     endcase
// end

assign valid_out_ov = req_done;
assign   req_done   = MULT_valid_out|ADD_valid_out;
assign  ADD_req_in  = ((fp_instruction==`FPU_OP_ADD ) && req_taken);
assign  MULT_req_in = ((fp_instruction==`FPU_OP_MULT) && req_taken);

always @(*) begin 
    case(current_state)
        S_IDLE: begin 
            if (req_valid_i) begin 
                req_taken  =  1'b1;
                next_state = S_PROCESS;
            end else begin 
                req_taken  =  1'b0;
                next_state = S_PROCESS;        
            end
        end

        S_PROCESS: begin 
            if (req_done) begin 
                if (req_valid_i) begin 
                    req_taken  =  1'b1;
                    next_state = S_PROCESS;
                end else begin 
                    req_taken  =  1'b0;
                    next_state = S_IDLE;        
                end         
            end else begin 
                req_taken  =  1'b0;
                next_state = S_PROCESS;        
            end
        end
    endcase
end 

always @(posedge clk) begin
    if (rst) begin 
        current_state <= S_IDLE;
    end else begin 
        current_state <= next_state;
    end 
end

endmodule




module FPU_ADDER_I #(    
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size =  8
    )  (
    input                      clk, 
    input                      rst,
    input                      req_in ,
    input  [`size_Fp_fmt-1:0]  rm ,    
    input  [PARAM_Fp_size-1:0] A  ,
    input  [PARAM_Fp_size-1:0] B  , 
    output [PARAM_Fp_size-1:0] Out,
    output                     valid_out,
    output [4:0]               exception 
);

    wire signal_inexact;
    wire a_is_zero = (E_A==8'h00) && (M_A==23'd0);
    wire b_is_zero = (E_B==8'h00) && (M_B==23'd0);
    wire a_is_inf  = (E_A==8'hFF) && (M_A==23'd0);
    wire b_is_inf  = (E_B==8'hFF) && (M_B==23'd0);
    wire a_is_nan  = (E_A==8'hFF) && (M_A!=23'd0);
    wire b_is_nan  = (E_B==8'hFF) && (M_B!=23'd0);
    localparam [31:0] QNAN = 32'h7FC0_0000;
    wire complete_overdlow;
    wire            SAeqSB;
    assign SAeqSB = (S_A == S_B);
    reg  [31:0] special_out,   special_out_r0,special_out_r1,special_out_r2   ,special_out_r3;
    wire [31:0] special_out_f;
    reg   [4:0] special_FLAG, special_FLAG_r0,special_FLAG_r1,special_FLAG_r2,special_FLAG_r3;
    wire  [4:0] special_FLAG_f;
    reg         take_special, take_special_r0, take_special_r1, take_special_r2, take_special_r3;
    wire        take_special_f;

    always @* begin
        take_special = 1'b1;
        special_out  = 32'h0000_0000;
        special_FLAG = 5'b111;        
        if (a_is_nan || b_is_nan) begin 
          special_out  = QNAN;
          special_FLAG = 5'b100; //NV Invalid Operation
        end else if ((a_is_inf && ~b_is_inf) || (~a_is_inf &&  b_is_inf) ) begin 
          special_out  =  {final_sign,8'hFF,23'd0};
          special_FLAG =  5'b010; // OF Overflow
        end else if (a_is_inf && b_is_inf) begin 
          special_out  = SAeqSB ?  {final_sign,8'hFF,23'd0} :   QNAN;
          special_FLAG = SAeqSB ?  5'b010                   : 5'b100;  // OF Overflow
        end else if (a_is_zero || b_is_zero) begin 
          special_out =           {final_sign,8'h00,23'd0};
          special_FLAG = 5'b111;
        end else begin 
          // if (signal_inexact) begin 
          // special_FLAG = 3'b000;
          // end else begin 
          // special_FLAG = 3'b111;  
          // end
          special_FLAG = 5'b111;  
          take_special = 1'b0;
        end
    end

reg [PARAM_Fp_size-1:0]  Out_r;
wire [PARAM_Fp_size-1:0] Out_w;
reg valid_out_r;
assign valid_out = valid_out_r;
assign Out = Out_r;

always @(posedge clk) begin 
  if (rst) begin 
    Out_r       <= 0;
    valid_out_r <= 0;
  end else begin  
    if (valid_r3) begin 
      valid_out_r <= valid_r3;
      Out_r       <= Out_w;
    end else begin 
    valid_out_r <= 1'b0;
    end 
  end
end 



localparam PARAM_Mantissa_PI_size = PARAM_Mantissa_size   +1;
parameter offset_bits = 7;
wire [PARAM_Mantissa_size-1   :0] M_B,M_A; 
wire [PARAM_Mantissa_PI_size-1:0] M_B_total,M_A_total; 
wire [PARAM_Exponent_size-1   :0] E_B,E_A, E_num_1_big, E_num_0_small;
wire S_B,S_A, is_subnormal_B,is_subnormal_A;
wire [PARAM_Exponent_size-1   :0]    E_A_eff, E_B_eff;
wire [PARAM_Mantissa_PI_size+offset_bits:0]    M_sum,M_sub;
wire [PARAM_Mantissa_PI_size+offset_bits:0]    M_result_non_normal;
wire [PARAM_Mantissa_PI_size-1:0]    M_num_0_small,M_num_1_big,M_shifted_small;  
reg [2*PARAM_Mantissa_PI_size-1:0]   M_shifted_small_pre_selection;  //47:0
wire[PARAM_Mantissa_PI_size-1 :0]    M_shifted_small_roudning; 
wire final_sign;
wire [PARAM_Fp_size-1:0] final_result;
wire [ PARAM_Mantissa_size:0]  M_final_mantisa; // 24
wire [PARAM_Mantissa_size-1:0] saved_mantissa,leading_zero;
wire [PARAM_Exponent_size :0] final_exponent;
wire M_all_zeros, result_zero;
wire  [PARAM_Mantissa_PI_size+offset_bits:0] M_result_non_normal_MP1_size_shift;
wire carry_out;
wire a_GTEQ_b;
wire [PARAM_Mantissa_PI_size+offset_bits:0]  A_in,B_in;

wire [PARAM_Mantissa_size     :0]    E_diff_big_small;
wire E_diff_big_small_too_big;


// initial assignments
assign M_A[PARAM_Mantissa_size-1:0]=A[PARAM_Mantissa_size-1:0];
assign M_B[PARAM_Mantissa_size-1:0]=B[PARAM_Mantissa_size-1:0];
assign E_A[PARAM_Exponent_size-1:0]=A[PARAM_Exponent_size-1+PARAM_Mantissa_PI_size:PARAM_Mantissa_size];
assign E_B[PARAM_Exponent_size-1:0]=B[PARAM_Exponent_size-1+PARAM_Mantissa_PI_size:PARAM_Mantissa_size];
assign S_A                         =A[PARAM_Fp_size-1];
assign S_B                         =B[PARAM_Fp_size-1];

//detect subnormal
assign is_subnormal_A = (E_A == {PARAM_Exponent_size{1'b0}});
assign is_subnormal_B = (E_B == {PARAM_Exponent_size{1'b0}});

assign E_A_eff   = is_subnormal_A ? 8'd1 : E_A;
assign E_B_eff   = is_subnormal_B ? 8'd1 : E_B;
assign M_A_total = {~is_subnormal_A,M_A};
assign M_B_total = {~is_subnormal_B,M_B};

assign a_GTEQ_b =       ({E_A,M_A} >= {E_B,M_B} );
assign M_num_1_big      = a_GTEQ_b ?  M_A_total : M_B_total; 
assign M_num_0_small    = a_GTEQ_b ?  M_B_total : M_A_total; 
assign E_num_1_big      = a_GTEQ_b ?  E_A_eff   : E_B_eff  ; 
assign E_num_0_small    = a_GTEQ_b ?  E_B_eff   : E_A_eff  ;

assign final_sign =   a_GTEQ_b ? S_A : S_B;
// ALLIGNMENT
assign E_diff_big_small         =  E_num_1_big - E_num_0_small;
assign E_diff_big_small_too_big =  E_diff_big_small > PARAM_Mantissa_PI_size+offset_bits+1;
reg valid_r0, valid_r1, valid_r2, valid_r3;
reg [PARAM_Mantissa_size     :0] E_diff_big_small_r0;
reg E_diff_big_small_too_big_r0,M_all_zeros_r3;
reg [PARAM_Mantissa_size-1:0] leading_zero_r3;
reg final_sign_r0,final_sign_r1,final_sign_r2,final_sign_r3;
reg [PARAM_Exponent_size-1   :0]  E_num_1_big_r0,E_num_1_big_r1,E_num_1_big_r2,E_num_1_big_r3;
 reg [PARAM_Mantissa_PI_size+offset_bits:0]  A_in_r1,B_in_r1;
reg [PARAM_Mantissa_PI_size-1:0]    M_num_1_big_r0;  
reg [PARAM_Mantissa_PI_size-1:0]    M_num_0_small_r0;
reg SAeqSB_r0,SAeqSB_r1;
reg [2:0]rm_r0,rm_r1,rm_r2,rm_r3;
wire [PARAM_Mantissa_PI_size+offset_bits:0]  B_in_f;
reg [PARAM_Mantissa_PI_size+offset_bits:0]    M_result_non_normal_r2;

//blk 0
always @(posedge clk) begin 
  if (rst) begin 
    valid_r0                    <= 0;
    special_out_r0              <= 0;
    special_FLAG_r0             <= 0;
    take_special_r0             <= 0;
    E_diff_big_small_r0         <= 0;
    E_diff_big_small_too_big_r0 <= 0;
    M_num_0_small_r0            <= 0;
    SAeqSB_r0                   <= 0;
    rm_r0                       <= 0;
    final_sign_r0               <= 0;
    E_num_1_big_r0              <= 0;
    M_num_1_big_r0              <= 0;

  end else begin  
    if (req_in) begin 
      final_sign_r0               <= final_sign;
      rm_r0                       <= rm;
      special_out_r0              <=  special_out;
      SAeqSB_r0                   <=  SAeqSB;
      special_FLAG_r0             <= special_FLAG;
      take_special_r0             <= take_special;
      valid_r0                    <= req_in;

      if (take_special) begin 
      E_diff_big_small_r0         <= 0;
      E_diff_big_small_too_big_r0 <= 0;
      M_num_0_small_r0            <= 0;
      E_num_1_big_r0              <= 0;
      M_num_1_big_r0              <= 0;
      end else begin 
      E_diff_big_small_r0         <= E_diff_big_small;
      E_diff_big_small_too_big_r0 <= E_diff_big_small_too_big;
      M_num_0_small_r0            <= M_num_0_small;
      E_num_1_big_r0              <= E_num_1_big;
      M_num_1_big_r0              <= M_num_1_big;
      end
    end else begin 
    valid_r0   <= 1'b0;
        special_out_r0              <= 0;
    end 
  end
end 

always @(*) begin 
    if (E_diff_big_small_too_big_r0) begin 
        M_shifted_small_pre_selection = {{PARAM_Mantissa_PI_size{1'b0}},{PARAM_Mantissa_size{1'b0}},|M_num_0_small_r0};
    end else begin 
        M_shifted_small_pre_selection =  {M_num_0_small_r0,{PARAM_Mantissa_PI_size{1'b0}}} >> E_diff_big_small_r0;
    end
  end


assign M_shifted_small          =  M_shifted_small_pre_selection[2*PARAM_Mantissa_PI_size-1:PARAM_Mantissa_PI_size];// 47:24|23:0
assign M_shifted_small_roudning =  M_shifted_small_pre_selection[PARAM_Mantissa_PI_size-1  :                      0];// 23:0
assign A_in = {1'b0,M_num_1_big_r0,{offset_bits{1'b0}}};
assign B_in = {1'b0,M_shifted_small,M_shifted_small_roudning[PARAM_Mantissa_PI_size-1:PARAM_Mantissa_PI_size-offset_bits+1],|M_shifted_small_roudning[PARAM_Mantissa_PI_size-offset_bits:0]};


// BLK1
always @(posedge clk) begin 
  if (rst) begin 
    valid_r1                     <= 0;
    special_out_r1               <= 0;
    special_FLAG_r1              <= 0;
    take_special_r1              <= 0;
    SAeqSB_r1                    <= 0;
    rm_r1                        <= 0;
    final_sign_r1                <= 0;
    E_num_1_big_r1               <= 0;
    A_in_r1                      <= 0;
    B_in_r1                      <= 0;

  end else begin  
    if (valid_r0) begin 
      rm_r1                       <= rm_r0;
      final_sign_r1               <=final_sign_r0               ;
      E_num_1_big_r1              <= E_num_1_big_r0;
      valid_r1                    <= valid_r0                   ;
      A_in_r1                     <= A_in                       ;
      B_in_r1                     <= B_in                       ;
      special_out_r1              <= special_out_r0             ;
      special_FLAG_r1             <= special_FLAG_r0            ;
      take_special_r1             <= take_special_r0            ;
      SAeqSB_r1                   <= SAeqSB_r0                  ;
    end else begin 
    valid_r1   <= 1'b0;

    end 
  end
end 

wire sub_on;
assign sub_on = ~SAeqSB_r1;

assign B_in_f = sub_on ? ~B_in_r1[PARAM_Mantissa_PI_size+offset_bits-1:0] : B_in_r1[PARAM_Mantissa_PI_size+offset_bits:0]; 
assign M_result_non_normal  = A_in_r1+ B_in_f +sub_on; 

//next block
// BLK1
always @(posedge clk) begin 
  if (rst) begin 
    valid_r2                     <= 0;
    special_out_r2               <= 0;
    special_FLAG_r2              <= 0;
    take_special_r2              <= 0;
    M_result_non_normal_r2       <= 0;
    rm_r2                        <= 0;
    final_sign_r2                <= 0;
    E_num_1_big_r2              <= 0;


  end else   
    if (valid_r1)  begin 
      E_num_1_big_r2              <= E_num_1_big_r1;
      final_sign_r2               <=final_sign_r1               ;
      rm_r2                       <= rm_r1                      ;
      valid_r2                    <=        valid_r1            ;
      special_out_r2              <=  special_out_r1            ;
      special_FLAG_r2             <= special_FLAG_r1            ;
      take_special_r2             <= take_special_r1            ;
      M_result_non_normal_r2      <= M_result_non_normal;

    end else begin 
    valid_r2   <= 1'b0;
        special_out_r2               <= 0;
    end 
  
end 

wire   overflow_round;
leading_zeroth_bit #(
    .Bit_Length(   PARAM_Mantissa_PI_size+offset_bits+1),
    .Bit_Length_O( PARAM_Mantissa_size     )) leading_zeroth_bit_add ( 
    .in_wire(     M_result_non_normal_r2),
    .leading_zero(leading_zero),
    .all_zeros(M_all_zeros)
    );

assign M_result_non_normal_MP1_size_shift       = M_result_non_normal_r2 << leading_zero;
assign carry_out                                = M_result_non_normal_r2[PARAM_Mantissa_PI_size+offset_bits];

reg  [PARAM_Mantissa_PI_size+offset_bits:0] M_result_non_normal_MP1_size_shift_r3;
reg  carry_out_r3;

//next block
// BLK1
always @(posedge clk) begin 
  if (rst) begin 
    valid_r3                              <= 0;
    special_out_r3                        <= 0;
    special_FLAG_r3                       <= 0;
    take_special_r3                       <= 0;
    M_result_non_normal_MP1_size_shift_r3 <= 0;
    rm_r3                                 <= 0;
    final_sign_r3                         <= 0;
    leading_zero_r3                       <= 0;
    E_num_1_big_r3                        <= 0;
    M_all_zeros_r3                        <= 0;
    carry_out_r3 <=0;
  end else   
    if (valid_r2)  begin 
      M_all_zeros_r3                        <= M_all_zeros;
      E_num_1_big_r3                        <=  E_num_1_big_r2;
      final_sign_r3                         <=final_sign_r2   ;
      leading_zero_r3                       <= leading_zero   ;
      rm_r3                                 <= rm_r2          ;
      valid_r3                              <=        valid_r2;
      special_out_r3                        <=  special_out_r2;
      special_FLAG_r3                       <= special_FLAG_r2;
      take_special_r3                       <= take_special_r2;
      M_result_non_normal_MP1_size_shift_r3 <= M_result_non_normal_MP1_size_shift;
      carry_out_r3                          <= carry_out;
    end else begin 
    valid_r3   <= 1'b0;
    end 
end 


//last_blcok
FPU_rounder #(
    .PARAM_Fp_size(PARAM_Fp_size),
    .PARAM_Mantissa_size(PARAM_Mantissa_size),
    .PARAM_Exponent_size(PARAM_Exponent_size),
    .offset_bits(offset_bits) )
FPU_rounder (
.rm               (rm_r3),
.result_sign      (final_sign_r3),
.M_in_non_rounded (M_result_non_normal_MP1_size_shift_r3),
.M_final          (M_final_mantisa),
.overflow_round   (overflow_round),
.signal_inexact   (signal_inexact)
);


assign special_out_f     = complete_overdlow ? {final_sign_r3,8'hFF,23'd0} : special_out_r3;
assign take_special_f    = take_special_r3 || complete_overdlow;
assign special_FLAG_f    = {3'b0,complete_overdlow,1'b0} | special_FLAG_r3;

assign saved_mantissa    = M_final_mantisa[PARAM_Mantissa_size-1:0];
assign final_exponent    = carry_out_r3  ? (E_num_1_big_r3 + carry_out_r3+ overflow_round):  (E_num_1_big_r3 - leading_zero_r3+1 + overflow_round)  ;
assign complete_overdlow = ((final_exponent > 9'd254) | ((final_exponent == 9'd254) & carry_out_r3))&&(~take_special_r3) ; 
assign result_zero       = M_all_zeros_r3 && ~carry_out_r3;
assign final_result      = result_zero ? ({PARAM_Fp_size{1'b0}}) : {final_sign_r3,final_exponent[PARAM_Exponent_size-1:0],saved_mantissa};
assign Out_w             = take_special_f ? special_out_f : final_result;
assign exception         = special_FLAG_f;





endmodule



module leading_zeroth_bit 
#(  parameter Bit_Length   = 25,
    parameter Bit_Length_O = 6 ) (   
    input wire   [Bit_Length-1  :0] in_wire,
    output wire  [Bit_Length-1  :0] leading_one_oh,
    output wire  [Bit_Length_O-1:0] leading_zero,
    output wire all_zeros
);
integer i;
reg valid_r;
reg [Bit_Length-1  :0] leading_one_oh_r;    
reg [Bit_Length_O-1:0] leading_zero_r;

  always @ (*) begin
    valid_r          = 1'b0;
    leading_one_oh_r = {Bit_Length  {1'b0}};
    leading_zero_r   = {Bit_Length_O{1'b0}};
    
    // Scan from MSB down without break; gate with valid_r.
    for (i = Bit_Length-1; i >= 0; i = i - 1) begin
      if (!valid_r && (in_wire[i] == 1'b1)) begin
        valid_r               = 1'b1;
        leading_one_oh_r[i]   = 1'b1;
        leading_zero_r        = Bit_Length-i-1;
      end
    end
  end
assign  all_zeros = ~valid_r;
assign  leading_one_oh = leading_one_oh_r;
assign leading_zero    = leading_zero_r;
endmodule



module FPU_rounder #(    
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size =  8,
    parameter offset_bits         =  7
    )  (
    // rounds accrosing to RISCV
    input  wire [`size_Fp_fmt-1:0]                      rm               ,    
    input  wire [`size_Fp_fmt-1:0]                      frm              ,    
    input  wire                                         result_sign      ,    
    input  wire [PARAM_Mantissa_size+1+offset_bits:0]  M_in_non_rounded ,
    output wire [PARAM_Mantissa_size:0]                 M_final          ,
    output wire                                         overflow_round,
    output wire                                         signal_inexact          
);

wire [`size_Fp_fmt-1:0] actual_RM;
reg [PARAM_Mantissa_size:0]  M_final_reg;
localparam PARAM_Mantissa_PI_size= PARAM_Mantissa_size+1;

assign actual_RM = (rm==3'b111) ? frm  : rm;


wire [offset_bits:0] left_over_bits;
assign left_over_bits = M_in_non_rounded[offset_bits:0];
wire sticky,gurard,round;
assign guard                    = left_over_bits[offset_bits    ];
assign round                    = left_over_bits[offset_bits-1  ];
assign sticky                   = |left_over_bits[offset_bits-2:0];
assign signal_inexact           = sticky|guard|round;

wire   middle_rounding, round_up, round_down;
assign middle_rounding = ({guard,round,sticky} == 3'b100);
assign round_down      = ({guard             } == 1'b0  );
assign round_up        = ({guard,round|sticky} == 2'b1_1);//||({guard      ,round} == 2'b1_1);

wire ERROR_DETEC;
assign ERROR_DETEC = middle_rounding&round_down || middle_rounding&round_up  || round_down & round_up;

wire  [PARAM_Mantissa_size:0] M_final_RTZ, M_final_RNE, M_final_RUP, M_final_RDN, M_final_RMM;
wire [PARAM_Mantissa_PI_size-1:0]   truncated_mantissa;
wire [PARAM_Mantissa_PI_size  :0]   Mantissa_round_up_added;
wire [PARAM_Mantissa_PI_size-1:0]   mantissa_round_up;

assign truncated_mantissa      = M_in_non_rounded[PARAM_Mantissa_PI_size+offset_bits:offset_bits+1];
assign Mantissa_round_up_added = truncated_mantissa + 1'b1;
assign overflow_round          = Mantissa_round_up_added[PARAM_Mantissa_PI_size];
assign mantissa_round_up       = overflow_round ? Mantissa_round_up_added[PARAM_Mantissa_PI_size  :1] : Mantissa_round_up_added[PARAM_Mantissa_PI_size-1:0];


wire odd_high;
// assign M_final_mantisa = 
assign M_final_RTZ = M_in_non_rounded[PARAM_Mantissa_PI_size+offset_bits:offset_bits+1];
assign odd_high    = M_in_non_rounded[offset_bits+1]; 

//middle_rounding
wire RNE_condition,RUP_condition,RDN_condition;
assign RNE_condition =  round_up | odd_high&middle_rounding ;
assign M_final_RNE   =  RNE_condition  ? mantissa_round_up :truncated_mantissa;
assign RUP_condition = (guard|round|sticky)& ~result_sign;
assign M_final_RUP   = RUP_condition  ?  mantissa_round_up :truncated_mantissa;
assign RDN_condition = (guard|round|sticky)&  result_sign;
assign M_final_RDN   = RDN_condition  ?  mantissa_round_up :truncated_mantissa;
assign M_final_RMM   = ( round_up|middle_rounding)  ? mantissa_round_up :truncated_mantissa;;

assign M_final = M_final_reg;
always @(*) begin
case (actual_RM)
{3'b000}: begin 
  M_final_reg <= M_final_RNE;
end
{3'b001}: begin 
  M_final_reg <= M_final_RTZ;
end
{3'b010}: begin 
  M_final_reg <= M_final_RDN;
end
{3'b011}: begin 
  M_final_reg <= M_final_RUP;
end
{3'b100}: begin 
  M_final_reg <= M_final_RMM;
end
endcase

end

endmodule






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
    output     [4:0]                exception,
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
