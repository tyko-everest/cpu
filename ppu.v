module ppu (
    input wire clk
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

    // stores the final 16 bit colour for the selected pixel
    reg [15:0] colour;


    assign x = x_offset + x_view;
    assign y = y_offset + y_view;

    // layed out as a 2D array, ignore the 3 LSBs since tiles are 8x8 pixels
    // in C: (y / 8) * 32 + (x / 8)
    assign tile_map_index = {y[7:3], x[7:3]};

    // get the byte in the tile map, this states which tile to use for this pixel
    always @(posedge clk) begin
        // selects either from 0x1800 or 0x1C00 in vram depending on which map is selected
        tile_set_num <= vram[{2'b11, tile_map_select, tile_map_index}];
    end


    // lower bits of coordinates give the pixel number within given tile
    assign pixel = {y[2:0], x[2:0]};
    // 4 bits per pixel, so grab correct byte
    assign pixel_byte = pixel[5:1];
    // and then will need to decide whether high or low half
    assign pixel_half = pixel[0];

    always @(posedge clk) begin
        // gets the byte in the tile set that holds the palette selection
        palette_colour_byte <= vram[{tile_set_num, pixel_byte}];
    end

    always @(*) begin
        // grab the top or bottom half as the final 4 bit palette colour
        if (pixel_half) begin
            palette_colour <= palette_colour_byte[7:4];
        end else begin
            palette_colour <= palette_colour_byte[3:0];
        end
    end


    // 9 MSB of the tile_map index get the byte that store the palette num
    always @(posedge clk) begin
        palette_set_num_byte <= vram[tile_map_index[9:1]];
    end

    // grab the top or bottom half as the final 4 bit palette selection
    always @(*) begin
        if (tile_map_index[0]) begin
            palette_set_num <= palette_set_num_byte[7:4];
        end else begin
            palette_set_num <= palette_set_num_byte[3:0];
        end
    end


    // finally grab the two two bytes that make up the colour
    always @(posedge clk) begin
        colour[7:0] <= vram[{4'b1010, palette_set_num, palette_colour, 1'b0}];
        colour[15:8] <= vram[{4'b1010, palette_set_num, palette_colour, 1'b1}];
    end
    
endmodule