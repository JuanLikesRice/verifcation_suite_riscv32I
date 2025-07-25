module core_controller_fsm (
    input  wire        clk,
    input  wire [31:0] control_signal,        

    // input wire    initate_irq,
    input wire    end_condition,

    input wire    all_ready,

    input wire    ready_for_irq_handler,
    
    input  wire        irq_req_i,          // Interrupt detected
    input  wire [31:0] irq_addr_i,        // Address of interrupt handler

    output wire        irq_grant_o,       // RET from interrupt executed
    output wire        irq_prep,         // Acknowledge interrupt request
    output wire [31:0] interrupt_vector_i, // Interrupt vector address


    input wire [31:0] 	nextPC_o,
    input wire [31:0] 	pc_stage_2,
    input wire 		    change_PC_condition_for_jump_or_branch,
    input wire [63:0]   Single_Instruction_stage2,
    input wire          mret_inst,



    output wire  override_all_stop,
    output wire  enable_design,
    output wire  program_finished,

    output wire  [31:0] mepc,

    input  wire        reset,             // Reset signal     

// CSR stuff
input wire          write_csr,
input wire [11:0]   csrReg_write_dest_reg,
input wire [31:0]   csrReg_write_dest_reg_data,
input wire [11:0]   csrReg_read_src_reg,
output wire [31:0]  csrReg_read_src_reg_data,

input wire timer_timeout
);

    wire cntrl_csr;
    reg [31:0] CSR_FILE[0:4096];  // 4096 32-bit registers
    assign cntrl_csr   =  (csrReg_write_dest_reg == csrReg_read_src_reg) &&  write_csr ;
    assign csrReg_read_src_reg_data = cntrl_csr ? csrReg_write_dest_reg_data : CSR_FILE[csrReg_read_src_reg];
    wire [31:0] mtvec,mie, mstatus, mcause,mip,mtval;
    wire    irq_service_done;
    assign irq_service_done = mret_inst;

    // wire mret_inst;
    // wire mret_inst =   (Single_Instruction_stage2 == `inst_MRET);

//CSR signals
assign mstatus      =  CSR_FILE[12'h300];
assign mie          =  CSR_FILE[12'h304];
assign mtvec        =  CSR_FILE[12'h305];

assign mepc         =  CSR_FILE[12'h341];
assign mcause       =  CSR_FILE[12'h342];
assign mtval        =  CSR_FILE[12'h343];
assign mip          =  CSR_FILE[12'h344];

wire mstatus_MPIE;
wire   mie_MTIE;
wire   mip_MTIP;

wire [29:0] mtvec_base;
wire  [1:0] mtvec_mode;
wire        Timmer_enable_interrupt;
wire        initate_irq;
wire [31:0] saved_instruction_mepc;

assign saved_instruction_mepc   = change_PC_condition_for_jump_or_branch ? nextPC_o : pc_stage_2 + 4  ;
assign mstatus_MPIE             = mstatus[3];
assign mie_MTIE                 = mie[7];
assign mip_MTIP                 = mip[7];

assign mtvec_base = mtvec[31:2];
assign mtvec_mode = mtvec[ 1:0];
assign  Timmer_enable_interrupt = mie_MTIE & mstatus_MPIE;

assign  initate_irq        = Timmer_enable_interrupt && timer_timeout;
assign  interrupt_vector_i = {mtvec_base, 2'b00}; // Assuming mtvec_base is aligned to 4 bytes


always @( posedge clk) begin
    if ( (state  == PARTIAL_IRQ) && ready_for_irq_handler) begin 
        CSR_FILE[12'h341] <= saved_instruction_mepc; // mepc
        // CSR_FILE[12'h342] <= 32'b0;     // Clear mcause
        // CSR_FILE[12'h343] <= saved_instruction_mepc;     // Clear mtval
    end 
end



integer j;
integer p;
integer i;
integer o;

initial begin 
    for (p=0; p <4096; p=p+1) begin
                CSR_FILE[p] <= 32'b0;
    end
end

always @(posedge clk) begin
    if (reset) begin 
        for (o=0; o < 4096; o=o+1) begin
            CSR_FILE[o] <= 32'b0;
        end
    end else begin 
        if (write_csr) begin
            CSR_FILE[csrReg_write_dest_reg] <= csrReg_write_dest_reg_data;
        end
    end
end


//MARKER AUTOMATED HERE START
integer k;
integer n;
always @(negedge clk) begin
      #100
    #1
      $write("\n\nCSRs:   ");
      for (k=0; k < 4096; k=k+1) begin 
	  	// REG_FILE[i] <= 32'b0;
      if (CSR_FILE[k] != 0) begin
      $write("   R%4h: %9h,", k, CSR_FILE[k]);
      end
      end
      $write("\nCSRs*:  ");
      for (n=0; n < 4096; n=n+1) begin 
	  	// REG_FILE[i] <= 32'b0;
      if (CSR_FILE[n] != 0) begin
      $write("   R%4h: %9d,", n, $signed(CSR_FILE[n]));
      end
      end
end

    // Internal state register
    reg [2:0] state, next_state;
    // Internal signal registers (assigned to outputs)
    reg global_reset_r, pc_override_r, flush_partial_r, flush_full_r;
    reg csr_swap_context_r, run_irq_handler_r, begin_execution_r, done_flag_r;
    reg [2:0] state_out_r;
    assign program_finished = (state == DONE);
    
    // State register
    always @(posedge clk) begin
        if (rerset_force) begin 
            state <= IDLE;
        end 
        else begin 
            state <= next_state;
        end
    end

    // reg [2:0] next_state;
    localparam [2:0]
        IDLE              = 3'b000,
        PROGRAM           = 3'b001,
        PARTIAL_IRQ       = 3'b010,
        IRQ_HANDLE        = 3'b011,
        FULL_FLUSH_RESET  = 3'b100,
        DONE              = 3'b101;



    // control signals
    wire start_program, reset_request, rerset_force;

    assign start_program    = control_signal[0];
    assign reset_request    = control_signal[1];
    assign rerset_force     = control_signal[2];    

    // assign enable_design    = (state  != IDLE)       && (state  != PARTIAL_IRQ);
    assign enable_design    = (state  != IDLE);
    assign irq_prep         = (state  == PARTIAL_IRQ);
    // assign enable_design = (state != IDLE);

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_program) begin         
                    next_state = PROGRAM;
                end 
            end

            PROGRAM: begin
                if (reset_request) begin 
                    next_state = FULL_FLUSH_RESET;
                end else if (initate_irq) begin
                    next_state = PARTIAL_IRQ;
                end else if (end_condition) begin
                    next_state = DONE;
                end
            end

            PARTIAL_IRQ: begin
                if (reset_request) begin 
                    next_state = FULL_FLUSH_RESET;
                end else if (ready_for_irq_handler) begin
                    next_state = IRQ_HANDLE;
                end 
            end

            IRQ_HANDLE: begin
                if (reset_request) begin 
                    next_state = FULL_FLUSH_RESET;
                end else if (irq_service_done) begin
                    next_state = PROGRAM;
                end 
            end

            FULL_FLUSH_RESET: begin
                if (all_ready) begin 
                         next_state = IDLE;
                end 
            end

            DONE: begin
                if (reset_request) begin 
                    next_state = FULL_FLUSH_RESET;
                end 
            end

            default: begin 
                next_state = IDLE;
            end
        
        endcase
    end



endmodule


