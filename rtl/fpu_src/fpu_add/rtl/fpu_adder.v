`timescale 1ns/1ps

`ifndef size_Fp_fmt
`define size_Fp_fmt 3
`endif

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
    output                valid_out,
    output [2:0]          exception 
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
    reg   [2:0] special_FLAG, special_FLAG_r0,special_FLAG_r1,special_FLAG_r2,special_FLAG_r3;
    wire  [2:0] special_FLAG_f;
    reg         take_special, take_special_r0, take_special_r1, take_special_r2, take_special_r3;
    wire        take_special_f;

    always @* begin
        take_special = 1'b1;
        special_out  = 32'h0000_0000;
        special_FLAG = 3'b111;        
        if (a_is_nan || b_is_nan) begin 
          special_out  = QNAN;
          special_FLAG = 3'b100; //NV Invalid Operation
        end else if ((a_is_inf && ~b_is_inf) || (~a_is_inf &&  b_is_inf) ) begin 
          special_out  =  {final_sign,8'hFF,23'd0};
          special_FLAG =  3'b010; // OF Overflow
        end else if (a_is_inf && b_is_inf) begin 
          special_out  = SAeqSB ?  {final_sign,8'hFF,23'd0} :   QNAN;
          special_FLAG = SAeqSB ?  3'b010                   : 3'b100;  // OF Overflow
        end else if (a_is_zero || b_is_zero) begin 
          special_out =           {final_sign,8'h00,23'd0};
          special_FLAG = 3'b111;
        end else begin 
          // if (signal_inexact) begin 
          // special_FLAG = 3'b000;
          // end else begin 
          // special_FLAG = 3'b111;  
          // end
          special_FLAG = 3'b111;  
          take_special = 1'b0;
        end
    end

// Flag Mnemonic Flag Meaning
// 3'b100 NV Invalid Operation
// 3'b011 DZ Divide by Zero
// 3'b010 OF Overflow
// 3'b001 UF Underflow
// 3'b000 NX Inexact


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


  // wire sub = ~SAeqSB_r1;
  // wire [WIDTH-1:0] B_sel = sub ? ~B_in_r1 : B_in_r1;
  // wire             cin   = sub;

  // wire [WIDTH:0] addsub_full = {1'b0, A_in_r1} + {1'b0, B_sel} + cin;

  // assign M_sum               = addsub_full[WIDTH-1:0]; // same datapath, add when sub=0
  // assign M_sub               = addsub_full[WIDTH-1:0]; // same datapath, sub when sub=1
  // assign M_result_non_normal = SAeqSB_r1 ? M_sum : M_sub;

//  reg [PARAM_Mantissa_PI_size+offset_bits:0]  A_in_r1,B_in_r1;

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
assign special_FLAG_f    = complete_overdlow ?   3'b010 : special_FLAG_r3;

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



module FPU_ADDER_clk_stimTB;

  localparam integer PARAM_Fp_size       = 32;
  localparam integer PARAM_Mantissa_size = 23;
  localparam integer PARAM_Exponent_size = 8;

  reg  clk;

  reg  [`size_Fp_fmt-1:0] rm;
  reg  [PARAM_Fp_size-1:0]      A;
  reg  [PARAM_Fp_size-1:0]      B;
  wire [PARAM_Fp_size-1:0]      Out;

  // DUT
  FPU_ADDER_I #(
    .PARAM_Fp_size(PARAM_Fp_size),
    .PARAM_Mantissa_size(PARAM_Mantissa_size),
    .PARAM_Exponent_size(PARAM_Exponent_size)
  ) dut (
    .rm(rm),
    .A(A),
    .B(B),
    .Out(Out)
  );

  // 100 MHz nominal clock
  initial clk = 1'b0;
  always #5 clk = ~clk;



  // Stimulus + per-op display on next posedge
  initial begin
    // defaults
    // rm = 3'b000; A = 32'h0000_0000; B = 32'h0000_0000;
    // @(posedge clk); // settle

    // // 1) + 1.25 + 1.375
    // rm = 3'b000; A = 32'h3FA0_0000; B = 32'h3FB_0_0000; // RNE
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 1) + 1.25 +  751.375 
    // rm = 3'b000; A = 32'h3FA00000; B = 32'hBFC00000; // RNE
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);
    
    rm = 3'b000; B = 32'h0; A= 32'h0; // RNE
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);
    @(posedge clk);
    $finish;
  end

endmodule
