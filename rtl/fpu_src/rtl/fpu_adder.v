// define    `size_Fp_fmt 3
// FPU_ADDER_clk_stimTB.v
`timescale 1ns/1ps

`ifndef size_Fp_fmt
`define size_Fp_fmt 3
`endif

module FPU_ADDER_I #(    
    parameter PARAM_Fp_size       = 32,
    parameter PARAM_Mantissa_size = 23,
    parameter PARAM_Exponent_size =  8

    )  (
    input  [`size_Fp_fmt-1:0] rm,    
    input  [PARAM_Fp_size-1:0] A,
    input  [PARAM_Fp_size-1:0] B, 
    output [PARAM_Fp_size-1:0] Out
);
localparam N_bit_adder = PARAM_Mantissa_PI_size;
localparam PARAM_Mantissa_PI_size = PARAM_Mantissa_size   +1;
parameter offset_bits = 7;

wire [PARAM_Mantissa_size-1   :0] M_B,M_A; 
wire [PARAM_Mantissa_PI_size-1:0] M_B_total,M_A_total; 
wire [PARAM_Exponent_size-1   :0] E_B,E_A, E_num_1_big, E_num_0_small;
wire [7:0] EA; 
wire S_B,S_A, a_is_nan, b_is_nan,    a_is_inf, b_is_inf, is_subnormal_B,is_subnormal_A;
wire [PARAM_Exponent_size-1   :0]    E_A_eff, E_B_eff;
wire [PARAM_Mantissa_size     :0]    E_diff_big_small ,E_diff_big_small_mod;
wire [PARAM_Mantissa_PI_size+offset_bits:0]    M_sum,M_sub;
wire [PARAM_Mantissa_PI_size+offset_bits:0]    M_result_non_normal;
wire [PARAM_Mantissa_PI_size-1:0]    M_sub_24;
wire [PARAM_Mantissa_PI_size-1:0]    M_num_0_small,M_num_1_big,M_shifted_small;  
reg [2*PARAM_Mantissa_PI_size-1:0]   M_shifted_small_pre_selection;  //47:0
wire[PARAM_Mantissa_PI_size-1 :0]    M_shifted_small_roudning; 

localparam [31:0] QNAN = 32'h7FC0_0000;
leading_zeroth_bit #(
    .Bit_Length(   PARAM_Mantissa_PI_size+offset_bits+1),
    .Bit_Length_O( PARAM_Mantissa_size     )) leading_zeroth_bit_add ( 
    .in_wire(     M_result_non_normal),
    .leading_zero(leading_zero),
    .all_zeros(M_all_zeros)
    );


wire final_sign;
wire [PARAM_Fp_size-1:0] final_result;
wire [ PARAM_Mantissa_size:0]  M_final_mantisa; // 24
wire [ PARAM_Mantissa_size:0] M_result_non_normal_shifted;
wire [ PARAM_Mantissa_size:0] M_result_carry_out;

wire [PARAM_Mantissa_size-1:0] saved_mantissa,leading_zero;
wire [PARAM_Exponent_size-1:0] final_exponent;
wire M_all_zeros, result_zero;
wire  [PARAM_Mantissa_PI_size+offset_bits:0] M_result_non_normal_MP1_size, M_result_non_normal_MP1_size_shift,M_result_non_normal_MP1_size_shift_carry;
wire carry_out;


// initial assignments
assign M_A[PARAM_Mantissa_size-1:0]=A[PARAM_Mantissa_size-1:0];
assign M_B[PARAM_Mantissa_size-1:0]=B[PARAM_Mantissa_size-1:0];

assign E_A[PARAM_Exponent_size-1:0]=A[PARAM_Exponent_size-1+PARAM_Mantissa_PI_size:PARAM_Mantissa_size];
assign E_B[PARAM_Exponent_size-1:0]=B[PARAM_Exponent_size-1+PARAM_Mantissa_PI_size:PARAM_Mantissa_size];

assign S_A=A[PARAM_Fp_size-1];
assign S_B=B[PARAM_Fp_size-1];

//special cases
assign a_is_nan  = (E_A==8'hFF) && (M_A!=23'b0);
assign b_is_nan  = (E_B==8'hFF) && (M_B!=23'b0);
assign a_is_inf  = (E_A==8'hFF) && (M_A==23'b0);
assign b_is_inf  = (E_B==8'hFF) && (M_B==23'b0);


//detect subnormal
assign is_subnormal_A = (E_A == {PARAM_Exponent_size{1'b0}});
assign is_subnormal_B = (E_B == {PARAM_Exponent_size{1'b0}});

assign E_A_eff   = is_subnormal_A ? 8'd1 : E_A;
assign E_B_eff   = is_subnormal_B ? 8'd1 : E_B;
assign M_A_total = {~is_subnormal_A,M_A};
assign M_B_total = {~is_subnormal_B,M_B};


wire a_GTEQ_b;
assign a_GTEQ_b = ( {E_A,M_A} >= {E_B,M_B} );

assign M_num_1_big      = a_GTEQ_b ?  M_A_total : M_B_total; 
assign M_num_0_small    = a_GTEQ_b ?  M_B_total : M_A_total; 
assign E_num_1_big      = a_GTEQ_b ?  E_A_eff   : E_B_eff  ; 
assign E_num_0_small    = a_GTEQ_b ?  E_B_eff   : E_A_eff  ;
// wire   S_A_bigger_sign = 

// aligment
assign E_diff_big_small         =  E_num_1_big - E_num_0_small;
assign E_diff_big_small_too_big =  E_diff_big_small > PARAM_Mantissa_PI_size+offset_bits+1;

always @(*) begin 
if (E_diff_big_small_too_big) begin 
    M_shifted_small_pre_selection = 0;
end else begin 
    M_shifted_small_pre_selection =  {M_num_0_small,{PARAM_Mantissa_PI_size{1'b0}}} >> E_diff_big_small;
end
end


assign M_shifted_small          =  M_shifted_small_pre_selection[2*PARAM_Mantissa_PI_size-1:PARAM_Mantissa_PI_size];// 47:24|23:0
assign M_shifted_small_roudning =  M_shifted_small_pre_selection[PARAM_Mantissa_PI_size-1  :                      0];// 23:0


wire [PARAM_Mantissa_PI_size+offset_bits:0]  A_in,B_in;

assign A_in = {1'b0,M_num_1_big,{offset_bits{1'b0}}};
assign B_in = {1'b0,M_shifted_small,M_shifted_small_roudning[PARAM_Mantissa_PI_size-1:PARAM_Mantissa_PI_size-offset_bits]};
assign M_sum                = A_in+B_in; //{1'b0,M_num_1_big,{offset_bits{1'b0}}} + {1'b0,M_shifted_small,M_shifted_small_roudning[PARAM_Mantissa_PI_size-1:PARAM_Mantissa_PI_size-offset_bits]}; //23:21
assign M_sub                = A_in-B_in; //{1'b0,M_num_1_big,{offset_bits{1'b0}}} - {1'b0,M_shifted_small,M_shifted_small_roudning[PARAM_Mantissa_PI_size-1:PARAM_Mantissa_PI_size-offset_bits]}; //23:21 


// add / subtractioA+Bn//
assign M_result_non_normal  = (S_A == S_B) ? M_sum : M_sub;

assign M_result_non_normal_MP1_size_shift       = M_result_non_normal << leading_zero;
assign carry_out                                = M_result_non_normal[PARAM_Mantissa_PI_size+offset_bits];
// assign M_final_mantisa                          = M_result_non_normal_MP1_size_shift[PARAM_Mantissa_PI_size+offset_bits:offset_bits+1];//27:3//#PARAM_Mantissa_PI_size+offset_bits:offset_bits];

FPU_rounder #(
    .PARAM_Fp_size(PARAM_Fp_size),
    .PARAM_Mantissa_size(PARAM_Mantissa_size),
    .PARAM_Exponent_size(PARAM_Exponent_size),
    .offset_bits(offset_bits) )
FPU_rounder (
.rm               (rm),
.result_sign      (final_sign),
.M_in_non_rounded (M_result_non_normal_MP1_size_shift),
.M_final          (M_final_mantisa)
);


// always @(*) begin

// end
assign saved_mantissa = M_final_mantisa[PARAM_Mantissa_size-1:0];
assign final_exponent = carry_out  ? (E_num_1_big + carry_out):  (E_num_1_big - leading_zero+1)  ;
assign result_zero    = M_all_zeros && ~carry_out;
assign final_sign = a_GTEQ_b ? S_A : S_B;
// assign final_sign = 0;//a_GTEQ_b ? S_A : S_B;

assign final_result   = result_zero ? ({PARAM_Fp_size{1'b0}}) : {final_sign,final_exponent,saved_mantissa};
assign Out = final_result;

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
    input  wire [`size_Fp_fmt-1:0]                      rm               ,    
    input  wire [`size_Fp_fmt-1:0]                      frm              ,    
    input  wire                                         result_sign      ,    
    input  wire [PARAM_Mantissa_size+1+offset_bits:0]  M_in_non_rounded ,
    output wire [PARAM_Mantissa_size:0]                 M_final          ,
    output wire                                         overflow_round          
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

  // Waveform dump
  // initial begin
  //   $dumpfile("fpu_adder_tb.vcd");
  //   $dumpvars(0, FPU_ADDER_clk_stimTB);
  // end

  // Stimulus + per-op display on next posedge
  initial begin
    // defaults
    rm = 3'b000; A = 32'h0000_0000; B = 32'h0000_0000;
    @(posedge clk); // settle

    // 1) + 1.25 + 1.375
    rm = 3'b000; A = 32'h3FA0_0000; B = 32'h3FB_0_0000; // RNE
    @(posedge clk);
    $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // 1) + 1.25 +  751.375 
    rm = 3'b000; A = 32'h3FA00000; B = 32'hBFC00000; // RNE
    @(posedge clk);
    $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);
    
    rm = 3'b000; B = 32'h3FA00000; A= 32'hBFC00000; // RNE
    @(posedge clk);
    $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);




    // // 1) + 1.25 + 1.25
    // rm = 3'b000; A = 32'h3FA0_0000; B = 32'h3FA0_0000; // RNE
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 2) -1.5 + 1.25
    // rm = 3'b000; A = 32'hBFC0_0000; B = 32'h3FA0_0000;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 3) +0 + -0
    // rm = 3'b000; A = 32'h0000_0000; B = 32'h8000_0000;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 4) Large gap: 1.0 + tiny
    // rm = 3'b000; A = 32'h3F80_0000; B = 32'h2F00_0000;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 5) Big numbers: ~1e20 + ~1e20
    // rm = 3'b000; A = 32'h5F1B_3E64; B = 32'h5F1B_3E64;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 6) +inf + 1.0
    // rm = 3'b000; A = 32'h7F80_0000; B = 32'h3F80_0000;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 7) NaN + 2.0
    // rm = 3'b000; A = 32'h7FC0_0001; B = 32'h4000_0000;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 8) Subnormal + 0.5
    // rm = 3'b000; A = 32'h0000_0080; B = 32'h3F00_0000;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 9) RTZ: 0.3 + 0.3
    // rm = 3'b001; A = 32'h3E99_999A; B = 32'h3E99_999A;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 10) RUP: 0.3 + 0.2
    // rm = 3'b010; A = 32'h3E99_999A; B = 32'h3E4C_CCCD;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 11) RDN: 0.5 + min subnormal
    // rm = 3'b011; A = 32'h3F00_0000; B = 32'h0000_0001;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    // // 12) Cancelation: -50 + 50
    // rm = 3'b000; A = 32'hC248_0000; B = 32'h4248_0000;
    // @(posedge clk);
    // $display("[%0t] rm=%0d A=0x%08h B=0x%08h -> Out=0x%08h", $time, rm, A, B, Out);

    @(posedge clk);
    $finish;
  end

endmodule
