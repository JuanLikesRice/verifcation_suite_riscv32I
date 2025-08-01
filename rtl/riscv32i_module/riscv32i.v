`default_nettype none
`include "params.vh"

module riscv32i
   # (
    parameter   N_param = 32
   )     (
    input  wire         clk,
    input  wire [31:0]  GPIO0_R0_CH1, // control signals
    input  wire [31:0]  GPIO0_R0_CH2, // memory_offset
    input  wire [31:0]  GPIO0_R1_CH1, // initial_pc_i
    input  wire [31:0]  GPIO0_R1_CH2, // success_code

    output wire         STOP_sim,

    // BRAM ports for Data Mem
    output wire         data_mem_clkb,
    output wire         data_mem_enb,
    output wire         data_mem_rstb,
    output wire [3:0]   data_mem_web,
    output wire [31:0]  data_mem_addrb,
    output wire [31:0]  data_mem_dinb,
    input  wire         data_mem_rstb_busy,
    input  wire [31:0]  data_mem_doutb,

    // BRAM ports for peripheral Mem
    output wire         peripheral_mem_clkb,
    output wire         peripheral_mem_enb,
    output wire         peripheral_mem_rstb,
    output wire [3:0]   peripheral_mem_web,
    output wire [31:0]  peripheral_mem_addrb,
    output wire [31:0]  peripheral_mem_dinb,
    input  wire         peripheral_mem_rstb_busy,
    input  wire [31:0]  peripheral_mem_doutb,
    input  wire         timer_timeout, 


    // // BRAM ports for Ins Mem

    output wire         ins_mem_clkb,
    output wire         ins_mem_enb,
    output wire         ins_mem_rstb,
    output wire [3:0]   ins_mem_web,
    output wire [31:0]  ins_mem_addrb,
    output wire [31:0]  ins_mem_dinb,
    input  wire         ins_mem_rstb_busy,
    input  wire [31:0]  ins_mem_doutb
);



reg enable_design_reg;
reg stop_design;
wire enable_design;
wire start_design , reset;
reg [31:0] cycle_to_end;
wire [31:0] control_signals_in;
reg [31:0]  Cycle_count  ;
wire [31:0]  memory_offset;
wire [31:0]  initial_pc_i ;
wire [31:0]  success_code  ;
wire [31:0]  final_value  ;


wire        ins_data_req_o;
wire [31:0] ins_data_addr_o;
wire        ins_data_we_o;
wire [ 3:0] ins_data_be_o;
wire [31:0] ins_data_wdata_o;
wire   [31:0]     ins_data_rdata_i;
wire        ins_data_rvalid_i;
wire        ins_data_gnt_i;



wire              Dmem_data_req_o;
wire [31:0]       Dmem_data_addr_o;
wire              Dmem_data_we_o;
wire [ 3:0]       Dmem_data_be_o;
wire [31:0]       Dmem_data_wdata_o;
wire   [31:0]     Dmem_data_rdata_i;
wire              Dmem_data_rvalid_i;
wire              Dmem_data_gnt_i;


wire              Pmem_data_req_o;
wire [31:0]       Pmem_data_addr_o;
wire              Pmem_data_we_o;
wire [ 3:0]       Pmem_data_be_o;
wire [31:0]       Pmem_data_wdata_o;
wire   [31:0]     Pmem_data_rdata_i;
wire              Pmem_data_rvalid_i;
wire              Pmem_data_gnt_i;



pulse_generator pulse_generator_GPIO0_R0_CH1 (
    .clk(clk),
    .in(GPIO0_R0_CH1),
    .out(control_signals_in)
);

assign STOP_sim           = stop_design;
assign  memory_offset     = GPIO0_R0_CH2;
assign  initial_pc_i      = GPIO0_R1_CH1;
assign  success_code      = GPIO0_R1_CH2;

assign start_design    = control_signals_in[0];
assign reset           = control_signals_in[1];

assign enable_design = enable_design_reg & ~stop_design;


wire finished_program;

always @(posedge clk) begin
  	if (reset) begin
      cycle_to_end        <= 32'h0;
	    Cycle_count         <= 32'h0;
	    enable_design_reg   <=  1'b0;
      stop_design         <=  1'b0;
    end else begin  
    if (start_design) begin 
	    Cycle_count         <= 32'h0;
	    enable_design_reg   <=  1'b1;
    end else if (enable_design_reg) begin
        Cycle_count         <= Cycle_count + 1;
	      enable_design_reg   <= enable_design_reg;
    end      
    if (finished_program)begin 
        cycle_to_end <= cycle_to_end + 1;
        stop_design  <= 1'b0;
    end
    if (cycle_to_end >= 30) begin
        stop_design <= 1'b1;
        
    //MARKER AUTOMATED HERE START
        
    $display("\n\n\n\n----TB FINISH:Test Passed----\n\n\n\n\nTEST FINISHED by success write :%h \n\n\n\n\n",success_code);
    
    //MARKER AUTOMATED HERE END
end 
end
end 


    wire Dmem_clk, Imem_clk, Pmem_clk;
    // Instantiation of riscv32i_main
    riscv32i_main #(
        .N_param(32)
    ) u_riscv32i_main (
        .clk(             clk),
        .reset(           reset),
        .Cycle_count(     Cycle_count),

        // four GPIO IPUTS
        .control_signal(    control_signals_in),
        .memory_offset(     memory_offset),
        .initial_pc_i(      initial_pc_i),
        .success_code(      success_code),
      
        .finished_program(  finished_program),
        // .final_value(     final_value),
        

      .Dmem_clk(            Dmem_clk),
      .Dmem_data_req_o(     Dmem_data_req_o),
      .Dmem_data_addr_o(    Dmem_data_addr_o),
      .Dmem_data_we_o(      Dmem_data_we_o),
      .Dmem_data_be_o(      Dmem_data_be_o),
      .Dmem_data_wdata_o(   Dmem_data_wdata_o),
      .Dmem_data_rdata_i(   Dmem_data_rdata_i),
      .Dmem_data_rvalid_i(  Dmem_data_rvalid_i),
      .Dmem_data_gnt_i(     Dmem_data_gnt_i),



      .Pmem_clk(            Pmem_clk),
      .Pmem_data_req_o(     Pmem_data_req_o),
      .Pmem_data_addr_o(    Pmem_data_addr_o),
      .Pmem_data_we_o(      Pmem_data_we_o),
      .Pmem_data_be_o(      Pmem_data_be_o),
      .Pmem_data_wdata_o(   Pmem_data_wdata_o),
      .Pmem_data_rdata_i(   Pmem_data_rdata_i),
      .Pmem_data_rvalid_i(  Pmem_data_rvalid_i),
      .Pmem_data_gnt_i(     Pmem_data_gnt_i),
      .timer_timeout(       timer_timeout),


        // Memory interface signals
        .ins_data_req_o     (ins_data_req_o),
        .ins_data_addr_o    (ins_data_addr_o),
        .ins_data_we_o      (ins_data_we_o),
        .ins_data_be_o      (ins_data_be_o),
        .ins_data_wdata_o   (ins_data_wdata_o),
        .ins_data_rdata_i   (ins_data_rdata_i),
        .ins_data_rvalid_i  (ins_data_rvalid_i),
        .ins_data_gnt_i     (ins_data_gnt_i)
    );



    data_mem_bram_wrapper  data_mem_bram_wrapper (
        .clk               (    clk),
        .reset             (    reset),

        .ins_data_req_o    (    Dmem_data_req_o),
        .ins_data_addr_o   (    Dmem_data_addr_o),
        .ins_data_we_o     (    Dmem_data_we_o),
        .ins_data_be_o     (    Dmem_data_be_o),
        .ins_data_wdata_o  (    Dmem_data_wdata_o),
        .ins_data_rdata_i  (    Dmem_data_rdata_i),
        .ins_data_rvalid_i (    Dmem_data_rvalid_i),
        .ins_data_gnt_i    (    Dmem_data_gnt_i),


        // .data_clk(Imem_clk),
        .ins_mem_clkb (       data_mem_clkb),
        .ins_mem_enb (        data_mem_enb),
        .ins_mem_rstb (       data_mem_rstb),
        .ins_mem_web (        data_mem_web),
        .ins_mem_addrb (      data_mem_addrb),
        .ins_mem_dinb (       data_mem_dinb),
        .ins_mem_rstb_busy (  data_mem_rstb_busy),
        .ins_mem_doutb (      data_mem_doutb)

    );
    

    peripheral_mem_bram_wrapper  peripheral_mem_bram_wrapper (
        .clk               (    clk),
        .reset             (    reset),

        .ins_data_req_o    (    Pmem_data_req_o),
        .ins_data_addr_o   (    Pmem_data_addr_o),
        .ins_data_we_o     (    Pmem_data_we_o),
        .ins_data_be_o     (    Pmem_data_be_o),
        .ins_data_wdata_o  (    Pmem_data_wdata_o),
        .ins_data_rdata_i  (    Pmem_data_rdata_i),
        .ins_data_rvalid_i (    Pmem_data_rvalid_i),
        .ins_data_gnt_i    (    Pmem_data_gnt_i),


        // .data_clk(Imem_clk),
        .ins_mem_clkb (       peripheral_mem_clkb),
        .ins_mem_enb (        peripheral_mem_enb),
        .ins_mem_rstb (       peripheral_mem_rstb),
        .ins_mem_web (        peripheral_mem_web),
        .ins_mem_addrb (      peripheral_mem_addrb),
        .ins_mem_dinb (       peripheral_mem_dinb),
        .ins_mem_rstb_busy (  peripheral_mem_rstb_busy),
        .ins_mem_doutb (      peripheral_mem_doutb)

    );



    inst_mem_bram_wrapper  inst_mem_bram_wrapper (
        .clk               (clk),
        .reset             (reset),
        .ins_data_req_o    (ins_data_req_o),
        .ins_data_addr_o   (ins_data_addr_o),
        .ins_data_we_o     (ins_data_we_o),
        .ins_data_be_o     (ins_data_be_o),
        .ins_data_wdata_o  (ins_data_wdata_o),
        .ins_data_rdata_i  (ins_data_rdata_i),
        .ins_data_rvalid_i (ins_data_rvalid_i),
        .ins_data_gnt_i    (ins_data_gnt_i),
        // .data_clk(Imem_clk),
        .ins_mem_clkb (ins_mem_clkb),
        .ins_mem_enb (ins_mem_enb),
        .ins_mem_rstb (ins_mem_rstb),
        .ins_mem_web (ins_mem_web),
        .ins_mem_addrb (ins_mem_addrb),
        .ins_mem_dinb (ins_mem_dinb),
        .ins_mem_rstb_busy (ins_mem_rstb_busy),
        .ins_mem_doutb (ins_mem_doutb)
    );
    


endmodule




module riscv32i_main 
   # (
    parameter   N_param = 32
   ) (
    input  wire clk,
    input  wire reset,

    input  wire [31:0] Cycle_count,

    input  wire [31:0]  control_signal,
    input  wire [31:0]  memory_offset,
    input  wire [31:0]  initial_pc_i,
    // output wire [31:0]  final_value,
    input  wire [31:0]  success_code,
    output wire         finished_program,

    // // BRAM ports for Data Mem// output wire        data_mem_clkb,// output wire        data_mem_enb,// output wire        data_mem_rstb,// output wire [3:0 ] data_mem_web,// output wire [31:0] data_mem_addrb,// output wire [31:0] data_mem_dinb,// input  wire        data_mem_rstb_busy,// input  wire [31:0] data_mem_doutb,

    // Memory interface signals
    output  wire          Dmem_clk,
    output wire           Dmem_data_req_o,
    output wire [31:0]    Dmem_data_addr_o,
    output wire           Dmem_data_we_o,
    output wire  [3:0]    Dmem_data_be_o,
    output wire [31:0]    Dmem_data_wdata_o,
    input  wire  [31:0]   Dmem_data_rdata_i,
    input  wire           Dmem_data_rvalid_i,
    input  wire           Dmem_data_gnt_i,
    input  wire           timer_timeout,


    // output  wire          Pmem_clk,
    // output wire           Pmem_data_req_o,
    // output wire [31:0]    Pmem_data_addr_o,
    // output wire           Pmem_data_we_o,
    // output wire  [3:0]    Pmem_data_be_o,
    // output wire [31:0]    Pmem_data_wdata_o,
    // input  wire  [31:0]   Pmem_data_rdata_i,
    // input  wire           Pmem_data_rvalid_i,
    // input  wire           Pmem_data_gnt_i,



// peripheral interface signals
    output  wire          Pmem_clk,
    output wire           Pmem_data_req_o,
    output wire [31:0]    Pmem_data_addr_o,
    output wire           Pmem_data_we_o,
    output wire  [3:0]    Pmem_data_be_o,
    output wire [31:0]    Pmem_data_wdata_o,
    input  wire  [31:0]   Pmem_data_rdata_i,
    input  wire           Pmem_data_rvalid_i,
    input  wire           Pmem_data_gnt_i,



    // //bram  Ins_mem// output wire        ins_mem_clkb,// output wire        ins_mem_enb,// output wire        ins_mem_rstb,// output wire [3:0 ] ins_mem_web,// output wire [31:0] ins_mem_addrb,// output wire [31:0] ins_mem_dinb,// input  wire        ins_mem_rstb_busy,// input  wire [31:0] ins_mem_doutb

    input  wire           Imem_clk,
    output wire           ins_data_req_o,
    output wire [31:0]    ins_data_addr_o,
    output wire           ins_data_we_o,
    output wire  [3:0]    ins_data_be_o,
    output wire [31:0]    ins_data_wdata_o,
    input  wire  [31:0]   ins_data_rdata_i,
    input  wire           ins_data_rvalid_i,
    input  wire           ins_data_gnt_i

);


    wire  [N_param-1:0]  instruction;
    wire  [4:0] rd_o;
    wire  [4:0] rs1_o;
    wire  [4:0] rs2_o;
    wire   [11:0] csr_o;
    wire  [2:0] fun3_o;
    wire  [6:0] fun7_o;
    wire  [31:0] imm_o;
    wire  [6:0] INST_typ_o, opcode_o;
    wire  [63:0] Single_Instruction_o;
    wire  i_en;

    // param_module params ();
    reg halt_i;
    reg [63:0] pipeReg0;
    reg [511:0] pipeReg1, pipeReg2, pipeReg3;

    wire [63:0]  pipeReg0_wire;
    wire [511:0] pipeReg1_wire, pipeReg2_wire, pipeReg3_wire;

    wire pc_valid;
    wire [31:0]  final_value;
initial begin 
    halt_i          <= 0;
end

  wire irq_prep;
  wire enable_design;
  wire pulsed_irq_prep;
  wire [31:0] interrupt_vector_i;

  pulse_generator_1bit pulse_generator_1bit (
    .clk(clk),
    .in(  irq_prep),
    .out( pulsed_irq_prep)
);

    core_controller_fsm core_controller_fsm (
        .clk(                         clk),
        .control_signal(              control_signal),

        // .initate_irq(                 initate_irq),
        .end_condition(               end_condition),
        .all_ready(                   all_ready),
        .ready_for_irq_handler(       ready_for_irq_handler),
        // .irq_service_done(            irq_service_done),
        .irq_req_i(                   irq_req_i),
        .irq_addr_i(                  irq_addr_i),

        .program_finished(            finished_program),
        .irq_grant_o(                 irq_grant_o),
        .override_all_stop(           override_all_stop),
        .enable_design(               enable_design),

        .reset(                       reset),
        .write_csr(                   write_csr_wire_stage3),
        .csrReg_write_dest_reg(       csr_stage3),
        .csrReg_write_dest_reg_data(  csr_val_stage3),

        .csrReg_read_src_reg(         csr_o),
        .csrReg_read_src_reg_data(    csr_regfile_o),
        .mepc(                        mepc),
        .mret_inst(                   mret_inst),

        .irq_prep(                    irq_prep),
        .timer_timeout(               timer_timeout),
        .nextPC_o(                                nextPC_o),
        .pc_stage_2(                              pc_stage_2),
        .change_PC_condition_for_jump_or_branch(  change_PC_condition_for_jump_or_branch),
        .interrupt_vector_i(          interrupt_vector_i),
        .Single_Instruction_stage2(Single_Instruction_stage2)


    );



wire initate_irq,end_condition,all_ready,ready_for_irq_handler,irq_service_done,irq_req_i;
wire [31:0] irq_addr_i;
wire irq_grant_o, override_all_stop;

assign  initate_irq             = 1'b0;  
assign  end_condition           = (final_value == success_code);  
assign  all_ready               = 1'b0;  
assign  ready_for_irq_handler   = 1'b1;  
assign  irq_service_done        = 1'b0;  
assign  irq_req_i               = 1'b0;  
assign  irq_addr_i              = 32'h0;


wire [31:0] nextPC_o;
wire change_PC_condition_for_jump_or_branch;
wire [31:0] mepc;
wire mret_inst;

    pc pc  (
        .clk_i(clk),
        .reset_i(reset),
        .stage_IF_ready(stage_IF_ready),
        .jump_inst_wire(jump_inst_wire_stage2),
        .branch_inst_wire(branch_inst_wire_stage2),
        .targetPC_i(alu_result_2_stage2),
        .enable_design(enable_design),
        .pc_o(pc_i),
        .initial_pc_i(initial_pc_i),
        .pc_valid(pc_valid),

        .nextPC_o(                                nextPC_o),
        .change_PC_condition_for_jump_or_branch(  change_PC_condition_for_jump_or_branch),
        .interrupt_vector_i(                      interrupt_vector_i),
        .irq_prep(                                irq_prep),
        .mret_inst(                               mret_inst),
        .mepc(                                    mepc)

    );

    // ins_mem  ins_mem(
    //     .clk(clk),
    //     .reset(reset),
    //     .pc_i(pc_i),
    //     .enb(stage0_IF_valid),
    //     .instruction_o(instruction),

    //     //bram ins mem
    //     .ins_mem_clkb(       ins_mem_clkb),
    //     .ins_mem_enb(        ins_mem_enb),
    //     .ins_mem_rstb(       ins_mem_rstb),
    //     .ins_mem_web(        ins_mem_web),
    //     .ins_mem_addrb(      ins_mem_addrb),
    //     .ins_mem_dinb(       ins_mem_dinb),
    //     .ins_mem_rstb_busy(  ins_mem_rstb_busy),
    //     .ins_mem_doutb(      ins_mem_doutb)
    // );


    
    wire pc_i_valid = 1'b1;
    wire stall_i;
    wire STALL_IF_not_ready_w,STALL_ID_not_ready_w;
    assign stall_i = ~stage0_IF_valid;
    wire exec_stall = ~stage_EXEC_ready;
    ins_mem ins_mem (
        .clk                 (clk),
        .reset               (reset),
        .pc_i                (pc_i),
        .pc_i_valid          (pc_valid),
        .STALL_IF_not_ready_w(STALL_IF_not_ready_w),
        .STALL_ID_not_ready_w(STALL_ID_not_ready_w),
        .instruction_o_w     (instruction),
        .stall_i_EXEC        (exec_stall),
        .abort_rvalid(        delete_reg1_reg2),

        .stop_request_overide(      stop_request_overide_insmem),
        .reset_able(                reset_able_insmem),



        // Memory interface signals
        .data_clk             (Imem_clk),
        .data_req_o_w         (ins_data_req_o),
        .data_addr_o_w        (ins_data_addr_o),
        .data_we_o_w          (ins_data_we_o),
        .data_be_o_w          (ins_data_be_o),
        .data_wdata_o_w       (ins_data_wdata_o),
        .data_rdata_i         (ins_data_rdata_i),
        .data_rvalid_i        (ins_data_rvalid_i),
        .data_gnt_i           (ins_data_gnt_i)
    );


wire write_csr_wire,write_csr_wire_stage2;
// Pre Stage 0
wire [31:0] pc_stage_0,instruction_stage_0;
wire we_pi;
wire [31:0] pc_o,pc_i;
wire [31:0] writeData_pi,operand1_po,operand2_po, csrData_pi;


//stage 1 varibles
wire [31:0] pc_stage_1;
wire [31:0] instruction_stage_1;
wire [ 4:0] rd_stage1;
wire [ 2:0] fun3_stage1;
wire [ 6:0] fun7_stage1;
wire [ 6:0] INST_typ_stage1;
wire [ 6:0] opcode_stage1;
wire [ 4:0] rs1_stage1;
wire [ 4:0] rs2_stage1;
wire [11:0] csr_stage1;
wire [31:0] csr_val_stage1;
wire [31:0] operand1_stage1;
wire [31:0] operand2_stage1;
wire [31:0] imm_stage1;
wire [63:0] Single_Instruction_stage1;
wire [31:0] alu_result_1;
wire [31:0] alu_result_2;


//stage 2
wire [31:0] pc_stage_2;
wire [31:0] instruction_stage_2;
wire [ 4:0] rd_stage2;
wire [ 2:0] fun3_stage2;
wire [ 6:0] fun7_stage2;
wire [ 6:0] INST_typ_stage2;
wire [ 6:0] opcode_stage2;
wire [ 4:0] rs1_stage2;
wire [ 4:0] rs2_stage2;
wire [11:0] csr_stage2;
wire [31:0] csr_val_stage2;
wire [31:0] operand1_stage2;
wire [31:0] operand2_stage2;
wire [31:0] imm_stage2;
wire [63:0] Single_Instruction_stage2;
wire [31:0] alu_result_1_stage2;
wire [31:0] alu_result_2_stage2;


//Stage 3
wire [31:0] pc_stage_3;
wire [31:0] instruction_stage_3;
wire [ 4:0] rd_stage3;
wire [ 2:0] fun3_stage3;
wire [ 6:0] fun7_stage3;
wire [ 6:0] INST_typ_stage3;
wire [ 6:0] opcode_stage3;
wire [ 4:0] rs1_stage3;
wire [ 4:0] rs2_stage3;
wire [11:0] csr_stage3;
wire [31:0] csr_val_stage3;
wire [31:0] operand1_stage3;
wire [31:0] operand2_stage3;
wire [31:0] imm_stage3;
wire [63:0] Single_Instruction_stage3;
wire [31:0] alu_result_1_stage3;
wire [31:0] alu_result_2_stage3;
wire        write_reg_file_wire_stage3;
wire        write_csr_wire_stage3;
wire        load_into_reg_stage3;
wire [31:0] loaded_data_stage3;


//Data Mem wires
wire [31:0] loaded_data;
wire load_into_reg;
wire stall_mem_not_avalible;

//Pc
wire branch_inst_wire_stage2;
wire jump_inst_wire_stage2;

//Going into exect
//exec 
wire [31:0] operand1_into_exec;
wire [31:0] operand2_into_exec;
wire [31:0] result_secondary;
wire        jump_inst_wire,branch_inst_wire;


//Hazard
wire write_reg_file_wire_stage2;
wire [31:0] rd_result_stage2;

reg delete_reg1_reg2_reg;

wire [31:0] csr_regfile_o;


//Control signals 
wire   delete_reg1_reg2; 
wire   write_reg_stage3;
wire   write_reg_file_wire;


// Writing to WB regsiter
wire stage_WB_ready;  // Writestage ready for new register
wire stage_MEM_done;  // Memstage done
wire stage3_MEM_valid; // enables new write to PipeReg3

wire stage_MEM_ready;   // MEM  ready for new register
wire stage_EXEC_done;   // EXEC done
wire stage2_EXEC_valid; // enables new write to PipeReg2

wire stage_EXEC_ready;   // EXEC  ready for new register
wire stage_DECO_done;   //  DECO done
wire stage1_DECO_valid; // enables new write to PipeReg1

wire stage_DECO_ready;   // DECO  ready for new register
wire stage_IF_done;      //  IF    done
wire stage0_IF_valid;   // enables new write to PipeReg0

wire stage_IF_ready;   // IF  ready for PC register


//writing into destination reg
assign write_reg_stage3 = write_reg_file_wire_stage3|load_into_reg_stage3;

//flush from branch
assign delete_reg1_reg2 = branch_inst_wire_stage2 | jump_inst_wire_stage2| irq_prep | mret_inst;

//Value being wrtten to regfile in WBB stage, also may be forwarded to ALU
assign writeData_pi     = load_into_reg_stage3 ? loaded_data_stage3 : alu_result_1_stage3;
// assign csrData_pi       = alu_result_2_stage3;


//Value being wrtten to regfile in MEM stage, also may be forwarded to ALU
assign rd_result_stage2 = load_into_reg ? loaded_data : alu_result_1_stage2;


wire    stop_request_overide_datamem, reset_able_datamem;  
assign  stop_request_overide_datamem = 1'b0;
wire    stop_request_overide_insmem, reset_able_insmem;  
assign  stop_request_overide_insmem = 1'b0;
// assign  stop_request_overide_insmem = irq_prep;


assign mret_inst =   (Single_Instruction_stage2 == `inst_MRET);


//MARKER AUTOMATED HERE START

wire [63:0] pipeReg0_wire_debug;
assign pipeReg0_wire_debug[31:0] = pipeReg0[31:0];
assign pipeReg0_wire_debug[`instruct] = instruction_stage_0;
// assign pipeReg0_wire_debug[511:64] = pipeReg1[511:64];

debug # (.Param_delay(5),.regCount(0), .pc_en(1)
                                      ) debug_0 (.i_clk(clk),.pipeReg({448'b0,pipeReg0_wire_debug}), .pc_o(pc_i), .Cycle_count(Cycle_count));
debug # (.Param_delay(10),.regCount(1) ) debug_1 (.i_clk(clk),.pipeReg(pipeReg1));
debug # (.Param_delay(15),.regCount(2) ) debug_2 (.i_clk(clk),.pipeReg(pipeReg2));
debug # (.Param_delay(20),.regCount(3) ) debug_3 (.i_clk(clk),.pipeReg(pipeReg3));

//MARKER AUTOMATED HERE END



    decode #(.N_param(N_param)) decode_debug
    (
   .i_clk(clk),
   .i_en(i_en),
   .instruction(instruction_stage_0),
   .rd_o(rd_o),
   .rs1_o(rs1_o),
    .csr_o(csr_o),

   .rs2_o(rs2_o),
   .fun3_o(fun3_o),
   .fun7_o(fun7_o),
   .imm_o(imm_o),
   .INST_typ_o(INST_typ_o),
   .opcode_o(opcode_o),
   .Single_Instruction_o(Single_Instruction_o)
   );


 reg_file reg_file(
.clk(clk),
.reset(reset), 
.reg1_pi(rs1_o), 
.reg2_pi(rs2_o), 
.destReg_pi(rd_stage3),
.we_pi(write_reg_file_wire_stage3), 
.writeData_pi(writeData_pi), 
.operand1_po(operand1_po),
.operand2_po(operand2_po)


// .write_csr(          write_csr_wire_stage3),
// .csrReg_write_dest_reg(         csr_stage3),
// .csrReg_write_dest_reg_data(csr_val_stage3),

// .csrReg_read_src_reg(csr_o),
// .csrReg_read_src_reg_data(csr_regfile_o)




);

execute  #(.N_param(32)) execute 
    (.i_clk(clk),    
     .Single_Instruction_i(Single_Instruction_stage1),
     .operand1_pi(operand1_into_exec),
     .operand2_pi(operand2_into_exec),
     .csr_op_in(csr_into_exec),
     .instruction(instruction_stage_1),
     .pc_i(pc_stage_1),
     .rd_i(rd_stage1),
     .rs1_i(rs1_stage1), 
     .rs2_i(rs2_stage1), 
     .csr_i(csr_stage1),
     .imm_i(imm_stage1),
     .alu_result_1(alu_result_1),
     .alu_result_2(alu_result_2),
     .branch_inst_wire(branch_inst_wire),
     .jump_inst_wire(jump_inst_wire),
     .write_reg_file_wire(write_reg_file_wire),
     .write_csr_wire(         write_csr_wire)
     
   );





// assign  Pmem_clk          =   Dmem_clk;
// assign  Pmem_data_req_o   =   in_range_peripheral ? Dmem_data_req_o_intermediate  : 0 ;
// assign  Pmem_data_addr_o  =   Dmem_data_addr_o;
// assign  Pmem_data_we_o    =   Dmem_data_we_o;
// assign  Pmem_data_be_o    =   Dmem_data_be_o;
// assign  Pmem_data_wdata_o =   Dmem_data_wdata_o;



// .data_clk(                  Dmem_clk),
// .data_req_o(                Dmem_data_req_o_intermediate),
// .data_addr_o(               Dmem_data_addr_o),
// .data_we_o(                 Dmem_data_we_o),
// .data_be_o(                 Dmem_data_be_o),
// .data_wdata_o(              Dmem_data_wdata_o),
// .data_rdata_i(              Dmem_data_rdata_i),
// .data_rvalid_i(             Dmem_data_rvalid_i),
// .data_gnt_i(                Dmem_data_gnt_i)

wire           data_clk;
wire           data_req_o;
wire [31:0]    data_addr_o;
wire           data_we_o;
wire  [3:0]    data_be_o;
wire [31:0]    data_wdata_o;
wire  [31:0]   data_rdata_i;
wire           data_rvalid_i;
wire           data_gnt_i;

// assign data_clk        = in_range_peripheral  ? Dmem_clk                      : Pmem_clk              ;
// assign data_req_o      = in_range_peripheral  ? Dmem_data_req_o               : Pmem_data_req_o        ;
// assign data_addr_o     = in_range_peripheral  ? Dmem_data_addr_o              : Pmem_data_addr_o      ;
// assign data_we_o       = in_range_peripheral  ? Dmem_data_we_o                : Pmem_data_we_o        ;
// assign data_be_o       = in_range_peripheral  ? Dmem_data_be_o                : Pmem_data_be_o        ;
// assign data_wdata_o    = in_range_peripheral  ? Dmem_data_wdata_o             : Pmem_data_wdata_o     ;



wire in_range_peripheral;
wire data_req_o_intermediate;
// assign Dmem_data_req_o = in_range_peripheral ?  1'b0 : Dmem_data_req_o_intermediate;
// assign  Dmem_data_req_o   =    Dmem_data_req_o_intermediate;
assign  Dmem_data_req_o   =   in_range_peripheral ? 1'b0                     : data_req_o_intermediate;
assign  Pmem_data_req_o   =   in_range_peripheral ? data_req_o_intermediate  : 1'b0 ;


assign Dmem_clk          = data_clk            ; 
// assign Dmem_data_req_o   = data_req_o          ; 
assign Dmem_data_addr_o  = data_addr_o         ; 
assign Dmem_data_we_o    = data_we_o           ; 
assign Dmem_data_be_o    = data_be_o           ; 
assign Dmem_data_wdata_o = data_wdata_o        ; 

assign Pmem_clk          =  data_clk           ;
// assign Pmem_data_req_o   =  data_req_o         ;
assign Pmem_data_addr_o  =  data_addr_o        ;
assign Pmem_data_we_o    =  data_we_o          ;
assign Pmem_data_be_o    =  data_be_o          ;
assign Pmem_data_wdata_o =  data_wdata_o       ;



assign data_rdata_i     = in_range_peripheral  ? Pmem_data_rdata_i             : Dmem_data_rdata_i     ;
assign data_rvalid_i    = in_range_peripheral  ? Pmem_data_rvalid_i            : Dmem_data_rvalid_i    ;
assign data_gnt_i       = in_range_peripheral  ? Pmem_data_gnt_i               : Dmem_data_gnt_i       ;


    // output  wire          Pmem_clk,
    // output wire           Pmem_data_req_o,
    // output wire [31:0]    Pmem_data_addr_o,
    // output wire           Pmem_data_we_o,
    // output wire  [3:0]    Pmem_data_be_o,
    // output wire [31:0]    Pmem_data_wdata_o,
    // input  wire  [31:0]   Pmem_data_rdata_i,
    // input  wire           Pmem_data_rvalid_i,
    // input  wire           Pmem_data_gnt_i,


dataMem dataMem 
  (
.final_value(               final_value),
.clk(                       clk),
.reset(                     reset),
.Single_Instruction(        Single_Instruction_stage2),
.address_i(                 alu_result_1_stage2),
.storeData(                 operand2_stage2),
.pc_i(                      pc_stage_2),
.loadData_w(                loaded_data),
.memory_offset(             memory_offset),
.stall_mem_not_avalible(    stall_mem_not_avalible),
.load_into_reg(             load_into_reg),

.stop_request_overide(      stop_request_overide_datamem),
.reset_able(                reset_able_datamem),
.in_range_peripheral(       in_range_peripheral),


//
.data_clk(         data_clk                     ),
.data_req_o(       data_req_o_intermediate ),
.data_addr_o(      data_addr_o             ),
.data_we_o(        data_we_o               ),
.data_be_o(        data_be_o               ),
.data_wdata_o(     data_wdata_o            ),
.data_rdata_i(     data_rdata_i            ),
.data_rvalid_i(    data_rvalid_i           ),
.data_gnt_i(       data_gnt_i              )
//


);
wire [31:0] csr_into_exec;
hazard hazard (
.clk(clk),
.rs1_stage1(rs1_stage1),
.rs2_stage1(rs2_stage1),
.destination_reg_stage2(rd_stage2),
.write_reg_stage2(write_reg_file_wire_stage2),
.destination_reg_stage3(rd_stage3),
.write_reg_stage3(write_reg_stage3),
.PC_stage1(pc_stage_1), 
.PC_stage2(pc_stage_2), 
.PC_stage3(pc_stage_3),
.rd_result_stage2(rd_result_stage2),
.writeData_pi(writeData_pi),
.operand1_stage1(operand1_stage1),
.operand1_into_exec(operand1_into_exec),
.operand2_into_exec(operand2_into_exec),
.operand2_stage1(operand2_stage1),


.csr_into_exec(csr_into_exec),

.csr_stage1(                               csr_stage1),
.csr_result_stage1(                    csr_val_stage1),

.csr_destination_reg_stage2(               csr_stage2),
.csr_write_reg_stage2(          write_csr_wire_stage2),
.csr_destination_reg_stage3(               csr_stage3),
.csr_write_reg_stage3(          write_csr_wire_stage3),
.csr_memstage_data(                    csr_val_stage2),
.csr_wbstage_data(                     csr_val_stage3)

);


assign pc_stage_0          =        pipeReg0[`PC_reg];
// assign instruction_stage_0 =        pipeReg0[`instruct];
assign instruction_stage_0          =  delete_reg1_reg2_reg ? 32'h00000013 : instruction;
// assign instruction_stage_0 =        instruction; //pipeReg0[`instruct];
assign pc_stage_1 =                 pipeReg1[`PC_reg];
assign instruction_stage_1 =        pipeReg1[`instruct];
assign rd_stage1 =                  pipeReg1[`rd];
assign rs1_stage1 =                 pipeReg1[`opRs1_reg];
assign rs2_stage1 =                 pipeReg1[`opRs2_reg];
assign csr_stage1 =                 pipeReg1[`csr_reg];
assign csr_val_stage1 =             pipeReg1[`csr_reg_val];
assign operand1_stage1 =            pipeReg1[`op1_reg];
assign operand2_stage1 =            pipeReg1[`op2_reg];
assign imm_stage1 =                 pipeReg1[`immediate];
assign Single_Instruction_stage1 =  pipeReg1[`Single_Instruction];


assign pc_stage_2 =                 pipeReg2[`PC_reg];
assign instruction_stage_2 =        pipeReg2[`instruct];
assign rd_stage2 =                  pipeReg2[`rd];
assign rs1_stage2 =                 pipeReg2[`opRs1_reg];
assign rs2_stage2 =                 pipeReg2[`opRs2_reg];
assign csr_stage2 =                 pipeReg2[`csr_reg];
assign csr_val_stage2 =             pipeReg2[`csr_reg_val];
assign operand1_stage2 =            pipeReg2[`op1_reg];
assign operand2_stage2 =            pipeReg2[`op2_reg];
assign imm_stage2 =                 pipeReg2[`immediate];
assign Single_Instruction_stage2 =  pipeReg2[`Single_Instruction];
assign alu_result_1_stage2 =        pipeReg2[`alu_res1          ];
assign alu_result_2_stage2 =        pipeReg2[`alu_res2          ];
assign jump_inst_wire_stage2      = pipeReg2[`jump_en           ];  
assign branch_inst_wire_stage2    = pipeReg2[`branch_en         ];  
assign write_reg_file_wire_stage2 = pipeReg2[`reg_write_en      ];  
assign write_csr_wire_stage2      = pipeReg2[`csr_write_en      ];


wire HELLO;
assign pc_stage_3 =                 pipeReg3[`PC_reg];
assign instruction_stage_3 =        pipeReg3[`instruct];
assign rd_stage3 =                  pipeReg3[`rd];
assign rs1_stage3 =                 pipeReg3[`opRs1_reg];
assign rs2_stage3 =                 pipeReg3[`opRs2_reg];
assign csr_stage3 =                 pipeReg3[`csr_reg];
assign csr_val_stage3 =             pipeReg3[`csr_reg_val];
assign operand1_stage3 =            pipeReg3[`op1_reg];
assign operand2_stage3 =            pipeReg3[`op2_reg];
assign imm_stage3 =                 pipeReg3[`immediate];
assign Single_Instruction_stage3 =  pipeReg3[`Single_Instruction];
assign alu_result_1_stage3 =        pipeReg3[`alu_res1          ];
assign alu_result_2_stage3 =        pipeReg3[`alu_res2          ];
assign write_reg_file_wire_stage3 = pipeReg3[`reg_write_en      ];
assign write_csr_wire_stage3      = pipeReg3[`csr_write_en      ];
assign HELLO      = pipeReg3[`csr_write_en      ];
assign load_into_reg_stage3       = pipeReg3[`load_reg          ];  
assign loaded_data_stage3         = pipeReg3[`data_mem_loaded   ];  


assign pipeReg0_wire[`PC_reg]   = pc_i;
assign pipeReg0_wire[`instruct] = instruction;


assign pipeReg1_wire[`PC_reg            ] = pc_stage_0;
assign pipeReg1_wire[`instruct          ] = instruction_stage_0;
assign pipeReg1_wire[`alu_res1          ] = 0;
assign pipeReg1_wire[`load_reg          ] = 0;
assign pipeReg1_wire[`jump_en           ] = 0;
assign pipeReg1_wire[`branch_en         ] = 0;
assign pipeReg1_wire[`reg_write_en      ] = 0;
assign pipeReg1_wire[`csr_write_en      ] = 0;
assign pipeReg1_wire[`LD_ready          ] = 0;
assign pipeReg1_wire[`SD_ready          ] = 0;
assign pipeReg1_wire[`rd                ] = rd_o;
assign pipeReg1_wire[`operand_amt       ] = 0;
assign pipeReg1_wire[`opRs1_reg         ] = rs1_o;
assign pipeReg1_wire[`opRs2_reg         ] = rs2_o;
assign pipeReg1_wire[`csr_reg           ] = csr_o;
assign pipeReg1_wire[`csr_reg_val       ] = csr_regfile_o;
assign pipeReg1_wire[`op1_reg           ] = operand1_po;
assign pipeReg1_wire[`op2_reg           ] = operand2_po;
assign pipeReg1_wire[`immediate         ] = imm_o;
assign pipeReg1_wire[`alu_res2          ] = 0;
assign pipeReg1_wire[`rd_data           ] = 0;
assign pipeReg1_wire[`Single_Instruction] = Single_Instruction_o;
assign pipeReg1_wire[`data_mem_loaded   ] = 0;



assign pipeReg2_wire[`PC_reg            ] = pc_stage_1;
assign pipeReg2_wire[`instruct          ] = instruction_stage_1;
assign pipeReg2_wire[`alu_res1          ] = alu_result_1;
assign pipeReg2_wire[`load_reg          ] = 0;
assign pipeReg2_wire[`jump_en           ] = jump_inst_wire;
assign pipeReg2_wire[`branch_en         ] = branch_inst_wire;
assign pipeReg2_wire[`reg_write_en      ] = write_reg_file_wire;
assign pipeReg2_wire[`csr_write_en      ] = write_csr_wire;
assign pipeReg2_wire[`LD_ready          ] = 0;
assign pipeReg2_wire[`SD_ready          ] = 0;
assign pipeReg2_wire[`rd                ] = rd_stage1;
assign pipeReg2_wire[`operand_amt       ] = 0;
assign pipeReg2_wire[`opRs1_reg         ] = rs1_stage1;
assign pipeReg2_wire[`opRs2_reg         ] = rs2_stage1;
assign pipeReg2_wire[`csr_reg           ] = csr_stage1;
assign pipeReg2_wire[`csr_reg_val       ] = alu_result_2; 

assign pipeReg2_wire[`op1_reg           ] = operand1_into_exec;
assign pipeReg2_wire[`op2_reg           ] = operand2_into_exec;
assign pipeReg2_wire[`immediate         ] = imm_stage1;
assign pipeReg2_wire[`alu_res2          ] = alu_result_2;
assign pipeReg2_wire[`rd_data           ] = 0;
assign pipeReg2_wire[`Single_Instruction] = Single_Instruction_stage1;
assign pipeReg2_wire[`data_mem_loaded   ] = 0;



assign pipeReg3_wire[`PC_reg            ] = pc_stage_2;
assign pipeReg3_wire[`instruct          ] = instruction_stage_2;
assign pipeReg3_wire[`alu_res1          ] = alu_result_1_stage2;
assign pipeReg3_wire[`load_reg          ] = load_into_reg;
assign pipeReg3_wire[`jump_en           ] = 0;
assign pipeReg3_wire[`branch_en         ] = 0;
assign pipeReg3_wire[`reg_write_en      ] = write_reg_file_wire_stage2;
assign pipeReg3_wire[`csr_write_en      ] = write_csr_wire_stage2;
assign pipeReg3_wire[`LD_ready          ] = 0;
assign pipeReg3_wire[`SD_ready          ] = 0;
assign pipeReg3_wire[`rd                ] = rd_stage2;
assign pipeReg3_wire[`operand_amt       ] = 0;
assign pipeReg3_wire[`opRs1_reg         ] = rs1_stage2;
assign pipeReg3_wire[`opRs2_reg         ] = rs2_stage2;
assign pipeReg3_wire[`csr_reg           ] = csr_stage2;
assign pipeReg3_wire[`csr_reg_val       ] = csr_val_stage2;
assign pipeReg3_wire[`op1_reg           ] = operand1_stage2;
assign pipeReg3_wire[`op2_reg           ] = operand2_stage2;
assign pipeReg3_wire[`immediate         ] = imm_stage2;
assign pipeReg3_wire[`alu_res2          ] = alu_result_2_stage2;
assign pipeReg3_wire[`rd_data           ] = 0;
assign pipeReg3_wire[`Single_Instruction] = Single_Instruction_stage2;
assign pipeReg3_wire[`data_mem_loaded   ] = loaded_data;


assign stage_MEM_done   = ~stall_mem_not_avalible;
assign stage_WB_ready   = 1'b1;
assign stage3_MEM_valid = stage_WB_ready & stage_MEM_done;

assign stage_EXEC_done   = 1'b1;
assign stage_MEM_ready   = stage3_MEM_valid; // 
assign stage2_EXEC_valid = stage_MEM_ready & stage_EXEC_done;
 
assign stage_DECO_done    = ~STALL_ID_not_ready_w;
assign stage_EXEC_ready   = stage2_EXEC_valid; // 
assign stage1_DECO_valid  = stage_EXEC_ready & stage_DECO_done;

assign stage_IF_done      = ~STALL_IF_not_ready_w;
assign stage_DECO_ready   = stage1_DECO_valid; // 
assign stage0_IF_valid    = stage_DECO_ready & stage_IF_done;

//for PC counter 
assign stage_IF_ready   = stage0_IF_valid; // 

always @(posedge clk)begin
if (reset) begin 
    pipeReg0 <= 64'b0;
    pipeReg1 <= 512'b0;
    pipeReg2 <= 512'b0;
	pipeReg3 <= 512'b0;
end else if (enable_design) begin

delete_reg1_reg2_reg <= delete_reg1_reg2;
if  (delete_reg1_reg2) begin 
    pipeReg0 <= 64'b0;
    pipeReg1 <= 512'b0;
    pipeReg2 <= 512'b0;

    if (stage3_MEM_valid) begin      // <-- stage 2 // 
        pipeReg3 <= pipeReg3_wire;  
     end else begin
        pipeReg3 <= pipeReg3;
     end

end else begin 

    if (stage0_IF_valid) begin 
        pipeReg0   <= pipeReg0_wire;
    end 
    // else if (stage_DECO_done) begin 
    //     pipeReg0   <= 512'b0;//pipeReg0;
    // end 
    else begin 
        pipeReg0   <= pipeReg0;
    end

    if (stage1_DECO_valid) begin
        pipeReg1 <= pipeReg1_wire;
    end else if (stage2_EXEC_valid) begin 
        pipeReg1 <= 512'b0;
    end
    // else if (stage_DECO_done) begin 
    //     pipeReg1  <= 512'b0;
    // end 
    else begin 
   // if (pipeReg1[`instruct] != pipeReg1_wire[`instruct] ) begin
        //     pipeReg1 <= pipeReg1_wire; 
        // end else begin 
        //     pipeReg1 <= 512'b0;
        // end
        pipeReg1 <= pipeReg1;
    end

    if (stage2_EXEC_valid) begin
        // if (pipeReg1 !=)
        pipeReg2 <= pipeReg2_wire;     
    end else begin 
        pipeReg2 <= pipeReg2;
    end

    if (stage3_MEM_valid) begin
        pipeReg3 <= pipeReg3_wire;  
    end else begin
        pipeReg3 <= pipeReg3;
    end


end //end else from reset


end //end enable_design

end // end clock
endmodule



module pulse_generator(
    input  wire       clk,
    input wire  [31:0] in,
    output wire [31:0] out
);

reg [31:0] out_r;
reg [31:0] prev_in;
assign out = out_r;
integer i;
  always @(posedge clk) begin
    for (i = 0; i < 32; i = i + 1) begin
        out_r[i]   <= in[i] & ~prev_in[i];
        prev_in[i] <= in[i];

    end
  end
endmodule


module pulse_generator_1bit(
    input  wire       clk,
    input wire  in,
    output wire out
);
reg out_r;
reg prev_in;
assign out = out_r;
integer i;
  always @(posedge clk) begin
    // for (i = 0; i < 32; i = i + 1) begin
        out_r   <= in & ~prev_in;
        prev_in <= in;
    // end
  end
endmodule


module data_mem_bram_wrapper #(  parameter MEM_DEPTH = 1096 ) (
    input  wire         clk,
    input  wire         reset,
    

    // BRAM interface Signals

    output wire        ins_mem_clkb,
    output wire        ins_mem_enb,
    output wire        ins_mem_rstb,
    output wire [3:0 ] ins_mem_web,
    output wire [31:0] ins_mem_addrb,
    output wire [31:0] ins_mem_dinb,
    input  wire        ins_mem_rstb_busy,
    input  wire [31:0] ins_mem_doutb,


    // core Memory interface
    input  wire         ins_data_req_o,     
    input  wire [31:0]  ins_data_addr_o,    
    input  wire         ins_data_we_o,      
    input  wire [3:0]   ins_data_be_o,      
    input  wire [31:0]  ins_data_wdata_o,
    output wire [31:0]  ins_data_rdata_i,   
    output wire         ins_data_rvalid_i,  
    output wire         ins_data_gnt_i      
);

    reg rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
    wire rstb_busy;
    assign ins_data_gnt_i     = ins_data_req_o;
    assign ins_data_rvalid_i  = rvalid_reg;
    // assign ins_data_gnt_i     = rvalid_reg;
    // assign ins_data_rvalid_i  = rvalid_reg_7;
    // assign  bram_web = 4'b0;


  assign ins_mem_clkb      = clk;
  assign ins_mem_enb       = ins_data_req_o;

  // assign enb = data_req_o;
  assign ins_mem_web = ins_data_we_o ? ins_data_be_o: 4'b0;

  assign ins_mem_rstb      = 1'b0;
  // assign ins_mem_web       = 4'b0000;
  assign ins_mem_addrb     = ins_data_addr_o;
  assign ins_mem_dinb      = ins_data_wdata_o;
  // assign ins_mem_rstb_busy = rstb_busy;
  assign ins_data_rdata_i = ins_mem_doutb;

  reg [31:0] cycle_taken;
initial begin
    cycle_taken <= 0;
end

    always @(posedge clk) begin
        if (reset) begin
        rvalid_reg <= 1'b0; rvalid_reg_1 <= 1'b0;  rvalid_reg_2 <= 1'b0;     rvalid_reg_3 <= 1'b0; rvalid_reg_4 <= 1'b0;  rvalid_reg_5 <= 1'b0; rvalid_reg_6 <= 1'b0;  rvalid_reg_7 <= 1'b0;
        end
        else begin
          rvalid_reg   <= ins_data_req_o; rvalid_reg_1 <= rvalid_reg;  rvalid_reg_2 <= rvalid_reg_1; rvalid_reg_3 <= rvalid_reg_2;  rvalid_reg_4 <= rvalid_reg_3; rvalid_reg_5 <= rvalid_reg_4;  rvalid_reg_6 <= rvalid_reg_5; rvalid_reg_7 <= rvalid_reg_6;
        end
    end
endmodule



  //    peripheral
module  peripheral_mem_bram_wrapper #(  parameter MEM_DEPTH = 1096 ) (
    input  wire         clk,
    input  wire         reset,
    

    // BRAM interface Signals

    output wire        ins_mem_clkb,
    output wire        ins_mem_enb,
    output wire        ins_mem_rstb,
    output wire [3:0 ] ins_mem_web,
    output wire [31:0] ins_mem_addrb,
    output wire [31:0] ins_mem_dinb,
    input  wire        ins_mem_rstb_busy,
    input  wire [31:0] ins_mem_doutb,


    // core Memory interface
    input  wire         ins_data_req_o,     
    input  wire [31:0]  ins_data_addr_o,    
    input  wire         ins_data_we_o,      
    input  wire [3:0]   ins_data_be_o,      
    input  wire [31:0]  ins_data_wdata_o,
    output wire [31:0]  ins_data_rdata_i,   
    output wire         ins_data_rvalid_i,  
    output wire         ins_data_gnt_i      
);

    reg rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
    wire rstb_busy;
    assign ins_data_gnt_i     = ins_data_req_o;
    assign ins_data_rvalid_i  = rvalid_reg;
    // assign ins_data_gnt_i     = rvalid_reg;
    // assign ins_data_rvalid_i  = rvalid_reg_6;
    // assign  bram_web = 4'b0;


  assign ins_mem_clkb      = clk;
  assign ins_mem_enb       = ins_data_req_o;

  // assign enb = data_req_o;
  assign ins_mem_web = ins_data_we_o ? ins_data_be_o: 4'b0;

  assign ins_mem_rstb      = 1'b0;
  // assign ins_mem_web       = 4'b0000;
  assign ins_mem_addrb     = ins_data_addr_o;
  assign ins_mem_dinb      = ins_data_wdata_o;
  // assign ins_mem_rstb_busy = rstb_busy;
  assign ins_data_rdata_i = ins_mem_doutb;

  reg [31:0] cycle_taken;
initial begin
    cycle_taken <= 0;
end

    always @(posedge clk) begin
        if (reset) begin
        rvalid_reg <= 1'b0; rvalid_reg_1 <= 1'b0;  rvalid_reg_2 <= 1'b0;     rvalid_reg_3 <= 1'b0; rvalid_reg_4 <= 1'b0;  rvalid_reg_5 <= 1'b0; rvalid_reg_6 <= 1'b0;  rvalid_reg_7 <= 1'b0;
        end
        else begin
          rvalid_reg   <= ins_data_req_o; rvalid_reg_1 <= rvalid_reg;  rvalid_reg_2 <= rvalid_reg_1; rvalid_reg_3 <= rvalid_reg_2;  rvalid_reg_4 <= rvalid_reg_3; rvalid_reg_5 <= rvalid_reg_4;  rvalid_reg_6 <= rvalid_reg_5; rvalid_reg_7 <= rvalid_reg_6;
        end
    end
endmodule



module inst_mem_bram_wrapper #(  parameter MEM_DEPTH = 1096 ) (
    input  wire         clk,
    input  wire         reset,
    

    // BRAM interface Signals

    output wire        ins_mem_clkb,
    output wire        ins_mem_enb,
    output wire        ins_mem_rstb,
    output wire [3:0 ] ins_mem_web,
    output wire [31:0] ins_mem_addrb,
    output wire [31:0] ins_mem_dinb,
    input  wire        ins_mem_rstb_busy,
    input  wire [31:0] ins_mem_doutb,


    // core Memory interface
    input  wire         ins_data_req_o,     
    input  wire [31:0]  ins_data_addr_o,    
    input  wire         ins_data_we_o,      
    input  wire [3:0]   ins_data_be_o,      
    input  wire [31:0]  ins_data_wdata_o,
    output wire [31:0]  ins_data_rdata_i,   
    output wire         ins_data_rvalid_i,  
    output wire         ins_data_gnt_i      
);

    reg rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
    wire rstb_busy;
    assign ins_data_gnt_i     = ins_data_req_o;
    assign ins_data_rvalid_i  = rvalid_reg;
    // assign  bram_web = 4'b0;


  assign ins_mem_clkb      = clk;
  assign ins_mem_enb       = ins_data_req_o;
  assign ins_mem_rstb      = 1'b0;
  assign ins_mem_web       = 4'b0000;
  assign ins_mem_addrb     = ins_data_addr_o;
  assign ins_mem_dinb      = 32'b0;
  // assign ins_mem_rstb_busy = rstb_busy;
  assign ins_data_rdata_i = ins_mem_doutb;

  reg [31:0] cycle_taken;
initial begin
    cycle_taken <= 0;
end



    always @(posedge clk) begin
        if (reset) begin
        rvalid_reg <= 1'b0;
        rvalid_reg_1 <= 1'b0;
        rvalid_reg_2 <= 1'b0;   
        rvalid_reg_3 <= 1'b0;
        rvalid_reg_4 <= 1'b0;
        rvalid_reg_5 <= 1'b0;
        rvalid_reg_6 <= 1'b0;
        rvalid_reg_7 <= 1'b0;
        end
        else begin
          rvalid_reg   <= ins_data_req_o;
          rvalid_reg_1 <= rvalid_reg;
          rvalid_reg_2 <= rvalid_reg_1;
          rvalid_reg_3 <= rvalid_reg_2;
          rvalid_reg_4 <= rvalid_reg_3;
          rvalid_reg_5 <= rvalid_reg_4;
          rvalid_reg_6 <= rvalid_reg_5;
          rvalid_reg_7 <= rvalid_reg_6;
        end
    end
endmodule





module inst_mem_bram_wrapper_test_purpoeses #(  parameter MEM_DEPTH = 1096 ) (
    input  wire         clk,
    input  wire         reset,
    

    // BRAM interface Signals

    output wire        ins_mem_clkb,
    output wire        ins_mem_enb,
    output wire        ins_mem_rstb,
    output wire [3:0 ] ins_mem_web,
    output wire [31:0] ins_mem_addrb,
    output wire [31:0] ins_mem_dinb,
    input  wire        ins_mem_rstb_busy,
    input  wire [31:0] ins_mem_doutb,


    // core Memory interface
    input  wire         ins_data_req_o,     
    input  wire [31:0]  ins_data_addr_o,    
    input  wire         ins_data_we_o,      
    input  wire [3:0]   ins_data_be_o,      
    input  wire [31:0]  ins_data_wdata_o,
    output wire [31:0]  ins_data_rdata_i,   
    output wire         ins_data_rvalid_i,  
    output wire         ins_data_gnt_i      
);

    reg rvalid_reg,rvalid_reg_1,rvalid_reg_2,rvalid_reg_3,rvalid_reg_4,rvalid_reg_5,rvalid_reg_6,rvalid_reg_7;
    wire rstb_busy;
    // assign ins_data_gnt_i     = ins_data_req_o;
    // assign ins_data_rvalid_i  = rvalid_reg_2;
    // assign  bram_web = 4'b0;


wire grant, bram_en,req_done;
// assign ins_data_req_o_w = req_done;
// assign ins_data_req_o =ins_data_req_o_w;
assign ins_data_gnt_i= grant;

  assign ins_mem_clkb      = clk;
  assign ins_mem_enb       = grant;
  assign ins_mem_rstb      = 1'b0;
  assign ins_mem_web       = 4'b0000;
  assign ins_mem_addrb     = ins_data_addr_o;
  assign ins_mem_dinb      = 32'b0;
  // assign ins_mem_rstb_busy = rstb_busy;
  assign ins_data_rdata_i = ins_mem_doutb;

  reg [31:0] cycle_taken;
initial begin
    cycle_taken <= 0;
end

  parameter N = 2;
//   parameter L = 2;
    // assign ins_data_rvalid_i = req_done;

    parameter L = 1; // if you wnat ins_data_rvalid_i to be high after grant imediately
    assign ins_data_rvalid_i = bram_en;//req_done;
  timed_pulse #(
    .N(N),
    .L(L)
  ) dut (
    .clk(clk),
    .reset(reset),
    .ins_data_req_o(ins_data_req_o),
    // .value_o(value_o),
    .grant(grant),
    .req_done(req_done),
    .bram_en(bram_en)
  );





endmodule


module timed_pulse #(
  parameter N = 2, // Number of cycles to capture ins_data_req_o
  parameter L = 3   // Number of cycles to wait after capture
) (
    input  clk,
    input  reset,
    input  ins_data_req_o,
    output reg value_o,
    output wire grant,
    output wire req_done,
    output wire bram_en
);

  reg [31:0] counter,counter_L;
  reg capture_done;
  reg delay_done;
  reg pulse_out;
  reg bram_read;
wire grant_w;
assign req_done = req_done_w;

assign grant = grant_w;
assign grant_w = (counter == (N - 1)) && ins_data_req_o;
wire req_done_w;
assign req_done_w = (counter_L == (L - 1));
assign bram_en = bram_read;

  initial begin 
    bram_read <=0;
  end 
  always @ (posedge clk ) begin 
    if (grant) begin
      bram_read <= 1;
    end else if (bram_read) begin
      bram_read <= 0;
    end

  end 


  always @(posedge clk) begin
    if (reset) begin
      counter       <= 0;
      counter_L       <= 0;
      capture_done  <= 0;
      delay_done    <= 0;
      value_o       <= 0;
      pulse_out     <= 0;
    end else begin
      if(!capture_done)
      begin
            pulse_out <= 0;

        if (ins_data_req_o) begin
          if (counter < N -1) begin
            counter <= counter + 1;
          end else begin
            capture_done <= 1;
            counter <= 0;
           end
        end
      end else begin//if (!delay_done) begin
          if (counter_L < L-1) begin
             counter_L <= counter_L + 1;
          end else begin
            counter_L <= 0;
            capture_done <= 0;
            pulse_out    <= 1;
          end
        // end else begin
        //    pulse_out <= 1;
        // end
    end
  end
  end
//   always @(posedge clk) begin
//     if(reset) begin
//        value_o <= 0;
//     end else begin
//         value_o <= pulse_out;
//         pulse_out <= 0;
//     end
//   end

endmodule

