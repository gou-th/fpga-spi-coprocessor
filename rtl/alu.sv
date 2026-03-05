`timescale 1ns / 1ps

module alu(
    input logic clk,
    input logic [23:0] pkt_in,
    input logic enable,
    output logic [31:0] result
);

    logic [31:0] acc=0;            //Accumulator for MAC operation 
    logic [31:0] last_result=0;

    logic [7:0] opcode;
    logic [7:0] op_a,op_b;
    
    //Unpacking 24-bit packet 
    assign opcode=pkt_in[23:16];
    assign op_a=pkt_in[15:8];
    assign op_b=pkt_in[7:0];

    always_ff @(posedge clk) begin
        if (enable) begin
            case (opcode)
                8'h01: last_result<=op_a+op_b;
                8'h02: last_result<=op_a*op_b;
                8'h03: last_result<=op_a&op_b;
                8'h04: last_result<=op_a^op_b;
                8'h05: acc<=acc+(op_a*op_b);     //MAC operation 
                8'h06: acc<=0;                    
                8'h09: last_result<=(acc==0)?0:acc;
                default: ;
            endcase
        end
    end
    
    //Output routing 
    always_comb begin
        case (opcode)
            8'h07:result=acc;
            8'h08:result=last_result;
            default: result=last_result;
        endcase
    end

endmodule
