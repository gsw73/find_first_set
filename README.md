# find_first_set
find_first_set implements a priority encoder that takes in a vector (WIDTH set as a parameter) and outputs the first bit
location that contains a 1 starting with the most-significant bit.

The design.sv holds the synthesizable SystemVerilog implementation.  The other files create a SystemVerilog test bench for
verification.  Note that the top-level design and top-level test bench files are named as they are and use back-tick include
statements to support simulation on http://edaplayground.com.  The user may look there to compile and run the code and view
waveforms.
