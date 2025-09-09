// Verilog-2005 RI5CY LSU memory BFM with seed-driven per-request latencies.
module ri5cy_lsu_mem_bfm
#(
  parameter MEM_WORDS      = 1024,
  parameter GRANT_MIN_CYC  = 1,   // inclusive
  parameter GRANT_MAX_CYC  = 8,   // N
  parameter RESP_MIN_CYC   = 1,   // inclusive
  parameter RESP_MAX_CYC   = 12,  // J
  parameter OUTSTANDING_MAX= 32,
  parameter INIT_HEX       = "",
  parameter seed_i         = 32'h2975bc21
  
)
(
  input              clk,
  input              rst_n,

  // seed once per run (non-zero). Pulse seed_valid_i for 1 cycle.
  input              seed_valid_i,
  input      [31:0]  seed_i,

  // LSU -> BFM
  input              data_req_i,
  input      [31:0]  data_addr_i,
  input              data_we_i,
  input      [3:0]   data_be_i,
  input      [31:0]  data_wdata_i,

  // BFM -> LSU
  output reg         data_gnt_o,
  output reg         data_rvalid_o,
  output reg [31:0]  data_rdata_o
);


  reg [31:0] mem [0:MEM_WORDS-1];
  integer i;
  initial begin
    if (INIT_HEX!="") $readmemh(INIT_HEX, mem);
    else for (i=0;i<MEM_WORDS;i=i+1) mem[i]=32'h00000000;
  end

  // ------------- Seeded PRNG ---------------
  reg [31:0] prng;   // xorshift32 state
  reg        seeded;

  function [31:0] xs32;
    input [31:0] x;
    begin
      xs32 = x ^ (x << 13);
      xs32 = xs32 ^ (xs32 >> 17);
      xs32 = xs32 ^ (xs32 << 5);
    end
  endfunction

  function [31:0] prng_next;
    begin
      prng      = xs32(prng);
      prng_next = prng;
    end
  endfunction

  function integer map_range; // inclusive
    input integer lo, hi;
    reg [31:0] r; integer span;
    begin
      if (hi<=lo) map_range = lo;
      else begin
        r    = prng_next();
        span = hi - lo + 1;
        map_range = lo + (r % span);
      end
    end
  endfunction

  // ---------- Helpers ----------
  function [31:0] write_merge;
    input [31:0] oldw, neww; input [3:0] be;
    reg [7:0] b0,b1,b2,b3;
    begin
      b0 = be[0]?neww[7:0]   : oldw[7:0];
      b1 = be[1]?neww[15:8]  : oldw[15:8];
      b2 = be[2]?neww[23:16] : oldw[23:16];
      b3 = be[3]?neww[31:24] : oldw[31:24];
      write_merge = {b3,b2,b1,b0};
    end
  endfunction

  wire [31:2] addr_word = data_addr_i[31:2];

  // --------- Request/Response queues ---------
  reg [31:0] q_rdata [0:OUTSTANDING_MAX-1];
  integer    q_resp_delay [0:OUTSTANDING_MAX-1];
  integer q_wptr, q_rptr, q_count;
  wire queue_not_full  = (q_count < OUTSTANDING_MAX);
  wire queue_not_empty = (q_count > 0);

  // Grant delay counts only while a request is pending (per-request)
  integer grant_cnt;
  reg     grant_armed;  // set when we first see a pending request and we have loaded a delay

  // Response delay counter counts continuously toward next completion only when queue_not_empty
  integer resp_cnt;

  // ---------------- Seq ----------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_gnt_o    <= 1'b0;
      data_rvalid_o <= 1'b0;
      data_rdata_o  <= 32'h0;

      prng   <= 32'h1;
      seeded <= 1'b0;

      q_wptr<=0; q_rptr<=0; q_count<=0;

      grant_cnt  <= 0;
      grant_armed<= 1'b0;
      resp_cnt   <= 0;
    end else begin
      // seed once
      if (seed_valid_i && !seeded) begin
        prng   <= (seed_i==32'h0) ? 32'h1 : seed_i;
        seeded <= 1'b1;
        grant_cnt   <= 0;        // force reload on first request
        grant_armed <= 1'b0;
        resp_cnt    <= 0;        // will be set when first req is accepted
      end

      data_gnt_o    <= 1'b0;
      data_rvalid_o <= 1'b0;

      // ---------------- GRANT path ----------------
      // Load a fresh grant delay the moment a new pending request is observed.
      if (seeded && data_req_i && !grant_armed && queue_not_full) begin
        grant_cnt   <= map_range(GRANT_MIN_CYC, GRANT_MAX_CYC);
        grant_armed <= 1'b1;
      end

      // Only count grant delay while request is asserted (per protocol req stays high until grant).
      if (seeded && data_req_i && grant_armed) begin
        if (grant_cnt <= 0) begin
          // Accept request now
          data_gnt_o <= 1'b1;
          if (addr_word < MEM_WORDS) begin
            if (data_we_i) begin
              mem[addr_word] <= write_merge(mem[addr_word], data_wdata_i, data_be_i);
              q_rdata[q_wptr] <= 32'hx; // don't care for write
            end else begin
              q_rdata[q_wptr] <= mem[addr_word];
            end
          end else begin
            q_rdata[q_wptr] <= 32'hDEAD_BEEF;
          end

          // Store per-request response delay now
          q_resp_delay[q_wptr] <= map_range(RESP_MIN_CYC, RESP_MAX_CYC);

          q_wptr  <= (q_wptr+1) % OUTSTANDING_MAX;
          q_count <= q_count + 1;

          // Prepare for the *next* request: re-arm and load a new grant delay only when that next request is pending.
          grant_armed <= 1'b0;
        end else begin
          grant_cnt <= grant_cnt - 1;
        end
      end

      // ---------------- RESPONSE path ----------------
      if (seeded && queue_not_empty) begin
        // Initialize resp_cnt for the head if just became non-empty or after a pop
        if (resp_cnt < 0) resp_cnt <= 0;

        if (resp_cnt == 0) begin
          // Count-down not started for head: load its stored delay
          resp_cnt <= q_resp_delay[q_rptr];
        end else if (resp_cnt == 1) begin
          // Fire response now
          data_rvalid_o <= 1'b1;
          data_rdata_o  <= q_rdata[q_rptr];

          // Pop queue
          q_rptr  <= (q_rptr+1) % OUTSTANDING_MAX;
          q_count <= q_count - 1;

          // Reset resp_cnt so next head will load its own stored delay next cycle
          resp_cnt <= 0;
        end else begin
          resp_cnt <= resp_cnt - 1;
        end
      end else begin
        // No pending responses
        resp_cnt <= 0;
      end
    end
  end

endmodule
