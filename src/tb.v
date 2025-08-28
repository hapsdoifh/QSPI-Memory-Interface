`timescale 1ns/1ns

module read_tb;

//data 
reg [15:0] data;
integer cnt = 0;
//input
reg clk;
reg rst_n;
reg DO_from_chip;//miso 
reg [23:0] address;
reg [15:0] width;
//output        

wire DI_to_chip; // mosi
wire ncs; // only 1 chip used
wire processing_out; // from read
wire read_finished;  // internal handshake

read dut (.clk(clk), .rst_n(rst_n), .DO_from_chip(DO_from_chip), .address(address), .width(width), .DI_to_chip(DI_to_chip), 
        .ncs(ncs), .processing_out(processing_out), .read_finished(read_finished));

initial clk = 0;
always #5 clk = ~clk;

initial begin
    rst_n = 0;
    #100;
    rst_n = 1;
end

task read_d(input [15:0] ddd);
    begin

    for (cnt = 0;cnt < 16;cnt = cnt + 1) begin
        @(posedge clk);

            DO_from_chip <= ddd[cnt];
            
            data[cnt] <= processing_out;
            $display("cnt",cnt," prc o ",processing_out," do ",DO_from_chip);
    end
    @(posedge clk); // Allow one more cycle for DUT to finish sampling last bit
    DO_from_chip <= 1'bZ;
    end
endtask

reg [15:0] exp_data;
integer timeout = 0;
integer i;
initial begin
    address = 24'habcdef;
    exp_data = 16'h1234;
    @(posedge rst_n);

    read_d(16'h1234);
    for (i = 0; i < 4; i = i + 1) begin
        @(posedge clk);

        // timeout loop
        timeout = 0;
        while (!read_finished && timeout < 32000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (timeout == 32000) begin
            $display("timeout");
            $finish;
        end

        if (data !== exp_data) begin
            $display("data error",exp_data,data);
            $finish;
        end else begin
            $display("pass");
        end
    end

end
    

initial begin
    $dumpfile("read.vcd");
    $dumpvars(0, read_tb);
end
endmodule