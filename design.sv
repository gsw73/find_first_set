module find_first_set#(parameter WIDTH=8)
    (
        input logic clk,
        input logic rst_n,

        input logic in_vld,
        input logic [WIDTH-1:0] vector,

        output logic out_vld,
        output logic [15:0] location
    );

// =======================================================================
// Declarations & Parameters

// =======================================================================
// Logic

// Register:  location
//
// Returns the MSB in a vector that has a bit set.
//
// Note that most synthesis tools support the "break" statement allowing
// code as implemented.  To implement without a "break" statement, flip
// the "for" loop around to start at lowest bit:
//
// for ( i = 0; i < WIDTH - 1; i++ )
//     if ( vector[ i ] )
//          location <= i;

    always_ff @(posedge clk)
        if (!rst_n)
            location <= 'd0;

        else
            for (integer i = WIDTH-1; i >= 0; i--)
                begin
                    if (vector[i] == 1)
                        begin
                            location <= i;
                            break;
                        end
                end

// Register:  out_vld
//
// Make testing easier.  The location is determined in a single clock cycle.

    always_ff @(posedge clk)

        if (!rst_n)
            out_vld <= 1'b0;

        else
            out_vld <= in_vld;

endmodule : find_first_set


