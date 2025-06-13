module core_controller_fsm (
    input  wire        clk,
    input  wire [31:0] control_signal,        

    input wire    initate_irq,
    input wire    end_condition,

    input wire    all_ready,

    input wire    ready_for_irq_handler,
    input wire    irq_service_done,
    
    input  wire        irq_req_i,          // Interrupt detected
    input  wire [31:0] irq_addr_i,        // Address of interrupt handler
    output wire        irq_grant_o,       // RET from interrupt executed
    output wire  override_all_stop,
    output wire  enable_design,
    output wire  program_finished

);


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
        PARTIAL           = 3'b010,
        IRQ_HANDLE        = 3'b011,
        FULL_FLUSH_RESET  = 3'b100,
        DONE              = 3'b101;



    // control signals
    wire start_program, reset_request, rerset_force;

    assign start_program    = control_signal[0];
    assign reset_request    = control_signal[1];
    assign rerset_force     = control_signal[2];    

    assign enable_design = (state != IDLE);
    assign enable_design = (state != IDLE);


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
                    next_state = PARTIAL;
                end else if (end_condition) begin
                    next_state = DONE;
                end
            end

            PARTIAL: begin
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
                    next_state = IRQ_HANDLE;
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


