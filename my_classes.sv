package ffs_pkg;
    timeunit 1ns;
    timeprecision 100ps;

    typedef enum { FAIL, PASS } pf_e;

// =======================================================================

    class RandcRange;
        rand bit [15:0] value;
        int max_value;

        function new(int max_value=10);
            this.max_value = max_value;
        endfunction

        constraint c_max_value{value < max_value;}
    endclass : RandcRange

// =======================================================================

    class TestCase#(parameter WIDTH=128);
        bit [WIDTH-1:0] vector;
        rand int first_bit;
        rand int num;

        constraint c_vec
            {
                first_bit inside {[0:WIDTH-1]};
                num >= 0;
                num < first_bit;
                num < (WIDTH >> 3);
                (first_bit == 0) -> num == 0;
            }

        function void post_randomize;
            RandcRange rr = new (first_bit);

            vector = 1 << first_bit;
            for (int i = 0; i < 4; i++)
                begin
                    assert (rr.randomize());
                    vector |= 1 << rr.value;
                end
        endfunction
    endclass

// =======================================================================

    class Agnt#(parameter WIDTH=73);
        mailbox mbxA2D;
        mailbox mbxA2M;
        TestCase#(WIDTH) tc;

        function new(mailbox drv, mailbox mon);
            this.mbxA2D = drv;
            this.mbxA2M = mon;
        endfunction

        task run();
            repeat (500)
                begin
                    tc = new ();
                    assert (tc.randomize());
                    mbxA2D.put(tc);
                    mbxA2M.put(tc);
                end
        endtask
    endclass

// =======================================================================

    class Driver#(parameter WIDTH=34);
        mailbox mbxA2D;
        virtual ffs_if#(WIDTH).TB sig_h;

        function new(mailbox drv, virtual ffs_if#(WIDTH).TB s);
            this.mbxA2D = drv;
            sig_h = s;
        endfunction

        task run();
            TestCase#(WIDTH) tc;

            forever
                begin
                    mbxA2D.get(tc);

                    repeat ($urandom & 3) @(sig_h.cb);
                    sig_h.cb.in_vld <= 1;
                    sig_h.cb.vector <= tc.vector;

                    @(sig_h.cb)
                        sig_h.cb.in_vld <= 0;
                    sig_h.cb.vector <= {WIDTH{1'b0}};
                end
        endtask ;
    endclass

// =======================================================================

    class Monitor#(parameter WIDTH=38);
        localparam VEC_PAD=(WIDTH+1)/4;

        mailbox mbxA2M;
        mailbox mbx2SB;
        int cnt_total;
        virtual ffs_if#(WIDTH).TB sig_h;

        function new(mailbox agnt, virtual ffs_if#(WIDTH).TB s);
            this.mbxA2M = agnt;
            this.sig_h = s;

            mbx2SB = new ();
        endfunction

        task run();
            fork
                forever
                    begin
                        TestCase#(WIDTH) dut_tc;

                        wait (sig_h.cb.out_vld)
                            dut_tc = new;
                        dut_tc.first_bit = sig_h.cb.location;
                        mbx2SB.put(dut_tc);
                        @(sig_h.cb);
                    end
            join_none

            forever
                begin
                    TestCase#(WIDTH) chk_dut_tc;
                    TestCase#(WIDTH) chk_agnt_tc;
                    pf_e chk;

                    mbxA2M.get(chk_agnt_tc);
                    mbx2SB.get(chk_dut_tc);

                    cnt_total++;

                    chk = pf_e'(chk_dut_tc.first_bit == chk_agnt_tc.first_bit);

                    if (chk == PASS)
                        begin
                            $display("@%t first_bit=%0d, vector=%h, cnt=%0d",
                                $realtime, chk_agnt_tc.first_bit, chk_agnt_tc.vector, cnt_total);
                        end

                    else
                        begin
                            $display("@%t ERROR DETECTED: agnt.first_bit = %0d, dut.first_bit = %0d vector = %0VEC_PADh",
                                $realtime, chk_agnt_tc.first_bit, chk_dut_tc.first_bit, chk_agnt_tc.vector);
                            repeat (10) @(sig_h.cb);
                            $finish;
                        end
                end
        endtask
    endclass

// =======================================================================

    class MyEnv#(parameter WIDTH=50);
        Agnt#(WIDTH) agnt;
        Driver#(WIDTH) drv;
        Monitor#(WIDTH) mon;

        mailbox mbxA2D;
        mailbox mbxA2M;

        function new(virtual ffs_if#(WIDTH).TB s);
            mbxA2D = new ();
            mbxA2M = new ();

            agnt = new (mbxA2D, mbxA2M);
            drv = new (mbxA2D, s);
            mon = new (mbxA2M, s);
        endfunction

        task run();
            fork
                agnt.run();
                drv.run();
                mon.run();
            join_none
        endtask
    endclass : MyEnv

endpackage : ffs_pkg
