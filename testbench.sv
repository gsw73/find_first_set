`define MIN(A, B) ((A) < (B) ? (A) : (B))

typedef bit [ 31:0 ] uint32_t;
typedef enum { FAIL, PASS } pf_e;

`include "my_classes.sv"

// ========================================================================

interface ffs_if
#(
    parameter WIDTH = 64
)
(
    input bit clk
);
    logic rst_n;
    logic in_vld = 0;
    logic [ WIDTH - 1:0 ] vector = {WIDTH{1'b0}};

    logic out_vld;
    logic [ 15:0 ] location;

    clocking cb @( posedge clk );
        default output #1;

        output rst_n;
        output in_vld;
        output vector;

        input out_vld;
        input location;
    endclocking : cb

    modport TB( clocking cb );
endinterface : ffs_if

// ========================================================================

module tb;

parameter VEC_WIDTH = 64;

logic clk;

// instantiate the interface
ffs_if
#(
    .WIDTH( VEC_WIDTH )
)
u_ffs_if
(
    .clk( clk )
);

// instantiate the main program
main_prg #( .WIDTH( VEC_WIDTH ) ) u_main_prg( .i_f( u_ffs_if ) );

initial
begin
    $dumpfile( "dump.vcd" );
    $dumpvars( 0 );
end
  
initial
begin
    $timeformat( -9, 1, "ns", 8 );
    
    clk = 1'b0;
    forever #5 clk = ~clk;
end
  
// instantiate the DUT
find_first_set
#(
    .WIDTH( VEC_WIDTH )
)
u_find_first_set
(
    .clk( clk ),
    .rst_n( u_ffs_if.rst_n ),

    .in_vld( u_ffs_if.in_vld ),
    .vector( u_ffs_if.vector ),

    .out_vld( u_ffs_if.out_vld ),
    .location( u_ffs_if.location )
);

endmodule

// ========================================================================
    
program automatic main_prg
    #( parameter WIDTH = 16 )
    ( ffs_if i_f );

MyEnv#( .WIDTH( WIDTH ) ) env;
virtual ffs_if#(WIDTH).TB sig_h = i_f.TB;

initial
begin
    env = new( sig_h );

    sig_h.cb.rst_n  <= 1'b0;
    #50 sig_h.cb.rst_n <= 1'b1;

    repeat( 20 ) @( sig_h.cb );

    env.run();

    repeat( 2000 ) @( sig_h.cb );
end

endprogram
