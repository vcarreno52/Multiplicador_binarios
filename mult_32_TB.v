`timescale 1ns / 1ps

module mult_32_TB;
    // 1. Declarar señales para conectar al multiplicador
    reg clk;
    reg rst;
    reg init;
    reg [15:0] A;
    reg [15:0] B;
    wire [31:0] pp;
    wire done;

    // 2. Instanciar la Unidad Bajo Prueba (UUT)
    mult_32 uut (
        .clk(clk), 
        .rst(rst), 
        .init(init), 
        .A(A), 
        .B(B), 
        .pp(pp), 
        .done(done)
    );

    // 3. Generar el Reloj (oscila cada 10 unidades de tiempo)
    always #10 clk = ~clk;

    initial begin
        // Configuración inicial para ver ondas en Linux
        $dumpfile("simulacion.vcd"); // Archivo para GTKWave
        $dumpvars(0, mult_32_TB);

        // Inicializar señales
        clk = 0;
        rst = 1;
        init = 0;
        A = 0;
        B = 0;

        // Resetear el sistema
        #25 rst = 0;
        
        // --- PRUEBA 1: 5 x 3 ---
        #20;
        A = 16'd5;
        B = 16'd3;
        init = 1;      // Pulso de inicio
        #20 init = 0;

        // Esperar a que termine (hasta que done sea 1)
        wait(done);
        
        // --- PRUEBA 2: 10 x 10 ---
        #100;
        A = 16'd10;
        B = 16'd10;
        init = 1;
        #20 init = 0;
        
        wait(done);

        #100;
        $display("Simulacion finalizada. Revisa las ondas.");
        $finish;
    end
endmodule
