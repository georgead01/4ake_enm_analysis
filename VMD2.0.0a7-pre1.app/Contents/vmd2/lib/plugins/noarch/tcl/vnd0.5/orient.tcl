package provide Orient 1.1

source [file join $env(VNDPLUGINDIR) la.tcl]

namespace eval ::Orient:: {
    namespace export orient
    variable x
    variable y
    variable z
    variable weights {}
    variable assigned_weights
    variable center_of_mass
    variable inertia_tensor
    variable calculated_axis 
    variable paxis
    variable COM
    variable I
}

# package require Orient
# namespace import Orient::orient
# ... load your molecules and make a selection ...
#
# set I [draw principalaxes $sel]           <--- show/calc the principal axes
# set A [orient $sel [lindex $I 2] {0 0 1}] <--- rotate axis 2 to match Z
# $sel move $A
# set I [draw principalaxes $sel]           <--- recalc principal axes to check
# set A [orient $sel [lindex $I 1] {0 1 0}] <--- rotate axis 1 to match Y
# $sel move $A
# set I [draw principalaxes $sel]           <--- recalc principal axes to check#


#-----------
# This code was modified by jasonks2 for the implementation of a VND neuronal structure.
# The original author is Paul G. Thanks. Further documentation will be provided
#------------

#replace sel with point list
proc Orient::sel_mass { size } {
    puts "VND MASS..."
    variable assigned_weights
    set assigned_weights {}
    #length of values
        set max [lindex $size 0]
        for {set i 0} {$i < [expr $max]} {incr i} { 
        lappend assigned_weights 1
        }
    puts "Visual Neuronal Dynamics: Now setting weights of 1"
    return $assigned_weights
}

proc Orient::sel_com {xarg yarg zarg} {
    variable assigned_weights
    variable center_of_mass
    set x $xarg
    set y $yarg
    set z $zarg
    set m $assigned_weights
    puts "[llength $m]"
    set comx 0
    set comy 0
    set comz 0
    set totalm 0
    foreach xx $x yy $y zz $z mm $m {
    # use the abs of the weights
        #set mm [expr abs($mm)]
	    set comx [ expr "$comx + $xx*$mm" ]
	    set comy [ expr "$comy + $yy*$mm" ]
	    set comz [ expr "$comz + $zz*$mm" ]
	    set totalm [ expr "$totalm + $mm" ]
    }
    set comx [ expr "$comx / $totalm" ]
    set comy [ expr "$comy / $totalm" ]
    set comz [ expr "$comz / $totalm" ]
    puts "Total weight: $totalm"
    set center_of_mass [list $comx $comy $comz]
    return $center_of_mass
}

proc Orient::sel_it { xarg yarg zarg COM} {
    variable inertia_tensor
    variable center_of_mass
    set x $xarg
    set y $yarg
    set z $zarg
    set m $::Orient::assigned_weights
    set COM $::Orient::center_of_mass

    # compute I
    set Ixx 0
    set Ixy 0
    set Ixz 0
    set Iyy 0
    set Iyz 0
    set Izz 0
    foreach xx $x yy $y zz $z mm $m {
        # use the abs of the weights
        #set mm [expr abs($mm)]
        
        # subtract the COM
        set xx [expr $xx - [lindex $COM 0]]
        set yy [expr $yy - [lindex $COM 1]]
        set zz [expr $zz - [lindex $COM 2]]

        set rr [expr $xx + $yy + $zz]

        set Ixx [expr $Ixx + $mm*($yy*$yy+$zz*$zz)]
        set Ixy [expr $Ixy - $mm*($xx*$yy)]
        set Ixz [expr $Ixz - $mm*($xx*$zz)]
        set Iyy [expr $Iyy + $mm*($xx*$xx+$zz*$zz)]
        set Iyz [expr $Iyz - $mm*($yy*$zz)]
        set Izz [expr $Izz + $mm*($xx*$xx+$yy*$yy)]

    }
    set inertia_tensor [list 2 3 3 $Ixx $Ixy $Ixz $Ixy $Iyy $Iyz $Ixz $Iyz $Izz]
    return $inertia_tensor
}

# draws the three principal axes
proc vmd_draw_principalaxes {xarg yarg zarg mol} {
    variable paxis
    variable COM
    variable I
    variable a1

    
    set x $xarg
    set y $yarg
    set z $zarg

    set I [Orient::calc_principalaxes $x $y $z]
    set ::NeuronVND::princ_axes $I

    set a1 [lindex $I 0]
    set a2 [lindex $I 1]
    set a3 [lindex $I 2]

    # find the size of the system #Haky vnd way
    set xmin [tcl::mathfunc::min {*}$xarg]
    set ymin [tcl::mathfunc::min {*}$yarg]
    set zmin [tcl::mathfunc::min {*}$zarg]
    
    set xmax [tcl::mathfunc::max {*}$xarg]
    set ymax [tcl::mathfunc::max {*}$yarg]
    set zmax [tcl::mathfunc::max {*}$zarg]

    set minT [list $xmin $ymin $zmin]
    set maxT [list $xmax $ymax $zmax]

    #dict lappend minmax $minT 
    #dict lappend minmax $maxT

    #puts "MINIMAX$minmax"
    #set minmax [measure minmax $sel] remove because VMD only
    #set ranges [vecsub [lindex $minmax 1] [lindex $minmax 0]]
    set ranges [vecsub $maxT $minT]
    puts "ranges = $ranges"
    set scale [expr .7*[Orient::max [lindex $ranges 0] \
                             [lindex $ranges 1] \
                             [lindex $ranges 2]]]
    set ::NeuronVND::princ_axes_scale $scale
    set scale2 [expr 1.02 * $scale]

    # draw some nice vectors
    #graphics $mol delete all
    graphics $mol color red
    set COM [Orient::sel_com $x $y $z]
    set ::NeuronVND::princ_axes_com $COM
    vmd_draw_vector $mol $COM [vecscale $scale $a1]
    graphics $mol color blue
    vmd_draw_vector $mol $COM [vecscale $scale $a2]
    graphics $mol color green
    vmd_draw_vector $mol $COM [vecscale $scale $a3]

    graphics $mol color white
    graphics $mol text [vecadd $COM [vecscale $scale2 $a1]] "x"
    graphics $mol text [vecadd $COM [vecscale $scale2 $a2]] "z"
    graphics $mol text [vecadd $COM [vecscale $scale2 $a3]] "y"
    set paxis [list $a1 $a2 $a3]
    return $paxis
}

# returns the three principal axes
proc Orient::calc_principalaxes {xarg yarg zarg} {
    puts "Calculating principal axes."
    set x $xarg
    set y $yarg
    set z $zarg
    variable COM
    variable I
    variable calculated_axis

    set weights $::Orient::assigned_weights
    puts "Getting the center-of-mass..."
    # get the COM
    set COM [Orient::sel_com $x $y $z]
    puts "Computing the inertia tensor..."
    # get the I
    set I [Orient::sel_it $x $y $z $COM]
    puts "I before the $I"
    puts "Drawing the principal components..."
    La::mevsvd_br I evals
    # now $I holds in its columns the principal axes
    set a1 "[lindex $I 3] [lindex $I 6] [lindex $I 9]"
    set a2 "[lindex $I 4] [lindex $I 7] [lindex $I 10]"
    set a3 "[lindex $I 5] [lindex $I 8] [lindex $I 11]"
    set calculated_axis [list $a1 $a2 $a3]
     puts "this is the calculated_axis I after SVD"
    foreach elem $calculated_axis { 
        puts "$elem\n"
    }
    return $::Orient::calculated_axis
}

# rotate a selection about its COM, taking <vector1> to <vector2>
# e.g.: orient $sel [lindex $I 2] {0 0 1}
# (this aligns the third principal axis with z)
proc Orient::orient { sel vector1 vector2 {weights domass}} {
    if { $weights == "domass" } {
        set weights [ $sel get mass ]
    } else {
        set weights $::Orient::assigned_weights

    set COM [Orient::sel_com $sel $weights]

    set I [Orient::calc_principalaxes 0 $weights]

    #test alignment on X
    set vector1 [lindex $I 0]
    set vec1 [vecnorm $vector1]

    set vector2 {1 0 0}
    set vec2 [vecnorm $vector2]

    # compute the angle and axis of rotation
    set rotvec [veccross $vec1 $vec2]
    set sine   [veclength $rotvec]
    set cosine [vecdot $vec1 $vec2]
    set angle [expr atan2($sine,$cosine)]
    
    # return the rotation matrix
    return [trans center $COM axis $rotvec $angle rad]
    }
}
proc Orient::test_points {} {
    proc plotpoints {ll} {
        set n 0
        foreach e $ll {
            set x [lindex $e 0]
            set y [lindex $e 1]
            set z [lindex $e 2]
            puts "n= $n: x= $x   y= $y  z=$z"
            draw sphere [list $x $y $z] radius 1
            incr n
        }
    }
    #set mylist { { 0 0 0} {0 1 1} {0 5 6} {3 5 9} {5 5 9} {5 6 9}} #  { 0 0 0} {0 1 1} {0 5 6} {3 5 9} {5 5 9} {5 6 9}
    # set m1 [transoffset {0 8 0}]
    # set m2 [transoffset {0 0 4}]
    # set m3 [transaxis x 40 deg]
    # set m4 [transoffset {3  0 0}]
    # set big_m [transmult $m4 $m3 $m2 $m1 ]
    # set calced_list ""; foreach v $mylist {set cur_v [coordtrans $big_m $v]; lappend calced_list $cur_v }; puts $calced_list
   #  plotpoints $calced_list
}

proc Orient::draw_alignment_axis {xarg yarg zarg amol} {
    set COM $::Orient::COM
    #initial principal axes tensor
    set I $::Orient::calculated_axis
    Orient::vnd_orient

    puts "$COM"
    puts "$I"

    set newa1 ""
    set newa2 ""
    set newa3 ""


    set x $xarg
    set y $yarg
    set z $zarg
    set mol $amol

    set xmin [tcl::mathfunc::min {*}$xarg]
    set ymin [tcl::mathfunc::min {*}$yarg]
    set zmin [tcl::mathfunc::min {*}$zarg]
    set xmax [tcl::mathfunc::max {*}$xarg]
    set ymax [tcl::mathfunc::max {*}$yarg]
    set zmax [tcl::mathfunc::max {*}$zarg]

    set minT [list $xmin $ymin $zmin]
    set maxT [list $xmax $ymax $zmax]

    dict lappend minmax $minT 
    dict lappend minmax $maxT

    #set minmax [measure minmax $sel] remove because VMD only
    #set ranges [vecsub [lindex $minmax 1] [lindex $minmax 0]]
    set ranges [vecsub $minT $maxT]
    set scale [expr 0.009*[Orient::max [lindex $ranges 0] \
                             [lindex $ranges 1] \
                             [lindex $ranges 2]]]
    set scale2 [expr 1.02 * $scale]

    set rot_m $::Orient::calculated_list

    set newa1 [coordtrans [lindex $rot_m 0] [lindex $I 0]]
    set newa2 [coordtrans [lindex $rot_m 1] [lindex $I 1]]
    set newa3 [coordtrans [lindex $rot_m 2] [lindex $I 2]]

    graphics $mol color 20
    set COM [Orient::sel_com $x $y $z]
    vmd_draw_vector $mol $COM [vecscale $scale $newa1]
    vmd_draw_vector $mol $COM [vecscale $scale $newa2]
    vmd_draw_vector $mol $COM [vecscale $scale $newa3]

    graphics $mol color white
    #now just drawing straight from calculated axis
    graphics $mol text [vecadd $COM [vecscale $scale2 $newa1]] "x"
    graphics $mol text [vecadd $COM [vecscale $scale2 $newa2]] "z"
    graphics $mol text [vecadd $COM [vecscale $scale2 $newa3]] "y"
    set alignment_vector [list $newa1 $newa2 $newa3]
    return $alignment_vector

}

#prototype for drawing the alignment axis or "final position"
proc Orient::vnd_orient {} {
    set weights $::Orient::assigned_weights
    set COM $::Orient::COM
    set I $::Orient::calculated_axis

    set ix [lindex $I 0]
    set iy [lindex $I 1]
    set iz [lindex $I 2]

    set xvec { 1 0 0}
    set yvec { 0 1 0}
    set zvec { 0 0 1}
    set vec2list [list $xvec $yvec $zvec]
    puts "$vec2list"
    variable calculated_list
    set calculated_list ""

for {set i 0} {$i < [llength $I]} {incr i} {
        set ivec1 [vecnorm [lindex $I $i]]
        set ivec2 [vecnorm [lindex $vec2list $i]]
        set rotvec [veccross $ivec1 $ivec2]
        set sine   [veclength $rotvec]
        set cosine [vecdot $ivec1 $ivec2]
        set angle [expr atan2($sine,$cosine)]
        puts "rotvec $rotvec"
        puts "sine $sine"
        puts "cosine $cosine"
        puts "angle $angle"
        puts "-------------------------------"
        lappend calculated_list [trans center $COM axis $rotvec $angle rad]
    }
    #set calculated_list [transmult [lindex $calculated_list 0] [lindex $calculated_list 1] [lindex $calculated_list 2]]
    puts "done calculating rotation matrix $calculated_list"
}

proc vmd_draw_arrow {mol start end} {
    set scaling [expr [veclength [vecsub $end $start]]/100]
    # an arrow is made of a cylinder and a cone
    set middle [vecadd $start [vecscale 0.8 [vecsub $end $start]]]
    graphics $mol cylinder $start $middle radius [expr 2*$scaling]
    #i added this
    #graphics $mol line $start [vecadd $start {100 100 100}] width 2 style solid
    puts [list cone $middle $end radius [expr 5*$scaling]]
    graphics $mol cone $middle $end radius [expr 5*$scaling]
}

proc vmd_draw_vector { mol pos val } {
    set end   [ vecadd $pos [ vecscale +1 $val ] ]
    vmd_draw_arrow $mol $pos $end
}    

# find the max of some numbers
proc Orient::max { args } {
    set maxval [lindex $args 0]
    foreach arg $args {
        if { $arg > $maxval } {
            set maxval $arg
        }
    }
    return $maxval
}
