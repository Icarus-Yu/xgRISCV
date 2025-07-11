// =================================================================
// sccomp_rom_testbench.v
//
// 最终调试版 - 专注于流水线流动与写回(WB)阶段验证。
// 这个版本记录了追踪指令、验证写回和PC值所需的最关键信号。
// =================================================================
`timescale 1ns/1ps

module sccomp_rom_testbench();
    // --- 信号定义 ---
    reg clk;
    reg rstn;

    // 连接到被测模块(uut)的输出信号
    wire [31:0] reg_data;
    wire [31:0] instr;
    wire [31:0] PC_out;
    wire [31:0] mem_addr_out;
    wire [31:0] mem_data_out;
    wire [31:0] debug_data;

    // --- 实例化被测模块 (sccomp) ---
    // 注意：这里我们测试的是sccomp，而不是包含七段数码管的top_module，
    // 这样可以更专注于CPU核心的仿真。
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
    // 生成一个周期为10ns (100MHz) 的时钟信号
    initial clk = 0;
    always #5 clk = ~clk;

    // --- 波形文件生成 ---
    initial begin
        $dumpfile("waveform.vcd");

        // 全局信号
        $dumpvars(1, sccomp_rom_testbench.clk);
        $dumpvars(1, sccomp_rom_testbench.rstn);

        // 关键的流水线信号，用于追踪指令流动
        $dumpvars(1, uut.U_PipelineCPU.PC_IF);//当前PC地址
        $dumpvars(1, uut.instr);//当前指令
        $dumpvars(1, uut.U_PipelineCPU.if_id_reg.instr_out);
        $dumpvars(1, uut.U_PipelineCPU.id_ex_reg.instr_out);
        $dumpvars(1, uut.U_PipelineCPU.ex_mem_reg.instr_out);

        // --- 用于验证WB阶段操作的"五要素" ---
        $dumpvars(1, uut.U_PipelineCPU.mem_wb_reg.PC_out);             // 0. 这条指令的原始PC地址是？ (新增)
        $dumpvars(1, uut.U_PipelineCPU.mem_wb_reg.instr_out);          // 1. 到达WB阶段的指令是？
        $dumpvars(1, uut.U_PipelineCPU.RegWrite_WB);                   // 2. 是否要写寄存器？
        $dumpvars(1, uut.U_PipelineCPU.rd_addr_WB);                    // 3. 要写的寄存器地址是？
        $dumpvars(1, uut.U_PipelineCPU.wb_data_WB);                    // 4. 要写入的数据是？

        // 冒险与控制信号
        $dumpvars(1, uut.U_PipelineCPU.hazard_detection_unit.stall_IF);
        $dumpvars(1, uut.U_PipelineCPU.hazard_detection_unit.flush_ID);
        $dumpvars(1, uut.U_PipelineCPU.hazard_detection_unit.flush_EX);
    end

    // --- 测试流程控制 ---
    initial begin
        rstn = 0;// 开始20秒进复位操作
        #20;
        rstn = 1;
        #40000;
        $display("Simulation Finished.");
        $stop;
    end

endmodule
