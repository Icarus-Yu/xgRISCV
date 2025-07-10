// dm_32bit.v
// 32位数据存储器，兼容 RV32I 存取类型，支持 BYTE、HALF、WORD 的读写

`include "ctrl_encode_def.v"

module dm_32bit(
    input         clk,         // 时钟信号
    input         DMWr,        // 写使能
    input  [2:0]  DMType,      // 存取类型
    input  [31:0] addr,        // 地址
    input  [31:0] din,         // 写入数据
    output [31:0] dout         // 读出数据
);
    reg [7:0] mem[0:4095];     // 4KB 存储器（字节寻址）
    wire [11:0] a = addr[13:2] << 2; // 对齐后的地址
    wire [1:0] byte_offset = addr[1:0];

    wire [31:0] word = {
        mem[a + 3],
        mem[a + 2],
        mem[a + 1],
        mem[a + 0]
    };

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
