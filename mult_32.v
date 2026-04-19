module mult_32(clk, rst, init, A, B, pp, done);
    input rst;
    input clk;
    input init;
    input [15:0] A;
    input [15:0] B;

    output [31:0] pp;
    output done;

    wire w_sh;
    wire w_reset;
    wire w_add;
    wire w_z;

    wire [31:0] w_A;
    wire [15:0] w_B;
    
    // Instancias de módulos
    rsr rsr0 (.clk(clk), .in_B(B), .shift(w_sh), .load(w_reset), .s_B(w_B));
    lsr lsr0 (.clk(clk), .in_A(A), .shift(w_sh), .load(w_reset), .s_A(w_A));
    comp comp0(.B(w_B), .z(w_z));
    acc acc0 (.clk(clk), .A(w_A), .add(w_add), .rst(w_reset), .pp(pp));
    
    // Corregido: .done(done) con el punto inicial
    control_mult control0 (
        .clk(clk), .rst(rst), .lsb_B(w_B[0]), .init(init), .z(w_z), 
        .done(done), .sh(w_sh), .reset(w_reset), .add(w_add)
    );

endmodule

// --- Módulo RSR ---
module rsr (clk, in_B, shift, load, s_B);
    input clk;
    input [15:0] in_B;
    input load;
    input shift;
    output reg [15:0] s_B;
    
    always @(negedge clk) begin
        if(load)
            s_B <= in_B;
        else if(shift)
            s_B <= s_B >> 1;
    end
endmodule
    
// --- Módulo LSR ---
module lsr (clk, in_A, shift, load, s_A);
    input clk;
    input [15:0] in_A;
    input load;
    input shift;
    output reg [31:0] s_A; // Corregido de 30 a 31 (bus de 32 bits)
    
    always @(negedge clk) begin
        if(load)
            s_A <= {16'b0, in_A}; // Carga con extensión de ceros
        else if(shift)
            s_A <= s_A << 1;
    end
endmodule

// --- Módulo Comparador ---
module comp(B, z);
    input [15:0] B;
    output z;

    assign z = (B == 16'b0) ? 1'b1 : 1'b0;
endmodule

// --- Módulo Acumulador ---
module acc (clk, A, add, rst, pp);
    input clk;
    input [31:0] A;
    input add;
    input rst;
    output reg [31:0] pp;

    initial pp = 0;

    always @(negedge clk) begin
        if (rst)
            pp <= 32'h00000000;
        else if (add)
            pp <= pp + A;
    end
endmodule

// --- Módulo Controlador ---
module control_mult(clk, rst, lsb_B, init, z, done, sh, reset, add);
    input clk, rst, lsb_B, init, z;
    output reg done, sh, reset, add;

    parameter START = 3'b000;
    parameter CHECK = 3'b001;
    parameter SHIFT = 3'b010;
    parameter ADD   = 3'b011;
    parameter END   = 3'b100;

    reg [2:0] state;
    reg [3:0] count;

    initial begin
        done = 0; sh = 0; reset = 0; add = 0;
        state = START;
        count = 0;
    end

    // Lógica de Siguiente Estado
    always @(posedge clk) begin
        if (rst) begin
            state <= START;
        end else begin
            case(state)
                START: begin
                    count <= 0;
                    if(init) state <= CHECK;
                    else     state <= START;
                end

                CHECK: begin
                    if(lsb_B) state <= ADD;
                    else      state <= SHIFT;
                end

                SHIFT: begin
                    if(z) state <= END;
                    else  state <= CHECK;
                end

                ADD: begin
                    state <= SHIFT;
                end

                END: begin
                    count <= count + 1;
                    state <= (count > 9) ? START : END;
                end 

                default: state <= START;
            endcase  
        end
    end 

    // Lógica de Salidas (Combinacional)
    always @(state) begin
        case(state)
            START: begin
                done = 0; sh = 0; reset = 1; add = 0;
            end
            CHECK: begin
                done = 0; sh = 0; reset = 0; add = 0;
            end
            SHIFT: begin
                done = 0; sh = 1; reset = 0; add = 0;
            end
            ADD: begin
                done = 0; sh = 0; reset = 0; add = 1;
            end
            END: begin
                done = 1; sh = 0; reset = 0; add = 0;
            end
            default: begin
                done = 0; sh = 0; reset = 0; add = 0;
            end
        endcase
    end
endmodule