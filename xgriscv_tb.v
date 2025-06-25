// =====================================================================
//
// Designer   : Yili Gong (Revised by Gemini)
//
// Description:
// A robust testbench for simulating the xgriscv_pipeline.
// Fixes reset logic and adds waveform dumping.
//
// =====================================================================

`include "xgriscv_defines.v"

module xgriscv_tb();
    
    // --- 信号声明 ---
    reg  clk;
    reg  reset; // 信号重命名为 'reset'，清晰表示高电平有效
    wire [`ADDR_SIZE-1:0] pcW;
    
    // --- 实例化您的CPU设计 (DUT: Design Under Test) ---
    // 注意端口也相应地修改了
    xgriscv_pipeline xgriscvp(
        .clk(clk), 
        .reset(reset), // 使用 .port(signal) 的方式连接，更清晰，不易出错
        .pcW(pcW)
    );

    // --- 波形记录设置 (关键的调试部分) ---
    initial begin
        $dumpfile("wave.vcd");         // 设置输出的波形文件名
        $dumpvars(0, xgriscv_tb);      // 记录本模块及所有子模块的全部信号
    end

    // --- 初始化和复位流程 ---
    initial begin
        // 1. 从文件加载指令到内存
        $readmemh("riscv32_sim1.dat", xgriscvp.U_imem.RAM);
        
        // 2. 初始化时钟和复位信号
        clk   = 0;    // 习惯上时钟从0开始
        reset = 1;    // 立即让CPU进入复位状态
        
        // 3. 保持复位状态一段时间 (例如200个时间单位，即2个时钟周期)
        #200;
        
        // 4. 撤销复位，CPU开始正式执行指令
        reset = 0;
    end
    
    // --- 时钟生成 ---
    // 每10个时间单位翻转一次时钟电平 (周期为20)
    always #10 clk = ~clk;
    
    // --- 仿真监控与结束控制 ---
    always @(posedge clk) begin // 使用 @(posedge clk) 是更标准的做法
        if (!reset) begin // 只在非复位状态下进行监控
            
            // 您可以取消下面的注释来进行实时观察
            // $display("Cycle: %0d, PC: %h, Instr: %h, pcW: %h", 
            //          $time/20, xgriscvp.pcF, xgriscvp.instr, pcW);

            // 检查到程序结束指令的PC地址时，结束仿真
            if (pcW == 32'h80000078) begin
                $display(">>> Simulation finished successfully at PC = %h <<<", pcW);
                $finish; // 使用 $finish 彻底结束仿真
            end
        end
    end
    
endmodule