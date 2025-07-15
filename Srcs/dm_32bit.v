// dm_32bit.v
// 32位数据存储器，兼容 RV32I 存取类型，支持 BYTE、HALF、WORD 的读写
//在流水线的访问存阶段被使用
`include "ctrl_encode_def.v"

module dm_32bit(
    input         clk,         // 时钟信号，时钟的上升沿才能产生变化
    input         DMWr,        // 写使能，来自控制单元，表示需要向内存写入数据
    input  [2:0]  DMType,      // 存取类型
    input  [31:0] addr,        // 32位访存地址，由ex阶段的ALU计算得出
    input  [31:0] din,         // 写入数据，来自寄存器r2
    output [31:0] dout         // 从内存中读出数据，对于load这个指令而言，在写回阶段被写入目标寄存器
);
    reg [7:0] mem[0:4095];     // 4KB 存储器（字节寻址），相当于运行内存
    wire [11:0] a = addr[13:2] << 2; // 对齐后的地址
    wire [1:0] byte_offset = addr[1:0];

    wire [31:0] word = {
        mem[a + 3],//对应高字节
        mem[a + 2],
        mem[a + 1],
        mem[a + 0]
    };//组合逻辑，读操作异步实现，小端存储
//根据 DMType 和 byte_offset 从 word 中选取需要的部分，并进行相应的处理后，输出给 dout。
    assign dout = (DMType == `DM_WORD) ? word :
                  (DMType == `DM_HALFWORD) ?
                    (byte_offset[1] ? {{16{mem[a + 3][7]}}, mem[a + 3], mem[a + 2]} :
                                      {{16{mem[a + 1][7]}}, mem[a + 1], mem[a + 0]}) :
                  (DMType == `DM_HALFWORD_UNSIGNED) ?
                    (byte_offset[1] ? {16'b0, mem[a + 3], mem[a + 2]} :
                                      {16'b0, mem[a + 1], mem[a + 0]}) :
                  (DMType == `DM_BYTE) ?
                    (byte_offset == 2'b00 ? {{24{mem[a][7]}}, mem[a]} :
                     byte_offset == 2'b01 ? {{24{mem[a + 1][7]}}, mem[a + 1]} :
                     byte_offset == 2'b10 ? {{24{mem[a + 2][7]}}, mem[a + 2]} :
                                            {{24{mem[a + 3][7]}}, mem[a + 3]}) :
                  (DMType == `DM_BYTE_UNSIGNED) ?
                    (byte_offset == 2'b00 ? {24'b0, mem[a]} :
                     byte_offset == 2'b01 ? {24'b0, mem[a + 1]} :
                     byte_offset == 2'b10 ? {24'b0, mem[a + 2]} :
                                            {24'b0, mem[a + 3]}) : 32'hxxxxxxxx;

//写逻辑 这部分是时序逻辑，只有在时钟上升沿 (posedge clk) 并且写使能 DMWr 为 1 时才会执行。
    always @(posedge clk) begin
        if (DMWr) begin
            case (DMType)
                `DM_WORD: begin
                    mem[a + 0] <= din[7:0];
                    mem[a + 1] <= din[15:8];
                    mem[a + 2] <= din[23:16];
                    mem[a + 3] <= din[31:24];
                end
                `DM_HALFWORD: begin
                    if (byte_offset[1]) begin
                        mem[a + 2] <= din[7:0];
                        mem[a + 3] <= din[15:8];
                    end else begin
                        mem[a + 0] <= din[7:0];
                        mem[a + 1] <= din[15:8];
                    end
                end
                `DM_BYTE: begin
                    if (byte_offset == 2'b00) mem[a + 0] <= din[7:0];
                    else if (byte_offset == 2'b01) mem[a + 1] <= din[7:0];
                    else if (byte_offset == 2'b10) mem[a + 2] <= din[7:0];
                    else mem[a + 3] <= din[7:0];
                end
            endcase
        end
    end
endmodule
