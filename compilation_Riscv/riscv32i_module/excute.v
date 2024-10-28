module execute 
   # (
    parameter   N_param = 32   ) (
    input  wire i_clk,
    input  wire i_en,
    // input  wire [N_param-1:0]  instruction,
    // outputs to register file
    input wire  [4:0] rd_i,
    input wire  [4:0] rs1_i,
    input wire  [4:0] rs2_i,
    input wire  [2:0] fun3_i,
    input wire  [6:0] fun7_i,
    input wire [31:0] imm_i,
    input wire [63:0] Single_Instruction_i
    // output wire [6:0] INST_typ_o,
    // output wire [6:0] opcode_o
    // outputs to ALU
);

always @(posedge i_clk) begin 
case(Single_Instruction_i)

{inst_UNKNOWN   }:begin 
    $write("inst_UNKOWN   ");
end
{inst_ADD   }:begin 
    $write("inst_ADD   ");
end
{inst_SUB   }:begin 
    $write("inst_SUB   ");
end
{inst_XOR   }:begin 
    $write("inst_XOR   ");
end
{inst_OR    }:begin 
    $write("inst_OR    ");
end

{inst_AND    }:begin 
    $write("inst_AND    ");
end
{inst_SLL   }:begin 
    $write("inst_SLL   ");
end
{inst_SRL   }:begin 
    $write("inst_SRL   ");
end
{inst_SRA   }:begin 
    $write("inst_SRA   ");
end

{inst_SLT   }:begin 
    $write("inst_SLT   ");
end
{inst_SLTU  }:begin 
    $write("inst_SLTU  ");
end
{inst_ADDI  }:begin 
    $write("inst_ADDI  ");
end
{inst_XORI  }:begin 
    $write("inst_XORI  ");
end

{inst_ORI  }:begin 
    $write("inst_ORI  ");
end
{inst_ANDI  }:begin 
    $write("inst_ANDI  ");
end
{inst_SLLI  }:begin 
    $write("inst_SLLI  ");
end
{inst_SRLI  }:begin 
    $write("inst_SRLI  ");
end

{inst_SRAI    }:begin 
    $write("inst_SRAI    ");
end
{inst_SLTI  }:begin 
    $write("inst_SLTI  ");
end
{inst_SLTIU }:begin 
    $write("inst_SLTIU ");
end
{inst_LB    }:begin 
    $write("inst_LB    ");
end

{inst_LH    }:begin 
    $write("inst_LH    ");
end
{inst_LW    }:begin 
    $write("inst_LW    ");
end
{inst_LBU   }:begin 
    $write("inst_LBU   ");
end
{inst_LHU   }:begin 
    $write("inst_LHU   ");
end

{inst_SB    }:begin
    $write("inst_SB ");
     end
{inst_SH    }:begin
    $write("inst_SH ");
     end
{inst_SW    }:begin
    $write("inst_SW ");
     end
{inst_BEQ   }:begin
    $write("inst_BEQ");
     end

{inst_BNE   }:begin
    $write("inst_BNE");
     end
{inst_BLT   }:begin
    $write("inst_BLT");
     end
{inst_BGE   }:begin
    $write("inst_BGE");
     end
{inst_BLTU  }:begin
    $write("inst_BLTU");
     end

{inst_BGEU  }:begin
    $write("inst_BGEU");
     end
{inst_JAL   }:begin
    $write("inst_JAL");
     end
{inst_JALR  }:begin
    $write("inst_JALR");
     end
{inst_LUI   }:begin
    $write("inst_LUI");
     end

{inst_AUIPC }:begin
    $write("inst_AUIPC");
     end
{inst_ECALL }:begin
    $write("inst_ECALL");
     end
{inst_EBREAK}:begin
    $write("inst_EBREAK");
     end
{inst_FENCE }:begin
    $write("inst_FENCE");
     end

{inst_FENCEI}:begin
    $write("inst_FENCEI");
     end
{inst_CSRRW }:begin
    $write("inst_CSRRW");
     end
{inst_CSRRS }:begin
    $write("inst_CSRRS");
     end
{inst_CSRRC }:begin
    $write("inst_CSRRC");
     end

{inst_CSRRWI}:begin
    $write("inst_CSRRWI");
     end
{inst_CSRRSI}:begin
    $write("inst_CSRRSI");
     end
{inst_CSRRCI}:begin
    $write("inst_CSRRCI");
     end
default: begin 
    $write("not_encoded instruction");
end


endcase








end




endmodule