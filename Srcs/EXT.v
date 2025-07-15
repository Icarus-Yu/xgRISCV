// 该模块的全称是 立即数生成单元 (Immediate Generator Unit)。

// 在RISC-V指令集中，不同类型的指令（I-Type, S-Type, B-Type等）会把立即数（immediate value）的二进制位“藏”在指令码的不同位置。这个 EXT 模块的核心作用就是：

// 接收从指令中已经提取好但尚未处理的立即数位。

// 根据控制信号 EXTOp 判断当前指令的类型。

// 对这些位进行重新拼接和扩展（符号扩展或零扩展），最终生成一个统一的、完整的32位立即数 immout，以供CPU的其它部分（主要是ALU）使用。

// 它通常位于CPU流水线的 ID（译码）阶段。
`include "ctrl_encode_def.v"

module EXT(
	input   [4:0] 	iimm_shamt,
    input	[11:0]			iimm, //instr[31:20], 12 bits
	input	[11:0]			simm, //instr[31:25, 11:7], 12 bits
	input	[11:0]			bimm, //instrD[31], instrD[7], instrD[30:25], instrD[11:8], 12 bits
	input	[19:0]			uimm,
	input	[19:0]			jimm,
	input	[5:0]			EXTOp,

	output	reg [31:0] 	       immout);// 输出的立即数，32位

    // The input `bimm` is {instr[31], instr[7], instr[30:25], instr[11:8]}
    // The input `jimm` is {instr[31], instr[19:12], instr[20], instr[30:21]}

always  @(*)
	 case (EXTOp)
		`EXT_CTRL_ITYPE_SHAMT:   immout<={27'b0,iimm_shamt[4:0]};
		`EXT_CTRL_ITYPE:	immout <= {{20{iimm[11]}}, iimm[11:0]};
		`EXT_CTRL_STYPE:	immout <= {{20{simm[11]}}, simm[11:0]};
		`EXT_CTRL_BTYPE:    immout <= {{19{bimm[11]}}, bimm, 1'b0};
		`EXT_CTRL_UTYPE:	immout <= {uimm[19:0], 12'b0};
		`EXT_CTRL_JTYPE:	immout <= {{11{jimm[19]}}, jimm[19:0],1'b0};
		default:	        immout <= 32'b0;
	 endcase


endmodule
