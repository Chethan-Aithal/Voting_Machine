`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.06.2026 12:03:16
// Design Name: 
// Module Name: votingMachine_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module votingMachine_tb;

    reg clock;
    reg reset;
    reg mode;
    reg button1;
    reg button2;
    reg button3;
    reg button4;

    wire [7:0] led;

    // Instantiate DUT
    votingMachine DUT (
        .clock(clock),
        .reset(reset),
        .mode(mode),
        .button1(button1),
        .button2(button2),
        .button3(button3),
        .button4(button4),
        .led(led)
    );

    // Clock Generation (10 ns period)
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Test Sequence
    initial begin

        // Initialize inputs
        reset   = 1;
        mode    = 0;
        button1 = 0;
        button2 = 0;
        button3 = 0;
        button4 = 0;

        // Apply reset
        #20;
        reset = 0;

        //--------------------------------------------------
        // Vote for Candidate 1
        //--------------------------------------------------
        button1 = 1;
        #120;              // hold long enough for counter=10
        button1 = 0;
        #50;

        //--------------------------------------------------
        // Vote for Candidate 2
        //--------------------------------------------------
        button2 = 1;
        #120;
        button2 = 0;
        #50;

        //--------------------------------------------------
        // Vote for Candidate 2 again
        //--------------------------------------------------
        button2 = 1;
        #120;
        button2 = 0;
        #50;

        //--------------------------------------------------
        // Vote for Candidate 3
        //--------------------------------------------------
        button3 = 1;
        #120;
        button3 = 0;
        #50;

        //--------------------------------------------------
        // Switch to Result Mode
        //--------------------------------------------------
        mode = 1;

        //--------------------------------------------------
        // Display Candidate 1 Votes
        //--------------------------------------------------
        button1 = 1;
        #50;
        button1 = 0;
        #50;

        //--------------------------------------------------
        // Display Candidate 2 Votes
        //--------------------------------------------------
        button2 = 1;
        #50;
        button2 = 0;
        #50;

        //--------------------------------------------------
        // Display Candidate 3 Votes
        //--------------------------------------------------
        button3 = 1;
        #50;
        button3 = 0;
        #50;

        //--------------------------------------------------
        // Display Candidate 4 Votes
        //--------------------------------------------------
        button4 = 1;
        #50;
        button4 = 0;
        #50;

        //--------------------------------------------------
        // End Simulation
        //--------------------------------------------------
        #100;
        $finish;

    end

    // Monitor Signals
    initial begin
        $monitor(
            "Time=%0t Reset=%b Mode=%b B1=%b B2=%b B3=%b B4=%b LED=%d",
            $time, reset, mode,
            button1, button2, button3, button4,
            led
        );
    end

endmodule
