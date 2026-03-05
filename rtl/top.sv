`timescale 1ns / 1ps

module top(
    input logic clk100mhz,
    input logic sck_in,
    input logic mosi_in,
    input logic cs_in,
    output logic miso_out,
    output logic [15:0] led
);

    logic [23:0] pkt_data;
    logic pkt_ready;
    logic [31:0] alu_out;
    
    logic [7:0] opcode;
    assign opcode=pkt_data[23:16];

    //Logic to check if command requires sending data back 
    logic is_read_cmd;
    assign is_read_cmd=pkt_ready&&((opcode==8'h07)||(opcode==8'h08));

    logic [31:0] data;
    logic load;

    //Instantiate the receiver module 
    spi_receiver receiver_inst (
        .clk (clk100mhz),
        .sck_in (sck_in),
        .mosi_in (mosi_in),
        .cs_in (cs_in),
        .pkt (pkt_data),
        .ready (pkt_ready)
    );

    //instantiate the ALU module
    alu alu_inst (
        .clk (clk100mhz),
        .pkt_in (pkt_data),
        .enable (pkt_ready),
        .result (alu_out)
    );

    //Transmitter load logic 
    always_ff @(posedge clk100mhz) begin
        load<=0;        
        if (cs_in) begin
            load<=0;
        end
        else if (is_read_cmd) begin
            data<=alu_out;
            load<=1;
        end
    end

    //Instantiate the transmitter module 
    spi_transmitter transmitter_inst (
        .clk (clk100mhz),
        .sck_in (sck_in),
        .cs_in (cs_in),
        .data (data),
        .load (load),
        .miso (miso_out)
    );

    //Mapping lower half of ALU result to Basys 3 FPGA LEds
    always_ff @(posedge clk100mhz) begin
        if (pkt_ready)
            led<=alu_out[15:0];
    end

endmodule
