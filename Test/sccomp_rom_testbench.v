// =================================================================
// sccomp_rom_testbench.v
//
// 最终调试版 - 专注于前递(Forwarding)与冒险处理的验证。
// 这个版本记录了所有关键的流水线数据和控制信号。
// =================================================================
`timescale 1ns/1ps

module sccomp_rom_testbench();
    // --- 信号定义 ---
    reg clk;
    reg rstn;
    // 修复：声明 sw_i 信号，用于连接到 reg_sel
    reg [15:0] sw_i;

    // 连接到被测模块(uut)的输出信号
    wire [31:0] reg_data;
    wire [31:0] instr;
    wire [31:0] PC_out;
    wire [31:0] mem_addr_out;
    wire [31:0] mem_data_out;
    wire [31:0] debug_data;

    // --- 实例化被测模块 (sccomp) ---
    sccomp uut(
        .clk(clk),
        .rstn(rstn),
        .reg_sel(sw_i[4:0]), // 将开关的低5位连接到寄存器选择端口
        .reg_data(reg_data),
        .instr(instr),
        .PC_out(PC_out),
        .mem_addr_out(mem_addr_out),
        .mem_data_out(mem_data_out),
        .debug_data(debug_data)
    );

    // --- 时钟生成 ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- 波形文件生成 ---
    initial begin
        $dumpfile("waveform.vcd");

        // 全局信号
        $dumpvars(1, sccomp_rom_testbench.clk);
        $dumpvars(1, sccomp_rom_testbench.rstn);

        // --- 追踪指令在整个流水线中的流动 ---
        $dumpvars(1, uut.U_PipelineCPU.PC_IF);
        $dumpvars(1, uut.U_PipelineCPU.if_id_reg.instr_out);
        $dumpvars(1, uut.U_PipelineCPU.id_ex_reg.instr_out);
        $dumpvars(1, uut.U_PipelineCPU.ex_mem_reg.instr_out);
        $dumpvars(1, uut.U_PipelineCPU.mem_wb_reg.instr_out);

        // --- 新增：用于观察前递（Forwarding）的关键信号 ---
        // 前递单元的控制决策信号
        $dumpvars(1, uut.U_PipelineCPU.forwarding_unit.forward_rs1_EX);
        $dumpvars(1, uut.U_PipelineCPU.forwarding_unit.forward_rs2_EX);
        // EX阶段ALU的两个操作数（这些是经过前递逻辑选择后的最终值）
        $dumpvars(1, uut.U_PipelineCPU.rs1_data_forwarded_EX);
        $dumpvars(1, uut.U_PipelineCPU.alu_B_EX);
        // 前递的数据来源（MEM阶段的ALU结果和WB阶段的最终写回数据）
        $dumpvars(1, uut.U_PipelineCPU.ex_mem_reg.alu_result_out);
        $dumpvars(1, uut.U_PipelineCPU.wb_data_WB);

        // --- 用于验证WB阶段操作的信号 ---
        $dumpvars(1, uut.U_PipelineCPU.RegWrite_WB);
        $dumpvars(1, uut.U_PipelineCPU.rd_addr_WB);
        $dumpvars(1, uut.U_PipelineCPU.wb_data_WB);

        // --- 冒险与控制信号 ---
        $dumpvars(1, uut.U_PipelineCPU.hazard_detection_unit.stall_IF);
        $dumpvars(1, uut.U_PipelineCPU.hazard_detection_unit.flush_ID);
        $dumpvars(1, uut.U_PipelineCPU.hazard_detection_unit.flush_EX);
    end

    // --- 测试流程控制 ---
    initial begin
        // 初始化开关输入
        sw_i = 16'b0;
        // 施加复位
        rstn = 0;
        #20;
        rstn = 1;
        // 运行足够长的时间
        #40000;
        $display("Simulation Finished.");
        $stop;
    end

endmodule
