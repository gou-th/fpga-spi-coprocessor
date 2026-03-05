`timescale 1ns / 1ps

module tb_spi_coprocessor;

    logic clk;
    logic sck;
    logic mosi;
    logic cs;
    logic miso;
    logic [15:0] led;
    logic [31:0] result;

    integer expected;
    integer expected_acc;

    top dut (.clk100mhz(clk),.sck_in(sck),.mosi_in(mosi),.cs_in(cs),.miso_out(miso),.led(led));

    always #5 clk=~clk;     //100MHz clock

    localparam SCK_HALF=50;

    //Task to write a 24-bit command
    task send_packet(input [23:0] packet);
        integer i;
        begin
            cs=1'b0;
            #100;
            for (i=23;i>=0;i=i-1) begin
                mosi=packet[i];
                #SCK_HALF;
                sck=1'b1;
                #SCK_HALF;
                sck=1'b0;
            end
        end
    endtask

    //Task to read the 32-bit response 
    task read_miso(output logic [31:0] value);
        integer i;
        begin 
            value=32'b0;
            for (i=31; i>=0; i=i-1) begin 
                mosi=1'b0;
                #SCK_HALF;
                sck=1'b1;
                #1;
                value[i]=miso;    //sample the value at rising edge 
                #SCK_HALF; 
                sck=1'b0;
            end
            #100;
            cs=1'b1;
            #200;
        end
    endtask

    initial begin
        clk=0;
        sck=0;
        mosi=0;
        cs=1;
        expected_acc=0;
        #500;

        //Test addition
        $display("ADD");
        expected=8'd5+8'd9;
        send_packet({8'h01,8'd5,8'd9});    //Send the command
        send_packet({8'h08,8'h0,8'h0});    //Read last result
        read_miso(result);
        $display("ADD: Expected=%0d, Got=%0d", expected, result);

        //Test multiplication 
        $display("MUL");
        expected=8'd3*8'd7;
        send_packet({8'h02,8'd3,8'd7});
        send_packet({8'h08,8'h0,8'h0});    
        read_miso(result);
        $display("MUL: Expected=%0d, Got=%0d", expected, result);

        //Test MAC unit
        $display("MAC");
        send_packet({8'h06,8'h0,8'h0});      //Clear ACC  
        expected_acc=(4*5)+(2*6);
        send_packet({8'h05,8'd4,8'd5});      //MAC 1
        send_packet({8'h05,8'd2,8'd6});      //MAC 2
        
        send_packet({8'h07,8'h0,8'h0});      //Read ACC
        read_miso(result);
        $display("MAC ACC: Expected=%0d, Got=%0d", expected_acc, result);

        $display("Finished");
        #200;
        $finish;
    end

endmodule
