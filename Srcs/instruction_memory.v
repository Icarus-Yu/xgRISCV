// instruction_memory.v
// 只读指令存储器，从 "instructions.txt" 加载 128 条指令（32 位）

module instruction_memory (
    input  [31:0] addr,         // 输入地址
    output [31:0] dout          // 输出指令
);
    reg [31:0] rom[0:127];

    initial begin
        $readmemh("instructions.txt", rom);
    end

    assign dout = rom[addr[8:2]];  // Word-aligned 地址（32 位指令，每条 4 字节）
endmodule
