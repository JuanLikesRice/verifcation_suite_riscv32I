module core_controller_fsm (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        master_reset,       // Hard reset on boot
    input  wire        irq,                // Interrupt detected
    input  wire        ret_from_irq,       // RET from interrupt executed
    input  wire        reset_trigger,      // Soft reset signal
    input  wire        program_done,       // Execution completed
    input  wire        all_ready,          // All pipeline stages ready
    input  wire        fetch_ready,        // Fetch FSM ready
    input  wire        start_program,      // Trigger to begin program

    output wire [2:0]  state_out,          // Debug state output
    output wire        global_reset,       // Reset signal to pipeline
    output wire        pc_override,        // PC override during jumps/interrupts
    output wire        flush_partial,      // Partial pipeline flush
    output wire        flush_full,         // Full pipeline flush
    output wire        csr_swap_context,   // CSR context switching
    output wire        run_irq_handler,    // Enables IRQ logic
    output wire        begin_execution,    // Enables instruction fetch
    output wire        done_flag           // Set when program completes
);

    // FSM state encoding
    localparam [2:0]
        IDLE        = 3'b000,
        PROGRAM     = 3'b001,
        PARTIAL     = 3'b010,
        IRQ_HANDLE  = 3'b011,
        FULL_FLUSH  = 3'b100,
        DONE        = 3'b101;

    // Internal state register
    reg [2:0] state, next_state;

    // Internal signal registers (assigned to outputs)
    reg global_reset_r, pc_override_r, flush_partial_r, flush_full_r;
    reg csr_swap_context_r, run_irq_handler_r, begin_execution_r, done_flag_r;
    reg [2:0] state_out_r;

    // Output assignments
    assign global_reset       = global_reset_r;
    assign pc_override        = pc_override_r;
    assign flush_partial      = flush_partial_r;
    assign flush_full         = flush_full_r;
    assign csr_swap_context   = csr_swap_context_r;
    assign run_irq_handler    = run_irq_handler_r;
    assign begin_execution    = begin_execution_r;
    assign done_flag          = done_flag_r;
    assign state_out          = state_out_r;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || master_reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic and outputs
    always @(*) begin
        // Default assignments
        next_state         = state;
        global_reset_r     = 0;
        pc_override_r      = 0;
        flush_partial_r    = 0;
        flush_full_r       = 0;
        csr_swap_context_r = 0;
        run_irq_handler_r  = 0;
        begin_execution_r  = 0;
        done_flag_r        = 0;
        state_out_r        = state;

        case (state)
            IDLE: begin
                if (start_program)
                    next_state = PROGRAM;
            end

            PROGRAM: begin
                begin_execution_r = 1;
                if (irq)
                    next_state = PARTIAL;
                else if (reset_trigger)
                    next_state = FULL_FLUSH;
                else if (program_done)
                    next_state = DONE;
            end

            PARTIAL: begin
                flush_partial_r    = 1;
                csr_swap_context_r = 1;
                if (fetch_ready)
                    next_state = IRQ_HANDLE;
            end

            IRQ_HANDLE: begin
                run_irq_handler_r = 1;
                if (ret_from_irq)
                    next_state = PROGRAM;
            end

            FULL_FLUSH: begin
                flush_full_r   = 1;
                global_reset_r = 1;
                if (all_ready)
                    next_state = IDLE;
            end

            DONE: begin
                done_flag_r = 1;
                if (master_reset)
                    next_state = IDLE;
            end
        endcase
    end

endmodule
