
//程序计数器 决定并保存下一条要执行的指令地址
`include "ctrl_encode_def.v"

module PC_NPC(
  input clk,
  input rst,
  input stall,
  input [31:0] base_PC,
  input [2:0] NPCOp,
  input [31:0] IMM,
  input [31:0] aluout,
  output reg [31:0] PC
);

  // 组合逻辑：计算下一个PC
  wire [31:0] PCPLUS4 = PC + 4;
  reg [31:0] next_PC;

  always @(*) begin
    case (NPCOp)
      `NPC_PLUS4:  next_PC = PCPLUS4;//正常执行，地址加4
      `NPC_BRANCH: next_PC = base_PC + IMM;
      `NPC_JUMP:   next_PC = base_PC + IMM;//发生分支或跳转，加上立即数偏移
      `NPC_JALR:   next_PC = aluout; // JALR指令，跳转到寄存器指定的地址
      default:     next_PC = PCPLUS4;
    endcase
  end

  // 时序逻辑：PC寄存器
  always @(posedge clk or posedge rst) begin
    if (rst)
      PC <= 32'h0000_0000;
    else if (!stall)
      PC <= next_PC;
    else
      PC <= PC;
  end//寄存器逻辑 PC

endmodule

