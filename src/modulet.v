module read (
        //inputs
        input wire clk,
        input wire rst_n,
        input wire DO_from_chip, //miso 
        input wire [23:0] address,
        input wire [15:0] width,

        //outputs
        output reg DI_to_chip, // mosi
        output reg ncs, // only 1 chip used
        output reg processing_out, // output from read
        output reg read_finished   // internal handshake
);
localparam idle = 0, send_opcode = 1, send_address = 2, reading = 3, stop = 4;
//idle: 0 send_opcode = 1, send_address = 2, reading = 3, stop: 4

        reg [1:0] sync_di; // 2 stages sync, output lsb
        reg [2:0] next_state, state;
        reg [15:0] cnt,next_cnt;
        
        always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    cnt <= 0;
                    state <= 0;
                    sync_di <= 2'b00;  
                    read_finished <= 0;
                    ncs = 1;
                    processing_out <= 0;
                end else begin
                        cnt <= next_cnt;
                        state <= next_state;
                        sync_di[1] <= DO_from_chip;
                        sync_di[0] <= sync_di[1];
                end          
        end

        always @(*) begin
                next_state = state;
                next_cnt = cnt;
                read_finished = 0;
                processing_out = 0;
                case (state)
                        idle: begin
                                next_state = state + 1;
                                next_cnt = 0;
                                ncs = 0;
                        end
                        send_opcode: begin
                                if (cnt <= 7) begin
                                        case (cnt)
                                                6,7: DI_to_chip = 1;
                                                default: DI_to_chip = 0;
                                        endcase
                                        next_cnt = cnt + 1;
                                end else begin
                                      next_state = state + 1;
                                      next_cnt = 0;  
                                end
                        end
                        send_address: begin
                                if (cnt <= 23) begin
                                      DI_to_chip = address[23-cnt];
                                      next_cnt = cnt + 1;           
                                end else begin
                                        next_state = state + 1;
                                        next_cnt = 0;
                                        DI_to_chip = 0;
                                end   
                        end
                        reading: begin
                                if (cnt < width) begin
                                        processing_out = sync_di[0];
                                        next_cnt = cnt + 1;
                                end else begin
                                       next_cnt = 0;
                                       next_state = state + 1; 
                                end
                        end
                        stop: begin
                                read_finished = 1;
                                next_state = 0;
                                next_cnt = 0;
                                ncs = 0;
                        end
                        default: begin
                        end
                endcase
        end 
endmodule