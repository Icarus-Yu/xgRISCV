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
    
    // --- �ź����� ---
    reg  clk;
    reg  reset; // �ź�������Ϊ 'reset'��������ʾ�ߵ�ƽ��Ч
    wire [`ADDR_SIZE-1:0] pcW;
    
    // --- ʵ��������CPU��� (DUT: Design Under Test) ---
    // ע��˿�Ҳ��Ӧ���޸���
    xgriscv_pipeline xgriscvp(
        .clk(clk), 
        .reset(reset), // ʹ�� .port(signal) �ķ�ʽ���ӣ������������׳���
        .pcW(pcW)
    );

    // --- ���μ�¼���� (�ؼ��ĵ��Բ���) ---
    initial begin
        $dumpfile("wave.vcd");         // ��������Ĳ����ļ���
        $dumpvars(0, xgriscv_tb);      // ��¼��ģ�鼰������ģ���ȫ���ź�
    end

    // --- ��ʼ���͸�λ���� ---
    initial begin
        // 1. ���ļ�����ָ��ڴ�
        $readmemh("riscv32_sim1.dat", xgriscvp.U_imem.RAM);
        
        // 2. ��ʼ��ʱ�Ӻ͸�λ�ź�
        clk   = 0;    // ϰ����ʱ�Ӵ�0��ʼ
        reset = 1;    // ������CPU���븴λ״̬
        
        // 3. ���ָ�λ״̬һ��ʱ�� (����200��ʱ�䵥λ����2��ʱ������)
        #200;
        
        // 4. ������λ��CPU��ʼ��ʽִ��ָ��
        reset = 0;
    end
    
    // --- ʱ������ ---
    // ÿ10��ʱ�䵥λ��תһ��ʱ�ӵ�ƽ (����Ϊ20)
    always #10 clk = ~clk;
    
    // --- ��������������� ---
    always @(posedge clk) begin // ʹ�� @(posedge clk) �Ǹ���׼������
        if (!reset) begin // ֻ�ڷǸ�λ״̬�½��м��
            
            // ������ȡ�������ע��������ʵʱ�۲�
            // $display("Cycle: %0d, PC: %h, Instr: %h, pcW: %h", 
            //          $time/20, xgriscvp.pcF, xgriscvp.instr, pcW);

            // ��鵽�������ָ���PC��ַʱ����������
            if (pcW == 32'h80000078) begin
                $display(">>> Simulation finished successfully at PC = %h <<<", pcW);
                $finish; // ʹ�� $finish ���׽�������
            end
        end
    end
    
endmodule