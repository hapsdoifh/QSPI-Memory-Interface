`default_nettype none
module pmod_interface (
        //inputs
        input wire clk,
        input wire rst_n,
        input wire miso,
        input wire sig_in,

        //outputs
        output wire mosi,
        output wire ncs,
        output wire sig_out,
        output wire sclk
);
reg [2:0] sync_miso, sync_ncs, sync_sig_in;

always @(posedge clk or negedge rst_n) begin 

end
