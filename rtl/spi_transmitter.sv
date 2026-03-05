`timescale 1ns / 1ps

module spi_transmitter(
    input logic clk,
    input logic sck_in,
    input logic cs_in,
    input logic [31:0] data, 
    input logic load,
    output logic miso
);

    logic [2:0] sck_sync, cs_sync;

    //CDC synchronizers of asynchronous signals 
    always_ff @(posedge clk) begin
        sck_sync<={sck_sync[1:0],sck_in};
        cs_sync <={cs_sync[1:0],cs_in};
    end

    logic [31:0] shift_reg;
    logic [5:0] count;
    logic wait_first_fall; 

    always_ff @(posedge clk) begin
        if (cs_sync[1]) begin
            count<=0;
            miso<=0;
            wait_first_fall<=0;
        end
        else begin
            //Latch the ALU result into the shift register
            if (load) begin
                shift_reg<=data;
                miso<=data[31]; //MSB
                count<=1;
                wait_first_fall<=1; 
            end
            //Shift the data out on SCK falling edge 
            else if ((cs_sync[1]==0) && (sck_sync[2:1]==2'b10) && (count!=0) && (count<32)) begin
                
                if (wait_first_fall) begin
                    wait_first_fall<=0; 
                end
                else begin
                    miso<=shift_reg[30];
                    shift_reg<={shift_reg[30:0],1'b0};
                    count<=count+1;
                end
            end
        end
    end

endmodule
