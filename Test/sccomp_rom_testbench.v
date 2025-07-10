// =================================================================
// sccomp_rom_testbench.v
//
// 用于sccomp模块的测试平台。
// 这个版本添加了生成VCD波形文件的功能。
// =================================================================
`timescale 1ns/1ps

module sccomp_rom_testbench();
    // --- 信号定义 ---
    reg clk;
    reg rstn;

    // 模拟FPGA上的开关输入。
    // 在这里，我们暂时将其固定为一个值，例如0。
    // 在仿真时，您可以根据需要强制修改它的值来测试不同功能。
    wire [15:0] sw_i = 16'b0;

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

    // --- 波形文件生成 (关键修改) ---
    initial begin
        // 指定生成的波形文件的名称为 "waveform.vcd"
        $dumpfile("waveform.vcd");
        // $dumpvars(0, uut) 会记录模块 uut 以及其内部所有子模块的信号变化
        $dumpvars(0, uut);
    end

    // --- 测试流程控制 ---
    initial begin
        // 1. 初始化并施加复位信号
        rstn = 0; // 初始时，施加低电平有效的复位
        #20;      // 持续20ns
        rstn = 1; // 撤销复位，CPU开始从0地址执行指令

        // 2. 运行足够长的时间以完成测试程序
        #40000; // 运行40000ns (4000个时钟周期)

        // 3. 结束仿真
        $display("Simulation Finished.");
        $stop;
    end

endmodule


// --- 模块定义 ---### 主要修改说明

// 1.  **添加了波形生成代码**：这是最重要的修改。
//     ```verilog
//     initial begin
//         $dumpfile("waveform.vcd");
//         $dumpvars(0, uut);
//     end
//     ```
//     * `$dumpfile("waveform.vcd");`：告诉仿真器，请创建一个名为 `waveform.vcd` 的文件来存储波形数据。
//     * `$dumpvars(0, uut);`：告诉仿真器，请记录 `uut`（也就是我们的 `sccomp` 模块）以及它内部所有层级的所有信号的变化。没有这一行，波形文件将是空的。

// 2.  **完善了输入信号连接**：
//     * 我将 `reg_sel` 输入改为了连接到 `sw_i` 的低5位（`sw_i[4:0]`），这更符合您原始设计中通过开关选择寄存器的意图。
//     * `sw_i` 本身被定义为一个固定的 `wire`，在基础仿真中，我们让它保持为0。
// ### 下一步

// 现在，您已经拥有了所有进行仿真所需的文件：
// 1.  您所有的CPU源文件，包括 `sccomp.v`、`PipelineCPU.v`、`dm.v` 等。
// 2.  修改后用于仿真的 `sccomp.v`。
// 3.  行为级ROM模型 `instruction_memory.v`。
// 4.  这个最终版的测试平台 `sccomp_rom_testbench.v`。
// 5.  包含机器码的 `instructions.txt` 文件。
