module dataMem #(  parameter mem_size = 131072 ) (
input wire clk,
input wire reset, 
// input wire load, 
// input wire store,  
input wire [63:0] Single_Instruction,
input wire [31:0] address,
input wire [31:0] storeData, 
output wire  [31:0] loadData_w
);
// reg [31:0] 	  DMEM [0:mem_size-1];
// wire [14:0]   word_address;
// assign  word_address = address_pi &  32'h1F;   
// assign  loadData_po = load_pi ? DMEM[word_address] : 32'b0; 
// integer   i;
//    always @(posedge clk_pi) begin
//       if (reset_pi)
// 	for (i=0; i < 32; i = i+1)
// 	  DMEM[i] <= 100+i;
//       else
// 	    if (store_pi)   
// 		       DMEM[word_address] <=  storeData_pi;	
// 	      end
// //    always @(negedge clk_pi)  begin
// //      $display("DMEM[5..9]:\tTime:%3d\t%3d\t%3d\t%3d\t%3d\t%3d", $time, DMEM[5], DMEM[6], DMEM[7], DMEM[8], DMEM[9]);
// //      $display("DMEM[10..14]:\tTime:%3d\t%3d\t%3d\t%3d\t%3d\t%3d", $time, DMEM[10], DMEM[11], DMEM[12], DMEM[13], DMEM[14]);
// //       end
// endmodule	       




// module dataMem #(
//     parameter mem_size = 131072 // 0.5 MB / 4 bytes per word
// ) (
//     input wire clk,
//     input wire reset,
//     input wire load,
//     input wire store,
//     input wire [63:0] Single_Instruction, // Instruction input
//     input wire [31:0] address,            // Address input
//     input wire [31:0] storeData,          // Data to be stored
//     output reg [31:0] loadData           // Data to be loaded
// );

    reg  [31:0] DMEM [0:mem_size-1];
    wire [16:0] word_address;
    wire [ 1:0] byte_address;
    reg  [ 3:0] load_wire;
    reg  [ 3:0] store_wire;
    wire [31:0] raw_word;
    reg [31:0] loadData;           // Data to be loaded


    assign word_address = address[16:2];  
    assign byte_address = address[ 1:0];
    assign raw_word = DMEM[word_address];
    assign loadData_w = loadData;


always @(*) begin
    case(Single_Instruction)
        {inst_LB    }:begin  // one byte
            load_wire  <= 1'b1;
            store_wire <= 1'b0;
            // loadData   <= DMEM[word_address];
            loadData = {{24{DMEM[word_address][(address[1:0] * 8) + 7]}}, DMEM[word_address][(address[1:0] * 8) +: 8]};
        end
        {inst_LH    }:begin // load Half
            load_wire  <= 1'b1;
            store_wire <= 1'b0;
            // loadData   <= DMEM[word_address];
            loadData = {{16{DMEM[word_address][(address[1] * 16) + 15]}}, DMEM[word_address][(address[1] * 16) +: 16]};
        end
        {inst_LW    }:begin // load word
            load_wire  <= 1'b1;
            store_wire <= 1'b0;
            loadData   <= DMEM[word_address];

        end
        {inst_LBU   }:begin 
            load_wire  <= 1'b1;
            store_wire <= 1'b0;
            // loadData   <= DMEM[word_address];
            loadData = {24'b0, DMEM[word_address][(address[1:0] * 8) +: 8]};
        end
        {inst_LHU   }:begin 
            load_wire  <= 1'b1;
            store_wire <= 1'b0;
            // loadData   <= DMEM[word_address];
            loadData = {16'b0, DMEM[word_address][(address[1] * 16) +: 16]};
        end
        {inst_SB    }:begin
            load_wire  <= 1'b0;
            store_wire <= 1'b1;
        end
        {inst_SH    }:begin
            load_wire  <= 1'b0;
            store_wire <= 1'b1;
        end
        {inst_SW    }:begin
            load_wire  <= 1'b0;
            store_wire <= 1'b1;
        end
        default: begin 
            load_wire  <=  1'b0;
            store_wire <=  1'b0;
        end
endcase
end








    // always @(*) begin
    //     loadData = 32'b0; 
    //     if (load) begin
    //         case (funct3)
    //             3'b000: 
    //                 loadData = {{24{DMEM[word_address][(address[1:0] * 8) + 7]}}, 
    //                             DMEM[word_address][(address[1:0] * 8) +: 8]};
    //             3'b100: // LBU (Load Byte Unsigned - Zero-extended)
    //                 loadData = {24'b0, DMEM[word_address][(address[1:0] * 8) +: 8]};
    //             3'b001: // LH (Load Halfword - Sign-extended)
    //                 loadData = {{16{DMEM[word_address][(address[1] * 16) + 15]}}, 
    //                             DMEM[word_address][(address[1] * 16) +: 16]};
    //             3'b101: // LHU (Load Halfword Unsigned - Zero-extended)
    //                 loadData = {16'b0, DMEM[word_address][(address[1] * 16) +: 16]};
    //             3'b010: // LW (Load Word)
    //                 loadData = DMEM[word_address];
    //             default: loadData = 32'b0; // Undefined operation
    //         endcase
    //     end
    // end

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < mem_size; i = i + 1) begin
                DMEM[i] <= i;
                // DMEM[i] <= 32'b0;
            end
        // end else if (store) begin
        //     case (funct3)
        //         3'b000: // SB (Store Byte)
        //             DMEM[word_address][(address[1:0] * 8) +: 8] <= storeData[7:0];
        //         3'b001: // SH (Store Halfword)
        //             DMEM[word_address][(address[1] * 16) +: 16] <= storeData[15:0];
        //         3'b010: // SW (Store Word)
        //             DMEM[word_address] <= storeData;
        //         default: ; // Undefined operation
        //     endcase
        end
    end

    // Alignment check for debug (optional, can be removed for synthesis)
    // always @(posedge clk) begin
    //     if (load || store) begin
    //         case (funct3)
    //             3'b001: // SH (Halfword)
    //                 if (address[0] != 0)
    //                     $fatal("Unaligned halfword access at address %h", address);
    //             3'b010: // SW (Word)
    //                 if (address[1:0] != 2'b00)
    //                     $fatal("Unaligned word access at address %h", address);
    //         endcase
    //     end
    // end

endmodule


