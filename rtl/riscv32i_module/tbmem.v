// RI5CY LSU memory BFM with seed-based latencies.
// Grant is combinational: gnt = grant_window & req & queue_not_full.
// grant_window opens when grant timer hits 0 and closes only on handshake.
// Response countdown begins the cycle AFTER the first handshake in flight.
module ri5cy_lsu_mem_bfm
#(
  parameter MEM_WORDS        = 1024,
  parameter GRANT_MIN_CYC    = 1,
  parameter GRANT_MAX_CYC    = 8,    // N
  parameter RESP_MIN_CYC     = 1,
  parameter RESP_MAX_CYC     = 12,   // J
  parameter OUTSTANDING_MAX  = 32,
  parameter DEBUG            = 1,
  parameter RESET_MEM_PARAM  = 32'h00000000,
  parameter ADDR_OFFSET      = 32'h2000,
  parameter INIT_HEX         = ""
)
(
  input              clk,
  input              rst_n,

  // seed once per run (non-zero). Pulse for 1 cycle.
  input              seed_valid_i,
  input      [31:0]  seed_i,

  // LSU -> BFM
  input              data_req_i,
  input      [31:0]  data_addr_i,
  input              data_we_i,
  input      [3:0]   data_be_i,
  input      [31:0]  data_wdata_i,

  // BFM -> LSU
  output wire        data_gnt_o,     // combinational grant
  output reg         data_rvalid_o,
  output reg [31:0]  data_rdata_o,

  // Correlation (LSU address space)
  output reg [31:0]  gnt_addr_o,
  output reg [31:0]  rvalid_addr_o
);

  // ---------------- Memory ----------------
  reg [31:0] mem [0:MEM_WORDS-1];
  integer i;
  initial begin
    if (INIT_HEX!="") $readmemh(INIT_HEX, mem);
    else for (i=0;i<MEM_WORDS;i=i+1) mem[i]=RESET_MEM_PARAM;
  end

  // ------------- Seeded PRNG ---------------
  reg [31:0] prng;   // xorshift32 state
  reg        seeded;

  function [31:0] xs32; input [31:0] x;
    begin
      xs32 = x ^ (x << 13);
      xs32 = xs32 ^ (xs32 >> 17);
      xs32 = x ^ (x << 5);
    end
  endfunction

  function [31:0] prng_next; input dummy;
    begin prng = xs32(prng); prng_next = prng; end
  endfunction

  function integer map_range; input integer lo, hi; reg [31:0] r; integer span;
    begin
      if (hi<=lo) map_range = lo;
      else begin r = prng_next(1'b0); span = hi - lo + 1; map_range = lo + (r % span); end
    end
  endfunction

  // ---------- Helpers ----------
  function [31:0] write_merge;
    input [31:0] oldw, neww; input [3:0] be; reg [7:0] b0,b1,b2,b3;
    begin
      b0 = be[0]?neww[7:0]   : oldw[7:0];
      b1 = be[1]?neww[15:8]  : oldw[15:8];
      b2 = be[2]?neww[23:16] : oldw[23:16];
      b3 = be[3]?neww[31:24] : oldw[31:24];
      write_merge = {b3,b2,b1,b0};
    end
  endfunction

  // Address offset handling
  wire [31:0] intermediate_data_addr_i;
  wire        sub_condition;
  assign sub_condition             = (data_addr_i > ADDR_OFFSET);
  assign intermediate_data_addr_i  = sub_condition ? (data_addr_i - ADDR_OFFSET) : 32'h0000;
  wire [31:2] addr_word            = intermediate_data_addr_i[31:2];

  // --------- Request/Response queues ---------
  reg [31:0] q_rdata      [0:OUTSTANDING_MAX-1];
  reg [31:0] q_addr_mem   [0:OUTSTANDING_MAX-1];
  reg [31:0] q_addr_lsu   [0:OUTSTANDING_MAX-1];
  reg        q_we         [0:OUTSTANDING_MAX-1];
  integer    q_resp_delay [0:OUTSTANDING_MAX-1];

  integer q_wptr, q_rptr, q_count;
  wire queue_not_full  = (q_count < OUTSTANDING_MAX);
  wire queue_not_empty = (q_count > 0);

  // --------- Grant timing state ---------
  integer grant_cnt;
  reg     grant_armed;     // we are counting down for a pending request
  reg     grant_window;    // "data_gnt_be_high": window open to allow grant

  // Combinational grant and accept
  assign data_gnt_o = grant_window & data_req_i & queue_not_full;
  wire   grant_accept = data_gnt_o;                // handshake event

  // --------- Response timing ---------
  integer resp_cnt;
  reg     resp_load_next;  // start countdown next cycle after first accept

  // ---------------- Seq ----------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_rvalid_o     <= 1'b0;
      data_rdata_o      <= 32'h0;
      gnt_addr_o        <= 32'h0;
      rvalid_addr_o     <= 32'h0;

      prng              <= 32'h1; seeded <= 1'b0;

      q_wptr<=0; q_rptr<=0; q_count<=0;

      grant_cnt   <= 0;
      grant_armed <= 1'b0;
      grant_window<= 1'b0;

      resp_cnt<=0;
      resp_load_next<=1'b0;
    end else begin
      // seed once
      if (seed_valid_i && !seeded) begin
        prng   <= (seed_i==32'h0) ? 32'h1 : seed_i;
        seeded <= 1'b1;
        grant_cnt<=0; grant_armed<=1'b0; grant_window<=1'b0;
        resp_cnt<=0; resp_load_next<=1'b0;
      end

      data_rvalid_o <= 1'b0;

      // ---------------- GRANT FSM ----------------
      // Arm timer when a request appears and we are not already counting or window-open
      if (seeded && data_req_i && !grant_armed && !grant_window && queue_not_full) begin
        grant_cnt   <= map_range(GRANT_MIN_CYC, GRANT_MAX_CYC);
        grant_armed <= 1'b1;
      end

      // If requester withdraws req before accept, cancel the timer and window
      if (!data_req_i) begin
        grant_armed  <= 1'b0;
        grant_window <= 1'b0;
      end

      // Countdown while armed; when it reaches 0, open window (stay open until accept)
      if (grant_armed) begin
        if (grant_cnt > 0) grant_cnt <= grant_cnt - 1;
        if (grant_cnt == 0) begin
          grant_window <= 1'b1;   // allow combinational grant when req_i is high
          grant_armed  <= 1'b0;   // stop the timer
        end
      end

      // On handshake, consume request and close window
      if (grant_accept) begin
        gnt_addr_o <= data_addr_i;

        // Memory side effects and enqueue
        if (addr_word < MEM_WORDS) begin
          if (data_we_i) begin
            mem[addr_word]   <= write_merge(mem[addr_word], data_wdata_i, data_be_i);
            q_rdata[q_wptr]  <= 32'hx;
          end else begin
            q_rdata[q_wptr]  <= mem[addr_word];
          end
        end else begin
          q_rdata[q_wptr]    <= 32'hDEAD_BEEF;
        end

        q_addr_mem[q_wptr]   <= {addr_word,2'b00};
        q_addr_lsu[q_wptr]   <= data_addr_i;
        q_we[q_wptr]         <= data_we_i;
        q_resp_delay[q_wptr] <= map_range(RESP_MIN_CYC, RESP_MAX_CYC);

        q_wptr  <= (q_wptr+1) % OUTSTANDING_MAX;
        q_count <= q_count + 1;

        grant_window <= 1'b0;                 // window consumed

        if (q_count == 0) resp_load_next <= 1'b1;  // first in flight -> start response next cycle
      end

      // ---------------- RESPONSE path ----------------
      if (seeded && queue_not_empty) begin
        if (resp_load_next) begin
          resp_cnt <= q_resp_delay[q_rptr];
          resp_load_next <= 1'b0;
        end else if (resp_cnt == 0) begin
          resp_cnt <= q_resp_delay[q_rptr];
        end else if (resp_cnt == 1) begin
          data_rvalid_o <= 1'b1;
          data_rdata_o  <= q_rdata[q_rptr];
          rvalid_addr_o <= q_addr_lsu[q_rptr];

          q_rptr  <= (q_rptr+1) % OUTSTANDING_MAX;
          q_count <= q_count - 1;

          resp_cnt <= 0;
        end else begin
          resp_cnt <= resp_cnt - 1;
        end
      end else begin
        resp_cnt <= 0;
        resp_load_next <= 1'b0;
      end
    end
  end

  // Protocol check: grant must only occur with req high (by construction)
  always @(posedge clk) begin
    if (data_gnt_o && !data_req_i)
      $error("[%0t] Grant asserted while data_req_i==0 (addr=%h)", $time, gnt_addr_o);
  end

  // ---------------- Debug block ----------------
  generate if (DEBUG) begin : DBG
    integer M,n;
    reg dbg_store_event, dbg_load_event;
    reg [31:0] dbg_addr_s, dbg_data_s;
    reg [31:0] dbg_addr_l, dbg_data_l;

    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        dbg_store_event <= 1'b0; dbg_load_event <= 1'b0;
        dbg_addr_s <= 32'h0; dbg_data_s <= 32'h0;
        dbg_addr_l <= 32'h0; dbg_data_l <= 32'h0;
      end else begin
        if (data_gnt_o && data_we_i) begin
          dbg_store_event <= 1'b1;
          dbg_addr_s <= {addr_word,2'b00};
          dbg_data_s <= write_merge(mem[addr_word], data_wdata_i, data_be_i);
        end
        if (data_rvalid_o && !q_we[q_rptr]) begin
          dbg_load_event <= 1'b1;
          dbg_addr_l <= q_addr_mem[q_rptr];
          dbg_data_l <= data_rdata_o;
        end
      end
    end

    always @(negedge clk) begin
      #1;
      $write("\n\nDATA_MEM:  ");
      for (M=0; M<MEM_WORDS; M=M+1)
        if (mem[M] != 32'h0) $write("   D%4h: %9h,", M*4, mem[M]);

      $write("\nDATA_MEM*: ");
      for (n=0; n<MEM_WORDS; n=n+1)
        if (mem[n] != 32'h0) $write("   D%4h: %9d,", n*4, $signed(mem[n]));

      if (dbg_load_event) begin
        $write("\nDATA LOADED:  D%8h: %8h", dbg_addr_l, dbg_data_l);
        dbg_load_event <= 1'b0;
      end
      if (dbg_store_event) begin
        $write("\nDATA STORED:  D%8h: %8h", dbg_addr_s, dbg_data_s);
        dbg_store_event <= 1'b0;
      end

      $write("\n----------------------------------------------------------------------------------END\n");
    end
  end endgenerate

endmodule
