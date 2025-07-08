`default_nettype none
module pmod_interface (
        //inputs
        input wire clk,
        input wire rst_n,
        input wire miso,
        input wire processing_in,

        //outputs
        output wire mosi,
        output wire ncs,
        output wire processing_out,
        output wire sclk
);
reg [1:0] sync_miso, sync_ncs, sync_sig_in;

always @(posedge clk or negedge rst_n) begin 

end
