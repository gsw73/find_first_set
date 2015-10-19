module find_first_set
#(
    parameter WIDTH = 8;
)
(
    input logic clk,
    input logic rst_n,

    input in_vld,
    input logic [ WIDTH - 1:0 ] vector,

    output logic out_vld,
    output logic [ 15:0 ] location
);

// =======================================================================
// Declarations & Parameters

// =======================================================================
// Logic

// Register:  location
//
// Returns the MSB in a vector that has a bit set.

always @( posedge clk )

    if ( !rst_n )
        location <= 'd0;

    else
        for ( integer i = WIDTH - 1; i >= 0; i-- )
        begin
            if ( vector[ i ] == 1 )
            begin
                location <= i;
                break;
            end
        end

// Register:  out_vld
//
// Make testing easier.  The location is determined in a single clock cycle.

always @( posedge clk )

    if ( !rst_n )
        out_vld <= 1'b0;

    else
        out_vld <= in_vld;

endmodule
