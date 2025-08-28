`timescale 1ns/1ns

module tb_uart;

    // Parameters
    localparam CLK_FREQ    = 100_000_000;
    localparam BAUD_RATE   = 115_200;
    localparam OVERSAMPLE  = 16;
    localparam DATA_BIT    = 8;
    localparam MAX_WAIT    = 10000;        // timeout limit in clock cycles

    // DUT Inputs
    reg                   clk;
    reg                   rst_n;
    reg                   tx_valid;
    reg  [DATA_BIT-1:0]   tx_data;
    reg                   rx_ready;
    wire                  tx_ready;

    // DUT Outputs
    wire                  tx_serial;
    // reg                   rx_serial = 1;
    wire                  rx_valid;
    wire [DATA_BIT-1:0]   rx_data;

    // Instantiate DUT
    top_uart #(
        .CLK_FREQ   (CLK_FREQ),
        .BAUD_RATE  (BAUD_RATE),
        .OVERSAMPLE (OVERSAMPLE),
        .DATA_BIT   (DATA_BIT)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .tx_valid   (tx_valid),
        .tx_data    (tx_data),
        .tx_ready   (tx_ready),
        .rx_ready   (rx_ready),
        .rx_valid   (rx_valid),
        .rx_data    (rx_data),
        .tx_serial  (tx_serial),
        .rx_serial  (rx_serial)
    );
    // initial begin
    //     $display("   time | clk rst tx_rdy tx_val tx_dat tx_ser rx_ser rx_val rx_dat");
    //     $display("-------+----------------------------------------------------");
    //     $monitor("%7t |   %b   %b      %b       %h      %b      %b      %b     %h", 
    //     $time, clk, rst_n, tx_ready, tx_valid, tx_data, tx_serial, rx_serial, rx_valid, rx_data);
    // end

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    // Loopback serial line
    // always @(posedge clk) begin
    //     rx_serial <= tx_serial;
    // end
    wire rx_serial = tx_serial;
    // Task to send a byte
    task send_byte(input [DATA_BIT-1:0] byte);
        begin
            $display(">>> send_byte(0x%0h) called at time %0t", byte, $time);            
            @(posedge clk);
            wait (tx_ready);
            @(posedge clk);
            tx_data  <= byte;
            tx_valid <= 1;
            @(posedge clk);
            tx_valid <= 0;
        end
    endtask

    // Stimulus and checking
    reg [DATA_BIT-1:0] expected;
    integer i;
    integer timeout;

    initial begin
        // Initialize
        rx_ready = 1;
        tx_valid = 0;
        tx_data  = 0;
        expected = 8'hA5;

        // Wait for reset
        @(posedge rst_n);

        // Send a few bytes
        send_byte(8'hA5);
        send_byte(8'h5A);
        send_byte(8'hFF);
        send_byte(8'h00);

        // Check received data with timeout
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk);

            // timeout loop
            timeout = 0;
            while (!rx_valid && timeout < MAX_WAIT) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout == MAX_WAIT) begin
                $display("ERROR: timeout waiting for rx_valid at time %t", $time);
                $finish;
            end

            // now rx_valid is high, check data
            if (rx_data !== expected) begin
                $display("ERROR: received %02h, expected %02h at time %t",
                         rx_data, expected, $time);
                $finish;
            end else begin
                $display("PASS: received %02h at time %t", rx_data, $time);
            end

            expected = expected ^ 8'hFF; // toggle pattern
        end

        $display("All tests passed.");
        $finish;
    end

    // Waveform
    initial begin
        $dumpfile("tb_uart.vcd");
        $dumpvars(0, tb_uart);
    end

endmodule
