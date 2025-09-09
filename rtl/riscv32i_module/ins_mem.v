module ins_mem (
		input wire	                  clk,
		input wire	                  reset,
      // From PC  
		input  wire [`size_X_LEN-1:0]  pc_i,
		output wire [`size_X_LEN-1:0]  pc_o,
		input wire	                  pc_i_valid, // request valid from PC
      // to PC
		output wire	                  STALL_FETCH,    // stall signal for IF stage (PC module is stalled)
		input  wire	                  STALL_DECODE,   // stall signal for DECO stage (Decode module is stalled, exec doesnt get new value)

      output wire [`size_X_LEN-1:0] instruction_o_w,        // final instruction
		// input wire	                  STALL_DECODE,           // stall from Decond 
		input wire	                  abort_rvalid,           // Abort from FSM reset, Jump, valid etc
		input wire	                  stop_request_overide,   
		output wire	                  reset_able, 
      input wire                    enable_design,
      output wire                   instruction_valid,            

		// Memory interface
		output wire	                  data_clk,
		output wire	                  data_req_o_w,
		output wire [`size_X_LEN-1:0] data_addr_o_w,
		output wire	                  data_we_o_w,
		output wire [3:0]             data_be_o_w,
		output wire [`size_X_LEN-1:0] data_wdata_o_w,
		input wire [`size_X_LEN-1:0]  data_rdata_i,
		input wire	                  data_rvalid_i,
		input wire	                  data_gnt_i
		);
   assign data_clk = clk; // Memory clock is the same as the system clock
   reg				         data_req_o;
   reg [`size_X_LEN-1:0]   data_addr_o;
   reg				         data_we_o;
   reg [3:0]			      data_be_o;
   reg [`size_X_LEN-1:0]   data_wdata_o;
   reg				         STALL_FETCH_REG;
   reg [`size_X_LEN-1:0]   instruction_o;

   localparam [1:0]		   S_IDLE         = 2'b00, // Accepts new requests from PC 
				               S_WAIT_GNT     = 2'b01, // Waiting for request to be taken by memory (recognized by mem), no new request from PC 
				               S_WAIT_RVALID  = 2'b10, // waiting for request to be satsisfied, if satsitisfied can accept new request from PC
				               S_ABORT_RVALID = 2'b11; // waiting for request to be satsisfied which is thrown away since aborted,
   // if satsitisfied can accept new request from PC

   reg [1:0]			               current_state, next_state;
   reg [`size_X_LEN-1:0]			   pc_decode;
   reg [`size_X_LEN-1:0]			   current_PC_wating_rvalid, instruction_o_backup;
   reg [`size_X_LEN-1:0]			   PC_requested;
   assign pc_o = PC_requested;

   wire				                  backup_used;
   wire				                  accept_PC_req;
   reg                              saved_instruction_from_stall;


      // Outputs changed in FSM
      // instruction_o 
      // data_req_o    // request send to mem
      // data_addr_o   // address 
      // STALL_FET,k

   assign data_we_o_w         =   `size_X_LEN'b0;     // We are not writing data, so this is always 0
   assign data_be_o_w         =   4'b1111;            // We always want the entire word;
   assign data_wdata_o_w      =   `size_X_LEN'b0;     // We are not writing data, so this is always 0
   assign data_req_o_w        =   data_req_o;
   assign data_addr_o_w       =   data_addr_o;
   // assign STALL_FETCH         =   STALL_FETCH_REG || backup_used ;
   assign STALL_FETCH         =   STALL_FETCH_REG ;

   assign instruction_o_w     = saved_instruction_from_stall ? instruction_o_backup : instruction_o; // Default instruction if reset is high
   assign accept_PC_req       =  pc_i_valid &&  (~abort_rvalid) && ~saved_instruction_from_stall;
   assign backup_used         =  (~STALL_DECODE && saved_instruction_from_stall && enable_design);
   assign reset_able          =  (current_state == S_IDLE);// && ~accept_PC_req; // Reset is not able if stop_request_overide is high
   assign instruction_valid   = (((current_state==S_WAIT_RVALID) && (data_rvalid_i)) || backup_used) && ~abort_rvalid;// either valid if request is done OR BACKUP is being used

   always @(posedge clk) begin
      if (reset) begin
         current_state        <= S_IDLE;
         instruction_o_backup  = 32'h00000013;
         // prev_cycle_stall_i   <= 1'b0; 
         PC_requested         <= 32'h0;
         saved_instruction_from_stall <= 1'b0; 
      end else begin 
         current_state <= next_state; // Update the state


         if (abort_rvalid) begin  
            instruction_o_backup         <= 32'h00000013;
            saved_instruction_from_stall <= 1'b0;   
            PC_requested                 <= 32'hFFFFFFFF;       
         end else begin
            
         if (data_gnt_i) begin 
            PC_requested <= pc_i;//data_rvalid_i 
         end
         case(current_state)
           S_WAIT_RVALID: begin
              if (data_rvalid_i && (STALL_DECODE||~enable_design)) begin 
                 instruction_o_backup         <= data_rdata_i; // Store the requested PC   
                 saved_instruction_from_stall <= 1'b1; // Store the requested PC   
              end
           end
         endcase  
         if (backup_used) begin 
            PC_requested                 <= 32'hFFFFFFFF; //data_rvalid_i 
            instruction_o_backup         <= 32'h00000013;
            saved_instruction_from_stall <= 1'b0; 
         end 	 
      end
      end
   end

   always @(*) begin
      case (current_state)
         S_IDLE: begin // can service a new request, thus branch nor stall will affect output
            instruction_o    = 32'h00000013;
            if (accept_PC_req) begin   // begin new request 
               data_req_o             = 1'b1;        
               data_addr_o            = pc_i;
               if (data_gnt_i) begin      // gnt recognized, meaning request recognized
                  STALL_FETCH_REG     = 1'b0;
                  next_state          = S_WAIT_RVALID;
               end else begin                   // gnt NOT recognized, meaning request must wait for being granted
                  STALL_FETCH_REG     = 1'b1;   // STALL the PC module, to wait for the gnt
                  next_state          = S_WAIT_GNT;
               end 
            end else begin  // IDLE bc no new request If there is a branch or jump, then the request is trashed
               STALL_FETCH_REG       = 1'b1;
               data_req_o            = 1'b0;        
               data_addr_o           = `size_X_LEN'b0;  
               next_state            = S_IDLE;
            end
         end

         S_WAIT_GNT: begin // request is being  // Fetch  is active, its waiting for gnt // DECODE is not Active
            instruction_o   = 32'h00000013;
            if (abort_rvalid) begin // accpet another request after granting
               data_req_o                  = 1'b0;
               STALL_FETCH_REG             = 1'b0;
               data_addr_o                 = 32'h0;
               next_state                  = S_IDLE; // no more request, no more wait for gnt
            end else begin // Jump or banch, meaning that current request is trashed
                  data_req_o               = 1'b1;
                  data_addr_o              = pc_i; // PC has not changed, use it
                  if (data_gnt_i) begin 
                     STALL_FETCH_REG       = 1'b0;
                     next_state            = S_WAIT_RVALID; // waits for rvalid meaning request done, no more stalling
                  end else begin 
                     STALL_FETCH_REG       = 1'b1;
                     next_state            = S_WAIT_GNT;    // wait for gnt again
                  end
            end 
         end  // end S_WAIT_GNT


         S_WAIT_RVALID: begin // NEW 
            if (data_rvalid_i) begin
               instruction_o = data_rdata_i; // instruction gained!
               if ((accept_PC_req && ~STALL_DECODE)) begin // STALL_DECODE
                     data_req_o              = 1'b1;        
                     data_addr_o             = pc_i;        
                     if (data_gnt_i) begin
                        STALL_FETCH_REG      = 1'b0;
                        next_state           = S_WAIT_RVALID;
                     end else begin          // new request but no gnt recognized
                        STALL_FETCH_REG      = 1'b1;
                        next_state           = S_WAIT_GNT;
                     end 
               end else begin  // Valid but no new request
                  data_req_o               =  1'b0;        
                  data_addr_o              =  32'h0;  
                  STALL_FETCH_REG          =  1'b1;
                  next_state               =  S_IDLE;
               end 
            end else begin // rvalid not satisfied
               instruction_o               = 32'h00000013;
               data_req_o                  = 1'b0;
               data_addr_o                 = pc_i;        
               STALL_FETCH_REG             = 1'b1;
               if (abort_rvalid) begin   
                  next_state               = S_ABORT_RVALID; // waiting
               end else begin 
                  next_state               = S_WAIT_RVALID;
               end 
            end
         end

         S_ABORT_RVALID: begin
            instruction_o               = 32'h00000013;  // Cant service new request, so you dont care about the instruction
            if (data_rvalid_i) begin    // request satisfied but thrown away can recive new request from PC
               if (pc_i_valid) begin                      // begin new request // Fetch  is active // DECODE is not Active
                  data_req_o         = 1'b1;        
                  data_addr_o        = pc_i;
                  if (data_gnt_i) begin // gnt recognized, meaning request recognized
                     STALL_FETCH_REG = 1'b0;
                     next_state         = S_WAIT_RVALID;
                  end else begin       // gnt NOT recognized, meaning request must wait for being granted
                     STALL_FETCH_REG       = 1'b1; // STALL the PC module, to wait for the gnt
                     next_state               = S_WAIT_GNT;
                  end 
               end else begin  // IDLE bc no new request
                  data_req_o          = 1'b0;        
                  data_addr_o         = `size_X_LEN'b0;  
                  STALL_FETCH_REG  = 1'b0;
                  next_state          = S_IDLE;
               end
            end else begin// still awaiting rvalid to throw away
               data_req_o                  =  1'b0;
               data_addr_o                 = 32'h0;
               STALL_FETCH_REG          =  1'b1;
               next_state               = S_ABORT_RVALID; // Now I gotta wait for new request
            end
         end

        default: begin
            data_req_o               =  1'b0;
            data_addr_o              = 32'h0;
            STALL_FETCH_REG          =  1'b0;
            instruction_o            = 32'h00000013;
            next_state               = S_IDLE;
        end
      endcase
   end
   

endmodule
