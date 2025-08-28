`default_nettype none
module pmod_interface (
        //inputs
        input wire clk,
        input wire rst_n,
        input wire DO_from_chip, //miso 
        input wire [7:0] data,
        input wire [8:0] opcode,
        input wire [15:0] width;
        input wire [23:0] address,
        //outputs
        output wire DI_to_chip, // mosi
        output wire ncs, // only 1 chip used
        output wire processing_out,
        output wire sclk,
        output wire io1, io2
);
localparam  read = 8'd3, write = 8'd2, page_program = 3, sector_erase = 4, block_erase_32 = 5, block_erase_64 = 6;

//Op code: read
//states IDLE: 0, Read: 1(03h), Write ena: 2(06h), Write dis: 3(04h), Page Program: 4(02h),
// Sector erase: 5(20h), Block Erase(32kB): 6(52h), Block Erase(64kB): 7(D8h)
reg [3:0] state,next_state;
reg [1:0] DO_sync,proc_in_sync, sync_ncs;
reg [15:0] cnt,next_cnt;
reg serialized;,next_serialized;
reg [7:0] shift, next_shift;

//dont know what to do
assign DI_to_chip = 0;
assign ncs = 0;
assign processing_out = 0;
assign sclk = 0;

always @(posedge clk or negedge rst_n) begin
        //reset  
        if (!rst_n) begin
                state <= 0;
                cnt <= 0;
                DO_sync <= 0;
                proc_in_sync <= 0;
                sync_ncs <= 0;
                shift <= 0;
                serialized <= 0;
        end else begin
                state <= next_state;
                cnt <= next_cnt;
                DO_sync[1] <= DO_from_chip;
                DO_sync[0] <= DO_sync[1];
                proc_in_sync[1] <= proc_in_sync;
                proc_in_sync[0] <= proc_in_sync[1];
                sync_ncs[1] <= sync_ncs;
                sync_ncs[0] <= sync_ncs[1];
                serialized <= next_serialized;            
        end
end

always @(*) begin
        //default combinational logic
        next_state = state;
        next_cnt = cnt;
        next_shift = shift;
        next_serialized = serialized;
        case (state)
                //read state: 1, 
                read: begin
                   ncs = 1;
                   if (conditions) begin
                        
                   end

                end 
                default: 
        endcase
end


endmodule

module read (
        //inputs
        input wire clk,
        input wire rst_n,
        input wire DO_from_chip, //miso 
        input wire [23:0] address
        input wire [15:0] width,

        //outputs
        output wire DI_to_chip, // mosi
        output wire ncs, // only 1 chip used
        output wire processing_out, // output from read
        output reg ready
);
localparam idle = 0, send_opcode = 1, send_address = 2, reading = 3, stop = 4;
//idle: 0 send_opcode = 1, send_address = 2, reading = 3, stop: 4

        reg [1:0] next_state, state,sync_di; // 2 stages sync, output lsb
        reg [15:0] cnt,next_cnt;
        
        always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    cnt <= 0;
                    state <= 0;
                    sync_di <= 2'b00;  
                    ready <= 0;
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
                ready = 0;
                case (state)
                        idle: begin
                                next_state = state + 1;
                                next_cnt = 0;
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
                                        DI_to_chip = z;
                                end   
                        end
                        reading: begin
                                if (cnt <= width) begin
                                        processing_out = sync_di[0];
                                        next_cnt = cnt + 1;
                                end else begin
                                       next_cnt = 0;
                                       next_state = state + 1; 
                                end
                        end
                        stop: begin
                                ready = 1;
                                next_state = 0;
                                next_cnt = 0;
                        end
                        default: begin
                        end;
                endcase
        end 
endmodule

module page_program (
        ports
);
        
endmodule

module blck_era (
        ports
);
        
endmodule

module sector_erase (
        ports
);
        
endmodule
