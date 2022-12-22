
module Traffic_controller(
    input wire clk_27,
    input wire reset,
    input wire overclock, // use slide switch 9
    input wire left_turn_request, nbnd_walk_req, sbnd_walk_req, ebnd_walk_req, wbnd_walk_req, // assign these walk requests to their appropriate keys
	output wire ovled,
	output wire clk, reset_out,
    output wire northbound_green, northbound_amber, northbound_red,   // you can pick inddividual leds out of the 7 semgents by assigning only the related pins to the traffic light (use hex_driver csv file for help)
    output wire southbound_green, southbound_amber, southbound_red,
    output wire eastbound_green, eastbound_amber, eastbound_red,
    output wire westbound_green, westbound_amber, westbound_red,
    output wire [6:0] southbound_walk, northbound_walk, eastbound_walk, westbound_walk,
    output wire [1:0] left_turn_signal
);

    /* Generating our 1hz clock using the 27Mhz hardware clk */
    `define MAX_CLOCK_CNT_SL 25'd13500000   // 1hz
    `define MAX_CLOCK_CNT_FST 25'd1350000   // 10 hz

    reg [24:0]sl_count;
    reg [24:0]clk_cnt_val;

    always @ (*)
        if (overclock == 1'b1)
            clk_cnt_val <= `MAX_CLOCK_CNT_FST;
        else
            clk_cnt_val <= `MAX_CLOCK_CNT_SL;

    always @ (posedge clk_27)
    begin
        if (sl_count < clk_cnt_val)
            sl_count <= sl_count + 23'd1;
        else
            sl_count <= 23'd0;
    end
	
    /* for debuggging */
	always @ (*)
		reset_out <= reset;
		
	always @ (*)
		ovled <= overclock;
    /* for debuggging ends */

//    (*keep*) reg clk;
    always @ (posedge clk_27)
        if (sl_count == 24'd0)
            clk <= ~clk;//1'b1;
        else
            clk <= clk;
    /* Generating our 1hz clock using the 27Mhz hardware clk done */

    // walk request
    reg walk_request, walk_clear; // design the logic of walk_clear based on enterring 1fd and 4fd
    always @ (posedge walk_clear or negedge nbnd_walk_req or negedge ebnd_walk_req) //  negedge sbnd_walk_req or negedge wbnd_walk_req)
        if (walk_clear == 1'b1)
            walk_request <= 1'b0;
        else if ((nbnd_walk_req==1'b0) || (ebnd_walk_req==1'b0)) // || (sbnd_walk_req==1'b0) || (wbnd_walk_req==1'b0))
            walk_request <= 1'b1;
        else
            walk_request <= walk_request;

    reg entering_state_1w , entering_state_1fd, entering_state_1d , entering_state_1, entering_state_2, entering_state_3, entering_state_4a , entering_state_4w , entering_state_4fd , entering_state_4d ,  entering_state_4, entering_state_5, entering_state_6;
    reg [5:0] timer;
    /* Intializing and updating our timer */
    always @(posedge clk or negedge reset) 
    begin
        if (reset == 1'b0)
            timer <= 6'd60; // time for state 1
        else if (entering_state_1w == 1'b1)
            timer <= 6'd10; // time for state 1w
        else if (entering_state_1fd == 1'b1)
            timer <= 6'd20; // time for state 1fd
        else if (entering_state_1d == 1'b1)
            timer <= 6'd30; // time for state 1d
        else if (entering_state_1 == 1'b1)
            timer <= 6'd60; // time for state 1
        else if (entering_state_2 == 1'b1)
            timer <= 6'd6; // time for state 2
        else if (entering_state_3 == 1'b1)
            timer <= 6'd2;
        else if (entering_state_4a == 1'b1)
            timer <= 6'd20;
        else if (entering_state_4w == 1'b1)
            timer <= 6'd10;
        else if (entering_state_4fd == 1'b1)
            timer <= 6'd20;
        else if (entering_state_4d == 1'b1)
            timer <= 6'd30;
        else if (entering_state_4 == 1'b1)
            timer <= 6'd60;
        else if (entering_state_5 == 1'b1)
            timer <= 6'd6;
        else if (entering_state_6 == 1'b1)
            timer <= 6'd2;
        else if (timer == 6'd1)
            timer <= timer; // never decrement below 1
        else
            timer <= timer - 6'd1;  
    end
    /* Intializing and updating our timer done*/


    /* State 1w logic */
    reg state_1w, state_1w_d, staying_in_state_1w;
    // make the state 1w flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_1w <= 1'b0;
        else 
            state_1w <= state_1w_d;
        
    //logic for entering state 1w
    always @ *
        if( (state_6 == 1'b1) && (timer == 6'd1)  && (walk_request==1'b1))  // replace this line in state_2 with state_1d
            entering_state_1w <= 1'b1;
        else 
            entering_state_1w <= 1'b0;
        
    //logic for staying in state 1w
    always @ *
        if( (state_1w == 1'b1) && (timer != 6'd1) )
            staying_in_state_1w <= 1'b1;
        else 
            staying_in_state_1w <= 1'b0;

    // make the d-input for state_1w flip/flop
    always @ *
    if (entering_state_1w == 1'b1 )
        // enter state 1w on next posedge clk
        state_1w_d <= 1'b1;
    else if ( staying_in_state_1w == 1'b1) 
        // stay in state 1w on next posedge clk
        state_1w_d <= 1'b1;
    else // not in state 1w on next posedge clk
        state_1w_d <= 1'b0;
    /* State 1w logic done */
    
    
    /* State 1fd logic */
    reg state_1fd, state_1fd_d, staying_in_state_1fd;
    // make the state 1fd flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_1fd <= 1'b0;
        else 
            state_1fd <= state_1fd_d;
        
    //logic for entering state 1fd
    always @ *
        if( (state_1w == 1'b1) && (timer == 6'd1))  // replace this line in state_2 with state_1d
            entering_state_1fd <= 1'b1;
        else 
            entering_state_1fd <= 1'b0;
        
    //logic for staying in state 1fd
    always @ *
        if( (state_1fd == 1'b1) && (timer != 6'd1) )
            staying_in_state_1fd <= 1'b1;
        else 
            staying_in_state_1fd <= 1'b0;

    // make the d-input for state_1fd flip/flop
    always @ *
    if (entering_state_1fd == 1'b1 )
        // enter state 1fd on next posedge clk
        state_1fd_d <= 1'b1;
    else if ( staying_in_state_1fd == 1'b1) 
        // stay in state 1fd on next posedge clk
        state_1fd_d <= 1'b1;
    else // not in state 1fd on next posedge clk
        state_1fd_d <= 1'b0;
    /* State 1fd logic done */
    
    
    /* State 1d logic */
    reg state_1d, state_1d_d, staying_in_state_1d;
    // make the state 1d flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_1d <= 1'b0;
        else 
            state_1d <= state_1d_d;
        
    //logic for entering state 1d
    always @ *
        if( (state_1fd == 1'b1) && (timer == 6'd1))  // replace this line in state_2 with state_1d
            entering_state_1d <= 1'b1;
        else 
            entering_state_1d <= 1'b0;
        
    //logic for staying in state 1d
    always @ *
        if( (state_1d == 1'b1) && (timer != 6'd1) )
            staying_in_state_1d <= 1'b1;
        else 
            staying_in_state_1d <= 1'b0;

    // make the d-input for state_1d flip/flop
    always @ *
    if (entering_state_1d == 1'b1 )
        // enter state 1d on next posedge clk
        state_1d_d <= 1'b1;
    else if ( staying_in_state_1d == 1'b1) 
        // stay in state 1d on next posedge clk
        state_1d_d <= 1'b1;
    else // not in state 1d on next posedge clk
        state_1d_d <= 1'b0;
    /* State 1d logic done */


    /* State 1 logic */
    reg state_1, state_6, state_1_d, staying_in_state_1;
    // make the state 1 flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_1 <= 1'b1;
        else 
            state_1 <= state_1_d;
        
    //logic for entering state 1
    always @ *
        if( (state_6 == 1'b1) && (timer == 6'd1) && (walk_request!=1'b1))
            entering_state_1 <= 1'b1;
        else 
            entering_state_1 <= 1'b0;
        
    //logic for staying in state 1
    always @ *
        if( (state_1 == 1'b1) && (timer != 6'd1) )
            staying_in_state_1 <= 1'b1;
        else 
            staying_in_state_1 <= 1'b0;

    // make the d-input for state_1 flip/flop
    always @ *
    if (entering_state_1 == 1'b1 )
        // enter state 1 on next posedge clk
        state_1_d <= 1'b1;
    else if ( staying_in_state_1 == 1'b1) 
        // stay in state 1 on next posedge clk
        state_1_d <= 1'b1;
    else // not in state 1 on next posedge clk
        state_1_d <= 1'b0;
    /* State 1 logic done*/


    /* State 2 logic */
    reg state_2, state_2_d, staying_in_state_2;
    // make the state 2 flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_2 <= 1'b0;
        else 
            state_2 <= state_2_d;
        
    //logic for entering state 2
    always @ *
        if( (state_1 == 1'b1) && (timer == 6'd1) )  // if adding new states change the state_1 to whichever state precedes the new one, and dont forget to update the next state with your new insertion state at this line
            entering_state_2 <= 1'b1;
        else if ( (state_1d == 1'b1) && (timer == 6'd1) )
            entering_state_2 <= 1'b1;
        else 
            entering_state_2 <= 1'b0;
        
    //logic for staying in state 2
    always @ *
        if( (state_2 == 1'b1) && (timer != 6'd1) )
            staying_in_state_2 <= 1'b1;
        else 
            staying_in_state_2 <= 1'b0;

    // make the d-input for state_2 flip/flop
    always @ *
    if (entering_state_2 == 1'b1 )
        // enter state 2 on next posedge clk
        state_2_d <= 1'b1;
    else if ( staying_in_state_2 == 1'b1) 
        // stay in state 2 on next posedge clk
        state_2_d <= 1'b1;
    else // not in state 2 on next posedge clk
        state_2_d <= 1'b0;
    /* State 2 logic done*/
    

    /* State 3 logic */
    reg state_3, state_3_d, staying_in_state_3;
    // make the state 3 flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_3 <= 1'b0;
        else 
            state_3 <= state_3_d;
        
    //logic for entering state 3
    always @ *
        if( (state_2 == 1'b1) && (timer == 6'd1) )
            entering_state_3 <= 1'b1;
        else 
            entering_state_3 <= 1'b0;
        
    //logic for staying in state 3
    always @ *
        if( (state_3 == 1'b1) && (timer != 6'd1) )
            staying_in_state_3 <= 1'b1;
        else 
            staying_in_state_3 <= 1'b0;

    // make the d-input for state_3 flip/flop
    always @ *
    if (entering_state_3 == 1'b1 )
        // enter state 3 on next posedge clk
        state_3_d <= 1'b1;
    else if ( staying_in_state_3 == 1'b1) 
        // stay in state 3 on next posedge clk
        state_3_d <= 1'b1;
    else // not in state 3 on next posedge clk
        state_3_d <= 1'b0;
    /* State 3 logic done*/


    /* State 4a logic */
    reg state_4a, state_4a_d, staying_in_state_4a;
    // make the state 4a flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_4a <= 1'b0;
        else 
            state_4a <= state_4a_d;
        
    //logic for entering state 4a
    always @ *
        if( (state_3 == 1'b1) && (timer == 6'd1)  && (left_turn_request==1'b0))  // replace this line in state_4 with state_4a
            entering_state_4a <= 1'b1;
        else 
            entering_state_4a <= 1'b0;
        
    //logic for staying in state 4a
    always @ *
        if( (state_4a == 1'b1) && (timer != 6'd1) )
            staying_in_state_4a <= 1'b1;
        else 
            staying_in_state_4a <= 1'b0;

    // make the d-input for state_4a flip/flop
    always @ *
    if (entering_state_4a == 1'b1 )
        // enter state 4a on next posedge clk
        state_4a_d <= 1'b1;
    else if ( staying_in_state_4a == 1'b1) 
        // stay in state 4a on next posedge clk
        state_4a_d <= 1'b1;
    else // not in state 4a on next posedge clk
        state_4a_d <= 1'b0;
    /* State 4a logic done*/
    

    /* State 4w logic */
    reg state_4w, state_4w_d, staying_in_state_4w;
    // make the state 4w flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_4w <= 1'b0;
        else 
            state_4w <= state_4w_d;
        
    //logic for entering state 4w
    always @ *
        if( (state_4a == 1'b1) && (timer == 6'd1)  && (walk_request==1'b1) )  // replace this line in state_2 with state_4d
            entering_state_4w <= 1'b1;
        else if ( (state_3 == 1'b1) && (timer == 6'd1)  && (walk_request==1'b1) && (left_turn_request!= 1'b0))
            entering_state_4w <= 1'b1;
        else 
            entering_state_4w <= 1'b0;
        
    //logic for staying in state 4w
    always @ *
        if( (state_4w == 1'b1) && (timer != 6'd1) )
            staying_in_state_4w <= 1'b1;
        else 
            staying_in_state_4w <= 1'b0;

    // make the d-input for state_4w flip/flop
    always @ *
    if (entering_state_4w == 1'b1 )
        // enter state 4w on next posedge clk
        state_4w_d <= 1'b1;
    else if ( staying_in_state_4w == 1'b1) 
        // stay in state 4w on next posedge clk
        state_4w_d <= 1'b1;
    else // not in state 4w on next posedge clk
        state_4w_d <= 1'b0;
    /* State 4w logic done */
    
    
    /* State 4fd logic */
    reg state_4fd, state_4fd_d, staying_in_state_4fd;
    // make the state 4fd flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_4fd <= 1'b0;
        else 
            state_4fd <= state_4fd_d;
        
    //logic for entering state 4fd
    always @ *
        if( (state_4w == 1'b1) && (timer == 6'd1))  // replace this line in state_2 with state_4d
            entering_state_4fd <= 1'b1;
        else 
            entering_state_4fd <= 1'b0;
        
    //logic for staying in state 4fd
    always @ *
        if( (state_4fd == 1'b1) && (timer != 6'd1) )
            staying_in_state_4fd <= 1'b1;
        else 
            staying_in_state_4fd <= 1'b0;

    // make the d-input for state_4fd flip/flop
    always @ *
    if (entering_state_4fd == 1'b1 )
        // enter state 4fd on next posedge clk
        state_4fd_d <= 1'b1;
    else if ( staying_in_state_4fd == 1'b1)
        // stay in state 4fd on next posedge clk
        state_4fd_d <= 1'b1;
    else // not in state 4fd on next posedge clk
        state_4fd_d <= 1'b0;
    /* State 4fd logic done */
    
    
    /* State 4d logic */
    reg state_4d, state_4d_d, staying_in_state_4d;
    // make the state 4d flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_4d <= 1'b0;
        else 
            state_4d <= state_4d_d;
            
    //logic for entering state 4d
    always @ *
        if( (state_4fd == 1'b1) && (timer == 6'd1))  // replace this line in state_2 with state_4d
            entering_state_4d <= 1'b1;
        else 
            entering_state_4d <= 1'b0;
        
    //logic for staying in state 4d
    always @ *
        if( (state_4d == 1'b1) && (timer != 6'd1) )
            staying_in_state_4d <= 1'b1;
        else 
            staying_in_state_4d <= 1'b0;

    // make the d-input for state_4d flip/flop
    always @ *
    if (entering_state_4d == 1'b1 )
        // enter state 4d on next posedge clk
        state_4d_d <= 1'b1;
    else if ( staying_in_state_4d == 1'b1) 
        // stay in state 4d on next posedge clk
        state_4d_d <= 1'b1;
    else // not in state 4d on next posedge clk
        state_4d_d <= 1'b0;
    /* State 4d logic done */


    /* State 4 logic */
    reg state_4, state_4_d, staying_in_state_4;
    // make the state 4 flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_4 <= 1'b0;
        else 
            state_4 <= state_4_d;
        
    //logic for entering state 4
    always @ *
        if((state_4a == 1'b1) && (timer == 6'd1) && (walk_request !=1'b1) ) // coming out of left turn no walk request
            entering_state_4 <= 1'b1;
        else if ((state_3 == 1'b1) && (left_turn_request!=1'b0) && (walk_request!=1'b1)  && (timer == 6'd1)) // coming out of state 3 no left turn no walk request
            entering_state_4 <= 1'b1;
        else 
            entering_state_4 <= 1'b0;
        
    //logic for staying in state 4
    always @ *
        if( (state_4 == 1'b1) && (timer != 6'd1) )
            staying_in_state_4 <= 1'b1;
        else 
            staying_in_state_4 <= 1'b0;

    // make the d-input for state_4 flip/flop
    always @ *
    if (entering_state_4 == 1'b1 )
        // enter state 4 on next posedge clk
        state_4_d <= 1'b1;
    else if ( staying_in_state_4 == 1'b1) 
        // stay in state 4 on next posedge clk
        state_4_d <= 1'b1;
    else // not in state 4 on next posedge clk
        state_4_d <= 1'b0;
    /* State 4 logic done*/
    

    /* State 5 logic */
    reg state_5, state_5_d, staying_in_state_5;
    // make the state 5 flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_5 <= 1'b0;
        else 
            state_5 <= state_5_d;
        
    //logic for entering state 5
    always @ *
        if( (state_4 == 1'b1) && (timer == 6'd1) )
            entering_state_5 <= 1'b1;
        else if ((state_4d == 1'b1) && (timer == 6'd1)) // walk over
            entering_state_5 <= 1'b1;
        else 
            entering_state_5 <= 1'b0;
        
    //logic for staying in state 5
    always @ *
        if( (state_5 == 1'b1) && (timer != 6'd1) )
            staying_in_state_5 <= 1'b1;
        else 
            staying_in_state_5 <= 1'b0;

    // make the d-input for state_5 flip/flop
    always @ *
    if (entering_state_5 == 1'b1 )
        // enter state 5 on next posedge clk
        state_5_d <= 1'b1;
    else if ( staying_in_state_5 == 1'b1) 
        // stay in state 5 on next posedge clk
        state_5_d <= 1'b1;
    else // not in state 5 on next posedge clk
        state_5_d <= 1'b0;
    /* State 5 logic done*/
    

    /* State 6 logic */
    reg state_6_d, staying_in_state_6;
    // make the state 6 flip flop
    always @ (posedge clk or negedge reset)
        if (reset == 1'b0) // keys are active low
            state_6 <= 1'b0;
        else 
            state_6 <= state_6_d;
        
    //logic for entering state 6
    always @ *
        if( (state_5 == 1'b1) && (timer == 6'd1) )
            entering_state_6 <= 1'b1;
        else 
            entering_state_6 <= 1'b0;
        
    //logic for staying in state 6
    always @ *
        if( (state_6 == 1'b1) && (timer != 6'd1) )
            staying_in_state_6 <= 1'b1;
        else 
            staying_in_state_6 <= 1'b0;

    // make the d-input for state_6 flip/flop
    always @ *
    if (entering_state_6 == 1'b1 )
        // enter state 6 on next posedge clk
        state_6_d <= 1'b1;
    else if ( staying_in_state_6 == 1'b1) 
        // stay in state 6 on next posedge clk
        state_6_d <= 1'b1;
    else // not in state 6 on next posedge clk
        state_6_d <= 1'b0;
    /* State 6 logic done*/


    /* logic for each light */
    always @ (*)
    if ( (state_1w |state_1fd | state_1d  | state_1 | state_2 | state_3 | state_4a | state_6) == 1'b1 ) 
        northbound_red = 1'b0;
    else 
        northbound_red = 1'b1;
    
    always @ (*)
    if ( (state_1w |state_1fd | state_1d  | state_1 | state_2 | state_3 | state_4a |  state_6) == 1'b1 ) 
        southbound_red = 1'b0;
    else 
        southbound_red = 1'b1;
    
    always @ (*)
    if ( (state_3 | state_4a | state_4w | state_4fd | state_4d | state_4 | state_5 | state_6) == 1'b1 ) 
        eastbound_red = 1'b0;
    else 
        eastbound_red = 1'b1;

    always @ (*)
    if ( (state_3 | state_4a | state_4w | state_4fd | state_4d | state_4 | state_5 | state_6) == 1'b1 ) 
        westbound_red = 1'b0;
    else 
        westbound_red = 1'b1;

    always @ (*)
    if ((state_4w | state_4fd | state_4d | state_4) == 1'b1 )
        northbound_green = 1'b0;
    else
        northbound_green = 1'b1;   
    
    always @ (*)
    if ((state_4w | state_4fd | state_4d | state_4) == 1'b1 )
        southbound_green = 1'b0;  
    else
        southbound_green = 1'b1;
    
    always @ (*)
    if ( state_5 == 1'b1 )
        northbound_amber = 1'b0;
    else
        northbound_amber = 1'b1;   
    
    always @ (*)
    if ( state_5 == 1'b1 )
        southbound_amber = 1'b0;
    else if (state_4a == 1'b1)
        southbound_amber <= 1'b0;
    else
        southbound_amber = 1'b1;  
    
    always @ (*)
    if ((state_1w |state_1fd | state_1d | state_1) == 1'b1 )
        eastbound_green = 1'b0;
    else
        eastbound_green = 1'b1;  
    
    always @ (*)
    if ((state_1w |state_1fd | state_1d |state_1) == 1'b1 )
        westbound_green = 1'b0;
    else
        westbound_green = 1'b1;  
    
    always @ (*)
    if ( state_2 == 1'b1 )
        eastbound_amber = 1'b0;
    else
        eastbound_amber = 1'b1;   
    
    always @ (*)
    if ( state_2 == 1'b1 )
        westbound_amber = 1'b0;
    else
        westbound_amber = 1'b1;

    always @ (*)
    if (state_4w == 1'b1)
        northbound_walk <= ~7'b0100000;
    else if (state_4fd == 1'b1)
        if (clk)
            northbound_walk <= ~7'b1011110;
        else
            northbound_walk <= ~7'd0;
    else
        northbound_walk <= ~7'b1011110;// ~7'd0

    // left arrow lights - we need to use HEX5 for this change it!
    always @ (*)
    if (state_4fd == 1'b1)
        if (clk)
            southbound_walk <= ~7'b1011110;
        else
            southbound_walk <= ~7'd0;
    else if (state_4w == 1'b1)
        southbound_walk <= ~7'b0100000;
    else
        southbound_walk <= ~7'b1011110;// ~7'd0

    always @ (*)
    if (state_1w == 1'b1)
        eastbound_walk <= ~7'b0100000;
    else if (state_1fd == 1'b1)
        if (clk)
            eastbound_walk <= ~7'b1011110;
        else
            eastbound_walk <= ~7'd0;
    else
        eastbound_walk <= ~7'b1011110;// ~7'd0

    always @ (*)
        if (state_4a == 1'b1)
            left_turn_signal = ~2'b11;
        else
            left_turn_signal = ~2'b00;

    always @ (*)
    if (state_1w == 1'b1)
        westbound_walk <= ~7'b0100000;
    else if (state_1fd == 1'b1)
        if (clk)
            westbound_walk <= ~7'b1011110;
        else
            westbound_walk <= ~7'd0;
    else
        westbound_walk <= ~7'b1011110;// ~7'd0
    /* light logic completed */

    /* walk_clear logic */
    always @ (*)
        if ((staying_in_state_1w == 1'b1) && (timer == 6'd10))
            walk_clear <= 1'b1;
        else if ((staying_in_state_4w == 1'b1) && (timer == 6'd10))
            walk_clear <= 1'b1;
        else
            walk_clear <= 1'b0;
    /* walk_clear logic ends */

endmodule

