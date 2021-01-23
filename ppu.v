module ppu (
    input wire clk,
    output reg [12:0] addr,
    input wire [31:0] data,
    output reg [15:0] colour
);

    /* VRAM map
     * 
     * tile_set     | 4.75K | 0x0000 - 0x12FF
     * sprites      | 0.25K | 0x1300 - 0x13FF
     * palette set  | 0.5K  | 0x1400 - 0x15FF
     * palette map  | 0.5K  | 0x1600 - 0x17FF
     * tile map 0   | 1K    | 0x1800 - 0x1BFF
     * tile map 1   | 1K    | 0x1C00 - 0x1FFF
     */

    localparam VIEW_WIDTH = 160;
    localparam VIEW_HEIGHT = 128;

    localparam NUM_SPRITES = 64;

    // TODO this needs to be selectable by user
    // select tile map 0 or 1
    reg tile_map_select;
    initial tile_map_select = 0;

    // 8 KiB of vram
    reg [7:0] vram [0:8191];

    // what pixel relative to the viewport
    reg [7:0] x_view, y_view;
    // offset of the viewport from the background screen
    reg [7:0] x_offset, y_offset;
    // sum of the two above, so absolute point on the background
    wire [7:0] x, y;

    // index of tile in background map
    wire [9:0] tile_map_index;

    // stores the tile number in the tile set
    reg [7:0] tile_set_num;

    // which pixel in the selected tile
    wire [5:0] pixel;
    // index of the pixel byte in the selected tile
    wire [4:0] pixel_byte;
    // whether we need the upper or lower half of this byte (16 colours in palette)
    wire pixel_half;

    // used to store the byte that has the palette colour
    reg [7:0] palette_colour_byte;
    // used to select the correct half of the previous byte, i.e. the palette choice
    reg [3:0] palette_colour;

    // used to store the byte that has the palette selection
    reg [7:0] palette_set_num_byte;
    // used to store the palette selection, upper or lower half of previous byte
    reg [3:0] palette_set_num;

    initial x_view = 0;
    initial y_view = 0;

    initial x_offset = 0;
    initial y_offset = 0;

    // gets the requested byte from the actual word that was recieved on bus
    reg [7:0] data_byte;
    always @(*) begin
        case (addr[1:0])
            2'b00: data_byte <= data[7:0]; 
            2'b01: data_byte <= data[15:8];
            2'b10: data_byte <= data[23:16];
            2'b11: data_byte <= data[31:24];
        endcase
    end

    // gets the requested half word from the actual word on the bus
    reg [15:0] data_hword;
    always @(*) begin
        case (addr[1])
            1'b0: data_hword <= data[15:0]; 
            1'b1: data_hword <= data[31:16];
        endcase
    end


    assign x = x_offset + x_view;
    assign y = y_offset + y_view;

    // layed out as a 2D array, ignore the 3 LSBs since tiles are 8x8 pixels
    // in C: (y / 8) * 32 + (x / 8)
    assign tile_map_index = {y[7:3], x[7:3]};


    // lower bits of coordinates give the pixel number within given tile
    assign pixel = {y[2:0], x[2:0]};
    // 4 bits per pixel, so grab correct byte
    assign pixel_byte = pixel[5:1];
    // and then will need to decide whether high or low half
    assign pixel_half = pixel[0];

    always @(*) begin
        // grab the top or bottom half as the final 4 bit palette colour
        if (pixel_half) begin
            palette_colour <= palette_colour_byte[7:4];
        end else begin
            palette_colour <= palette_colour_byte[3:0];
        end
    end


    // process of finding the first 8 sprites on the given line
    reg [5:0] sprites [0:7];
    reg [0:2] sprite_count;
    initial sprite_count = 0;


    reg [7:0] phase_row;
    initial phase_row = 0;

    reg [7:0] phase_col;
    initial phase_col = 0;
    
    reg [3:0] phase_pixel;
    initial phase_pixel = 0;
    

    reg phase_row_lock;
    initial phase_row_lock = 0;

    reg phase_col_lock;
    initial phase_col_lock = 1;

    reg phase_pixel_lock;
    initial phase_pixel_lock = 1;


    // go through each line of the image
    always @(negedge clk) begin
        if (!phase_row_lock) begin
            phase_row_lock = 1;

            if (phase_row < 128 - 1) begin
                phase_row = phase_row + 1;
                phase_col_lock = 0;
            end else begin
                phase_row = 0;
            end

        end
    end


    // go through the 64 sprites 
    always @(negedge clk) begin
        if (!phase_col_lock) begin
            phase_col_lock = 1;

            if (phase_col < 64 + 160 - 1) begin
                phase_col = phase_col + 1;
                phase_pixel_lock = 0;

            end else begin
                phase_col = 0;
                phase_row_lock = 0;
            end
            
        end
    end


    // process of getting colour for background picture given x and y
    always @(negedge clk) begin
        if (!phase_pixel_lock) begin

            if (phase_pixel < 12 - 1) begin
                phase_pixel = phase_pixel + 1;

                case (phase_pixel)
                    0: begin
                        // colour[15:8] <= data_byte;
                        $display("%H", colour);
                        // selects either from 0x1800 or 0x1C00 in vram depending on which map is selected
                        addr <= {2'b11, tile_map_select, tile_map_index};
                    end
                    1: begin
                        tile_set_num = data_byte;
                        // gets the byte in the tile set that holds the palette selection
                        addr = {tile_set_num, pixel_byte};
                    end
                    2: begin
                        palette_colour_byte <= data_byte;
                        // 9 MSB of the tile_map index get the byte that store the palette num
                        addr <= {4'b1011, tile_map_index[9:1]};
                    end
                    3: begin
                        palette_set_num_byte = data_byte;
                        // grab the top or bottom half as the final 4 bit palette selection
                        if (tile_map_index[0]) begin
                            palette_set_num = palette_set_num_byte[7:4];
                        end else begin
                            palette_set_num = palette_set_num_byte[3:0];
                        end
                        addr = {4'b1010, palette_set_num, palette_colour, 1'b0};
                    end
                    4: begin
                        $display(x, y);
                        colour[15:0] <= data_hword;
                        // addr <= {4'b1010, palette_set_num, palette_colour, 1'b1};

                        if (x_view < VIEW_WIDTH - 1) begin
                            x_view = x_view + 1;
                        end else begin
                            x_view = 0;
                            if (y_view < VIEW_HEIGHT - 1) begin
                                y_view = y_view + 1;
                            end else begin
                                y_view = 0;
                            end
                        end
                    end
                endcase

            end else begin
                phase_pixel = 0;
                phase_pixel_lock = 1;
                phase_col_lock = 0;
            end
            
            
        end
    end

    /*
    Plan for drawing sprites
    - at start of each line scan through all sprites, and record first index to first 8 that are on this line
    - at each pixel, go through 8 saved and try to find a match
    - first match found is only one to be drawn
    - check if this pixel of sprite is transparent or not
    - if is, go through background pixel process
    - if not, go through other memory accesses to get the 16 bit colour form the tile and palette

    min clock speed = 128 px * 160 px * 60 fps * 12 mem accesses = 14.7 MHz
    */

endmodule