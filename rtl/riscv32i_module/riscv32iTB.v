`timescale 1ps / 1ps

module riscv32iTB
  #(
    parameter N_param = 32, 
    parameter memory_offset_param = 32'h00000000,
    parameter success_code = 32'hDEADBEEF,
    parameter BRAM1_TBMEM0_PARAM = 0,
   //  parameter BRAM1_TBMEM0_PARAM = 1,
   //  parameter cycles_timeout      = 5000,
    parameter cycles_timeout      = 300000,
   //  parameter debug_param               = 1,
    parameter debug_param               = 0,

    parameter debug_param_vcd           = 0,
   //  parameter debug_param_vcd           = 1,
    parameter dispatch_print            = 0,
    // parameter cycles_timeout = 700,
    parameter initial_pc    = 32'h000021F4
    )
   (

    );
   // localparam ADR_IMEM_START = 32'h00002000;
   // localparam ADR_PMEM_START = 32'h00003800;
   // localparam ADR_DMEM_START = 32'h00004000;
   // localparam ADR_IMEM_SIZE  =         2048;
   // localparam ADR_PMEM_SIZE  =         1024;
   // localparam ADR_DMEM_SIZE  =         2048;

      localparam ADR_IMEM_START = 32'h00002000;
      localparam ADR_PMEM_START = 32'h00004800;
      localparam ADR_DMEM_START = 32'h00005000;

      localparam ADR_IMEM_SIZE  = 8192;
      localparam ADR_PMEM_SIZE  = 2048;
      localparam ADR_DMEM_SIZE  = 16384;


   // glbl glbl ();
   reg	      tb_clk;
   reg	      tb_reset;
   reg [31:0] Cycle_count;
   reg [31:0] initial_pc_i;
   wire [31:0] final_value;
   reg [31:0]  cycle_to_end;
   reg [31:0]  memory_offset;
   // wire [31:0] GPIO0_R0_CH1;
   reg	       enable_design;


   // BRAM PORTS data mem
   wire	       data_mem_clkb;
   wire	       data_mem_enb;
   wire	       data_mem_rstb;
   wire [3:0 ] data_mem_web;
   wire [31:0] data_mem_addrb;
   wire [31:0] data_mem_dinb;
   wire	       data_mem_rstb_busy;
   wire [31:0] data_mem_doutb;


   // BRAM PORTS peripheral mem
   wire	       peripheral_mem_clkb;
   wire	       peripheral_mem_enb;
   wire	       peripheral_mem_rstb;
   wire [3:0 ] peripheral_mem_web;
   wire [31:0] peripheral_mem_addrb;
   wire [31:0] peripheral_mem_dinb;
   wire	       peripheral_mem_rstb_busy;
   wire [31:0] peripheral_mem_doutb;
   wire	       timer_timeout;


   // BRAM ports ins_mem 
   wire	       ins_mem_clkb;
   wire	       ins_mem_enb;
   wire	       ins_mem_rstb;
   wire [3:0 ] ins_mem_web;
   wire [31:0] ins_mem_addrb;
   wire [31:0] ins_mem_dinb;
   wire	       ins_mem_rstb_busy;
   wire [31:0] ins_mem_doutb;

   reg [31:0]  GPIO0_R0_CH1;
   reg [31:0]  GPIO0_R0_CH2;
   reg [31:0]  GPIO0_R1_CH1;
   reg [31:0]  GPIO0_R1_CH2;
   wire	       STOP_sim    ;



   riscv32i_wrap
     // `ifndef GATESIM
     #(     .N_param(N_param),
            .BRAM1_TBMEM0_PARAM(BRAM1_TBMEM0_PARAM),
            .ADR_IMEM_START(ADR_IMEM_START),
            .ADR_PMEM_START(ADR_PMEM_START),
            .ADR_DMEM_START(ADR_DMEM_START),
            .ADR_IMEM_SIZE (ADR_IMEM_SIZE ),
            .ADR_PMEM_SIZE (ADR_PMEM_SIZE ),
            .ADR_DMEM_SIZE (ADR_DMEM_SIZE ),
            .debug_param(debug_param)
	   ) 
   // `endif
   dut (
        .clk(   tb_clk),
        // .reset(tb_reset),
        // .GPIO0_R0_CH1(GPIO0_R0_CH1),
        // .Cycle_count(Cycle_count),
        // .memory_offset(memory_offset),
        // .initial_pc_i(initial_pc_i),
        // .final_value(final_value),

	.GPIO0_R0_CH1(GPIO0_R0_CH1), // control signals
	.GPIO0_R0_CH2(GPIO0_R0_CH2), // memory_offset
	.GPIO0_R1_CH1(GPIO0_R1_CH1), // initial_pc_i
	.GPIO0_R1_CH2(GPIO0_R1_CH2), // success_code
	.STOP_sim    (STOP_sim    ), 


        //bram ports data_mem
        .data_mem_clkb(      data_mem_clkb     ),
        .data_mem_addrb(     data_mem_addrb    ),
        .data_mem_dinb(      data_mem_dinb     ),
        .data_mem_enb(       data_mem_enb      ),
        .data_mem_rstb(      data_mem_rstb     ),
        .data_mem_web(       data_mem_web      ),
        .data_mem_doutb(     data_mem_doutb    ),
        .data_mem_rstb_busy( data_mem_rstb_busy ),



        //bram ports peripheral_mem
        .peripheral_mem_clkb(      peripheral_mem_clkb     ),
        .peripheral_mem_addrb(     peripheral_mem_addrb    ),
        .peripheral_mem_dinb(      peripheral_mem_dinb     ),
        .peripheral_mem_enb(       peripheral_mem_enb      ),
        .peripheral_mem_rstb(      peripheral_mem_rstb     ),
        .peripheral_mem_web(       peripheral_mem_web      ),
        .peripheral_mem_doutb(     peripheral_mem_doutb    ),
        .peripheral_mem_rstb_busy( peripheral_mem_rstb_busy),
        .timer_timeout(            timer_timeout           ), // timer timeout signal

        //bram ports ins_mem
        .ins_mem_clkb(       ins_mem_clkb),
        .ins_mem_enb(        ins_mem_enb),
        .ins_mem_rstb(       ins_mem_rstb),
        .ins_mem_web(        ins_mem_web),
        .ins_mem_addrb(      ins_mem_addrb),
        .ins_mem_dinb(       ins_mem_dinb),
        .ins_mem_rstb_busy(  ins_mem_rstb_busy),
        .ins_mem_doutb(      ins_mem_doutb)

	);


   always begin
      tb_clk = 1'b0;
      #5000;
      tb_clk = 1'b1;
      #5000;
   end

   // initial begin : init
   //     string vcdfile;
   //     int vcdlevel;
   //     if ($value$plusargs("VCDFILE=%s",vcdfile))
   //         $dumpfile(vcdfile);
   //     if ($value$plusargs("VCDLEVEL=%d",vcdlevel))
   //         $dumpvars(vcdlevel);
   //         end
      if (debug_param_vcd) begin 

   initial begin 
      // reg [8*128-1:0] vcdfile;  // A reg-based string: 128 characters
      // integer vcdlevel;
      // if ($value$plusargs("VCDFILE=%s", vcdfile))
      $dumpfile("sim.vcd");
      // if ($value$plusargs("VCDLEVEL=%d", vcdlevel))
      $dumpvars(5); 
   end
   end


   initial begin
      $display("%t: starting stream stimulus", $time);
      $display("%t: TEST PASSED", $time);
      // $finish;
   end
   // Simulation control

   initial begin
      tb_clk = 0;
      GPIO0_R0_CH1 <= 32'b00; // control signals
      GPIO0_R0_CH2 <= memory_offset_param; // memory_offset
      GPIO0_R1_CH1 <= initial_pc; // initial_pc_i
      GPIO0_R1_CH2 <= success_code; // success_code
      repeat (10) @(posedge tb_clk);
      GPIO0_R0_CH1 <= 32'b100; // control signals

      repeat (1)  @(posedge tb_clk);
      #7000
        repeat (10) @(posedge tb_clk);
      GPIO0_R0_CH1 <= 32'b00; // control signals
      repeat (3) @(posedge tb_clk);
      GPIO0_R0_CH1 <= 32'b01; // control signals
      repeat (1) @(posedge tb_clk);

      // HERE CHANGE THIS VALUE TO DERTMINE CLOCK CYCLES
      repeat (cycles_timeout) @(posedge tb_clk);
      	   // $write("\nCycle_count %5d,\n",Cycle_count);

      $display("\n\n\n\n%t: STOP, cycle timeout at Cycle_count %5d,\n", $time,cycles_timeout);
      repeat (1) @(posedge tb_clk);
      repeat (1) @(posedge tb_clk);

      $finish;
   end
   always @(posedge STOP_sim) begin
      $display("\n\n\n\n%t: STOP_sim signal received", $time);
      $finish;
   end 


generate
  if (BRAM1_TBMEM0_PARAM) begin : g_with_bram0
   // BRAM PORTS data mem
   bram_mem #(
      .MEM_DEPTH(    ADR_DMEM_SIZE),
      .ADR_DMEM_START(ADR_DMEM_START),
      .debug_param(debug_param)
      )  
      data_mem_bram (
						.clkb(                  data_mem_clkb     ),
						.addrb_pre_aligned(     data_mem_addrb    ),
						.dinb(                  data_mem_dinb     ),
						.enb(                   data_mem_enb      ),
						.rstb(                  data_mem_rstb     ),
						.web(                   data_mem_web      ),
						.doutb(                 data_mem_doutb    ),
						.rstb_busy(             data_mem_rstb_busy )
						);
  
  
    bram_ins #(
      .MEM_DEPTH(     ADR_IMEM_SIZE),
      .ADR_IMEM_START(ADR_IMEM_START),
      .debug_param(debug_param) 
      ) 
      ins_mem_bram (
					       .clkb(       ins_mem_clkb),
					       .enb(        ins_mem_enb),
					       .rstb(       ins_mem_rstb),
					       .web(        ins_mem_web),
					       .addrb(      ins_mem_addrb),
					       .dinb(       ins_mem_dinb),
					       .rstb_busy(  ins_mem_rstb_busy),
					       .doutb(      ins_mem_doutb) 
					       );
 
   end
endgenerate

   bram_pmem #(
      .MEM_DEPTH(    ADR_PMEM_SIZE),
      .ADR_PMEM_START(ADR_PMEM_START),
      .debug_param(debug_param)
   )  data_pmem_bram (
						  .clkb(                  peripheral_mem_clkb     ),
						  .addrb_pre_aligned(     peripheral_mem_addrb    ),
						  .dinb(                  peripheral_mem_dinb     ),
						  .enb(                   peripheral_mem_enb      ),
						  .rstb(                  peripheral_mem_rstb     ),
						  .web(                   peripheral_mem_web      ),
						  .doutb(                 peripheral_mem_doutb    ),
						  .timer_timeout(         timer_timeout           ), // timer timeout signal
						  .rstb_busy(             peripheral_mem_rstb_busy )
						  );


 


endmodule



module bram_pmem #(  parameter MEM_DEPTH = 1096,    
                     parameter ADR_PMEM_START = 32'h00002600,
                     parameter debug_param = 1     ) (
						   input wire	      clkb,
						   input wire	      enb,
						   input wire	      rstb,
						   input wire [3:0 ]  web,
						   input wire [31:0]  addrb_pre_aligned,
						   input wire [31:0]  dinb,
						   output wire	      timer_timeout,
						   output wire	      rstb_busy,
						   output wire [31:0] doutb
						   );


   assign doutb = doutb_reg;
   assign rstb_busy = 0;
   reg [31:0]							      DMEM [0:MEM_DEPTH-1];
   reg [31:0]							      doutb_reg;
   reg [29:0]							      addrb_word;
   wire [29:0]							      word_address;
   wire [ 1:0]							      byte_address;
   // wire [31:0] addrb_aligned;
   wire [31:0]							      addrb;
   assign addrb = addrb_pre_aligned - ADR_PMEM_START; // memory offset
   // wire sub_condition;
   // assign sub_condition = (addrb > 32'h2000):
   // assign address_translation = sub_condition ? addrb - 32'h2000: 32'h0000;
   // assign word_address = address_translation[31:2];  
   // assign byte_address = address_translation[ 1:0];
   assign word_address = addrb[31:2];  
   assign byte_address = addrb[ 1:0];

   integer							      i;


   initial begin
      // First initialize memory to zero
      // integer i;
      for (i = 0; i < MEM_DEPTH; i = i + 1) begin
	 DMEM[i] = 32'h00000000;
      end
   end


   always @(posedge clkb) begin 
      if (rstb) begin
         for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            DMEM[i] <= 32'h00000000;
         end 
      end
      
   end

   reg [ 3:0] web_reg;  
   reg	      enb_reg;  
   reg [31:0] addrb_reg; 
   reg [31:0] data_in_reg;

   always @(posedge clkb) begin
      web_reg <= web;
      enb_reg <= enb;
      addrb_reg <= addrb;
      data_in_reg <= dinb;  

      if (rstb) begin
	 doutb_reg <= 32'b0;
      end else if (enb) begin
	 if (web != 4'b0000) begin
            if (web[0]) begin DMEM[word_address][ 7: 0]  <=  dinb[ 7: 0];   end 
            if (web[1]) begin DMEM[word_address][15: 8]  <=  dinb[15: 8];   end 
            if (web[2]) begin DMEM[word_address][23:16]  <=  dinb[23:16];   end 
            if (web[3]) begin DMEM[word_address][31:24]  <=  dinb[31:24];   end
	    // end

	    doutb_reg <= {
			  (web[3] ? dinb[31:24] : DMEM[word_address][31:24]),
			  (web[2] ? dinb[23:16] : DMEM[word_address][23:16]),
			  (web[1] ? dinb[15: 8] : DMEM[word_address][15: 8]),
			  (web[0] ? dinb[ 7: 0] : DMEM[word_address][ 7: 0])
			  };
	 end else begin
            doutb_reg <= DMEM[word_address];
	 end
      end
   end
   
if (debug_param == 1) begin 
   integer M,n;
   always @(negedge clkb) begin
      #115
	$write("\n\nPERIPHERAL_MEM:  ");
      for (M=0; M < MEM_DEPTH; M=M+1) begin 
	 if (DMEM[M] != 0) begin
	    // $write("   D%4d: %9h,", M, DMEM[M]);
	    $write("   D%4h: %9h,", M*4, DMEM[M]);
	    // $write("   D%4d: %9h,", M*4, DMEM[M]);
	    // $write("   D%4h: %10h,", M*4, DMEM[M]);
	 end
      end
      $write("\nPERIPHERAL_MEM*: ");
      for (n=0; n < MEM_DEPTH; n=n+1) begin 
	 if (DMEM[n] != 0) begin
	    $write("   D%4h: %9d,", n*4, $signed(DMEM[n]));
	 end
      end
      if (enb_reg) begin
	 if ((web_reg == 0))begin
	    //   $write("\nDATA LOADED:  D%8h: %8d, word in Mem %d",address,loadData,word_address);
	    $write("\nPDATA LOADED:  D%8h: %8h",addrb_reg,doutb_reg);
	 end else begin
	    $write("\nPDATA STORED:  D%8h: %8h",addrb_reg,doutb_reg);
	 end
	 $write("\n----------------------------------------------------------------------------------END\n");

      end
   end 
end

   wire [31:0] timer_val,timer_cmp;


   always @(posedge clkb) begin 
      DMEM[32'h40] <= DMEM[32'h40] + 1;
      if (timer_timeout) begin 
	 DMEM[32'h42] <= 32'h00000000; // reset timer cmp
      end
   end


   assign timer_val = DMEM[32'h40] ; // timer value
   assign timer_cmp = DMEM[32'h42] ; // timer value

   assign timer_timeout   = (timer_val >= timer_cmp) && (DMEM[32'h42] != 0);
   // assign timer_timeout_a = (timer_val >= timer_cmp);
   


endmodule



  
module bram_mem #(   parameter MEM_DEPTH = 1096,  
                     parameter ADR_DMEM_START = 32'h00002600,
                     parameter debug_param = 1 ) 
                     (
						  input wire	     clkb,
						  input wire	     enb,
						  input wire	     rstb,
						  input wire [3:0 ]  web,
						  input wire [31:0]  addrb_pre_aligned,
						  input wire [31:0]  dinb,
						  output wire	     rstb_busy,
						  output wire [31:0] doutb
						  );


   assign doutb = doutb_reg;
   assign rstb_busy = 0;
   reg [31:0]							     DMEM [0:MEM_DEPTH-1];
   reg [31:0]							     doutb_reg;
   reg [29:0]							     addrb_word;
   wire [29:0]							     word_address;
   wire [ 1:0]							     byte_address;
   // wire [31:0] addrb_aligned;
   wire [31:0]							     addrb;
   assign addrb = addrb_pre_aligned - ADR_DMEM_START; // memory offset

   // wire sub_condition;
   // assign sub_condition = (addrb > 32'h2000):
   // assign address_translation = sub_condition ? addrb - 32'h2000: 32'h0000;
   // assign word_address = address_translation[31:2];  
   // assign byte_address = address_translation[ 1:0];

   assign word_address = addrb[31:2];  
   assign byte_address = addrb[ 1:0];

   integer							     i;


   initial begin
      // First initialize memory to zero
      // integer i;
      for (i = 0; i < MEM_DEPTH; i = i + 1) begin
	 DMEM[i] = 32'h00000000;
      end
   end


   always @(posedge clkb) begin 
      if (rstb) begin
         for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            DMEM[i] <= 32'h00000000;
         end 
      end
      
   end

   reg [ 3:0] web_reg;  
   reg	      enb_reg;  
   reg [31:0] addrb_reg; 
   reg [31:0] data_in_reg;

   always @(posedge clkb) begin
      web_reg <= web;
      enb_reg <= enb;
      addrb_reg <= addrb;
      data_in_reg <= dinb;  

      if (rstb) begin
	 doutb_reg <= 32'b0;
      end else if (enb) begin
	 if (web != 4'b0000) begin
            if (web[0]) begin DMEM[word_address][ 7: 0]  <=  dinb[ 7: 0];   end 
            if (web[1]) begin DMEM[word_address][15: 8]  <=  dinb[15: 8];   end 
            if (web[2]) begin DMEM[word_address][23:16]  <=  dinb[23:16];   end 
            if (web[3]) begin DMEM[word_address][31:24]  <=  dinb[31:24];   end
	    // end

	    doutb_reg <= {
			  (web[3] ? dinb[31:24] : DMEM[word_address][31:24]),
			  (web[2] ? dinb[23:16] : DMEM[word_address][23:16]),
			  (web[1] ? dinb[15: 8] : DMEM[word_address][15: 8]),
			  (web[0] ? dinb[ 7: 0] : DMEM[word_address][ 7: 0])
			  };
	 end else begin
            doutb_reg <= DMEM[word_address];
	 end
      end
   end
   
if (debug_param == 1) begin 
   integer M,n;
   always @(negedge clkb) begin
      #120
	$write("\n\nDATA_MEM:  ");
      for (M=0; M < MEM_DEPTH; M=M+1) begin 
	 if (DMEM[M] != 0) begin
	    // $write("   D%4d: %9h,", M, DMEM[M]);
	    $write("   D%4h: %9h,", M*4, DMEM[M]);
	    // $write("   D%4d: %9h,", M*4, DMEM[M]);
	    // $write("   D%4h: %10h,", M*4, DMEM[M]);
	 end
      end
      $write("\nDATA_MEM*: ");
      for (n=0; n < MEM_DEPTH; n=n+1) begin 
	 if (DMEM[n] != 0) begin
	    $write("   D%4h: %9d,", n*4, $signed(DMEM[n]));
	 end
      end
      if (enb_reg) begin
	 if ((web_reg == 0))begin
	    //   $write("\nDATA LOADED:  D%8h: %8d, word in Mem %d",address,loadData,word_address);
	    $write("\nDATA LOADED:  D%8h: %8h",addrb_reg,doutb_reg);
	 end else begin
	    $write("\nDATA STORED:  D%8h: %8h",addrb_reg,doutb_reg);
	 end
	 $write("\n----------------------------------------------------------------------------------END\n");

      end
   end 
end

endmodule




module bram_ins #(  parameter MEM_DEPTH = 1096,      
                    parameter ADR_IMEM_START = 32'h00002000,
                     parameter debug_param = 1 ) (
						  input wire	     clkb,
						  input wire	     enb,
						  input wire	     rstb,
						  input wire [3:0 ]  web,
						  input wire [31:0]  addrb,
						  input wire [31:0]  dinb,
						  output wire	     rstb_busy,
						  output wire [31:0] doutb
						  );

   assign doutb = doutb_reg;
   assign rstb_busy = 0;
   reg [31:0]							     DMEM [0:MEM_DEPTH-1];
   reg [31:0]							     doutb_reg;
   reg [29:0]							     addrb_word;
   wire [29:0]							     word_address;
   wire [ 1:0]							     byte_address;

   wire [31:0] address_translation;
   wire sub_condition;
   assign sub_condition = (addrb > ADR_IMEM_START);
   assign address_translation = sub_condition ? (addrb - ADR_IMEM_START): 32'h0000;
   assign word_address = address_translation[31:2];  
   assign byte_address = address_translation[ 1:0];

   integer							     i;


   initial begin
      // First initialize memory to zero
      // integer i;
      for (i = 0; i < MEM_DEPTH; i = i + 1) begin
	 DMEM[i] = 32'h00000013;
      end
      // $readmemh("sanity.hex", memory);  // Load the program into memory
      // $readmemh("program.hex", DMEM);  
      $readmemh("out.hex", DMEM);  
   end


   always @(posedge clkb) begin 
      if (rstb) begin
         for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            DMEM[i] <= 32'h00000013;
         end 
      end
      
   end


   always @(posedge clkb) begin
      if (rstb) begin
	 doutb_reg <= 32'b0;
      end else if (enb) begin
	 if (web != 4'b0000) begin
            if (web[0]) begin DMEM[word_address][ 7: 0]  <=  dinb[ 7: 0];   end 
            if (web[1]) begin DMEM[word_address][15: 8]  <=  dinb[15: 8];   end 
            if (web[2]) begin DMEM[word_address][23:16]  <=  dinb[23:16];   end 
            if (web[3]) begin DMEM[word_address][31:24]  <=  dinb[31:24];   end 
	    doutb_reg <= {
			  (web[3] ? dinb[31:24] : DMEM[word_address][31:24]),
			  (web[2] ? dinb[23:16] : DMEM[word_address][23:16]),
			  (web[1] ? dinb[15: 8] : DMEM[word_address][15: 8]),
			  (web[0] ? dinb[ 7: 0] : DMEM[word_address][ 7: 0])
			  };
	 end else begin
            doutb_reg <= DMEM[word_address];
	 end
      end
   end

endmodule

