`timescale 1ns / 1ps

module spi_receiver(
    input logic clk,
    input logic sck_in,
    input logic mosi_in,
    input logic cs_in,
    output logic [23:0] pkt,
    output logic ready
);

    logic [2:0] sck_sync,mosi_sync,cs_sync;
    
    always_ff @(posedge clk) begin
        sck_sync <={sck_sync[1:0],sck_in};
        mosi_sync<={mosi_sync[1:0],mosi_in};
        cs_sync<={cs_sync[1:0],cs_in};
    end

    logic [23:0] shift_reg;
    logic [5:0] count=0;

    always_ff @(posedge clk) begin
        ready<=0;
        if (cs_sync[1]) begin
            count<=0;
        end 
        else if (sck_sync[2:1]==2'b01) begin
            shift_reg<={shift_reg[22:0],mosi_sync[2]};
            if (count==6'd23) begin
                pkt<={shift_reg[22:0],mosi_sync[2]};
                ready<=1;
                count<=0;
            end 
            else begin
                count<=count+6'd1;
            end
        end
    end
endmodule