// =================================================================
// sccomp.v
//
// CPU系统顶层模块。
// 这个版本已经修改为使用行为级ROM模型 (instruction_memory)，
// 以便在通用仿真器 (如 Icarus Verilog) 中运行。
// =================================================================
module sccomp(clk, rstn, reg_sel, reg_data, instr, PC_out, mem_addr_out, mem_data_out, debug_data);
   input          clk;
   input          rstn;
   input [4:0]    reg_sel;
   output [31:0]  reg_data;
   output [31:0]  instr;
   output [31:0]  PC_out;
   output [31:0]  mem_addr_out;      // 内存访问地址输出
   output [31:0]  mem_data_out;      // 内存访问数据输出
   output [31:0]  debug_data;

   wire [31:0]    PC;
   wire           MemWrite;
   wire [31:0]    dm_addr, dm_din, dm_dout;
   wire [2:0]     DMType;
   wire [31:0]    debug_data_wire;

   // 将低电平有效的复位信号转换为高电平有效
   wire rst = ~rstn;

   // 输出PC
   assign PC_out = PC;

   // 输出内存访问地址
   assign mem_addr_out = dm_addr;

   // 根据读写状态输出相应数据
   // 如果CPU正在向内存写数据，输出写入的数据
   // 如果内存正在被读，输出读到的数据
   assign mem_data_out = MemWrite ? dm_din : dm_dout;

  // 实例化五级流水线CPU
   PipelineCPU U_PipelineCPU(
         .clk(clk),                 // input:  cpu clock
         .rst(rst),                 // input:  reset
         .instr_in(instr),          // input:  instruction
         .Data_in(dm_dout),         // input:  data to cpu
         .mem_w(MemWrite),          // output: memory write signal
         .PC_out(PC),               // output: PC
         .Addr_out(dm_addr),        // output: address from cpu to memory
         .Data_out(dm_din),         // output: data from cpu to memory
         .reg_sel(reg_sel),         // input:  register selection
         .reg_data(reg_data),        // output: register data
         .DMType_out(DMType),        // output: memory access type
         .debug_data(debug_data_wire) // output: debug data
         );

  // 实例化数据存储器
   dm    U_dm(
         .clk(clk),           // input:  cpu clock
         .DMWr(MemWrite),     // input:  ram write
         .DMType(DMType),      // input:  memory access type
         .addr(dm_addr),      // input:  ram address (full 32-bit address)
         .din(dm_din),        // input:  data to ram
         .dout(dm_dout)       // output: data from ram
         );

  // ------------------- 修改部分开始 -------------------
  // 为进行仿真，我们将Vivado的ROM IP核 (dist_mem_gen_0) 替换为
  // 我们自己编写的行为级ROM模型 (instruction_memory)。

  /* // 原来的IP核实例化 (已注释掉)
   dist_mem_gen_0 U_ROM (
      .a(PC[8:2]),     // input:  rom address (7-bit)
      .spo(instr)      // output: instruction (32-bit)
   );
  */

   // 实例化用于仿真的行为级指令存储器
   instruction_memory U_instruction_memory (
      .addr(PC[8:2]),   // input: rom address (7-bit)
      .dout(instr)      // output: instruction (32-bit)
   );
   // ------------------- 修改部分结束 -------------------

   assign debug_data = debug_data_wire;

endmodule
```

### 主要修改说明

我将原代码中对 `dist_mem_gen_0` 的实例化部分注释掉了，并替换为对我们之前创建的 `instruction_memory` 模块的实例化。

* **端口连接**：
    * 指令存储器的地址输入 `addr` 仍然连接到 `PC[8:2]`，这是一个7位的地址，用于从128条指令中选择。
    * 指令存储器的数据输出 `dout` 连接到 `instr` 信号线，将读取到的指令送入CPU。
