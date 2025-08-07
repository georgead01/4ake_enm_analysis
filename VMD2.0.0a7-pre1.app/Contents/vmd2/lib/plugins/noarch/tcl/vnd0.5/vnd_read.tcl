## VND -- Visual Neuronal Dynamics I/O, parsing, selection, and data storage
##
## $Id: vnd_read.tcl,v 1.41 2024/04/30 23:53:00 barryi Exp $
##
##
## Home Page
## ---------
##   http://www.ks.uiuc.edu/Research/vnd/ 
##
##
package require json

namespace eval ::neuro {}

proc ::neuro::cortex_color_map {thePopName} {
  set matchList {
    AIv 1.000 1.000 0.878
    GU 1.000 1.000 0.600
    AIp 1.000 0.890 0.008
    AId 1.000 0.918 0.090
    VISC 1.000 1.000 0.078
    VISam 0.196 0.090 0.302
    VISpm 0.788 0.627 0.863
    VISa 0.392 0.325 0.580
    RSPagl 0.624 0.000 1.000
    RSPd 0.933 0.510 0.933
    RSPv 0.498 0.000 1.000
    ILA 0.000 0.000 0.804
    ORBm 0.275 0.510 0.706
    FRP 0.000 0.749 1.000
    ACAv 0.098 0.098 0.439
    ORBvl 0.000 0.000 0.502
    ORBl 0.941 0.973 1.000
    ACAd 0.529 0.808 0.980
    PL 0.118 0.565 1.000
    MOs 0.000 0.000 1.000
    SSp-un 0.886 0.239 0.157
    SSp-tr 0.400 0.000 0.000
    SSp-ll 1.000 0.627 0.478
    SSp-n 0.804 0.361 0.361
    SSp-ul 1.000 0.388 0.278
    SSp-m 0.863 0.078 0.235
    SSp-bfd 1.000 0.271 0.000
    MOp 0.698 0.133 0.133
    SSs 1.000 0.000 0.000
    PERI 0.769 0.384 0.063
    AUDpo 1.000 0.549 0.000
    AUDd 0.929 0.569 0.129
    ECT 1.000 0.459 0.220
    AUDv 1.000 0.510 0.000
    AUDp 1.000 0.624 0.000
    TEa 1.000 0.498 0.000
    VISli 0.000 0.651 0.576
    VISal 0.000 0.416 0.306
    VISrl 0.400 1.000 0.000
    VISpl 0.000 0.800 0.600
    VISpor 0.675 0.882 0.686
    VISl 0.090 0.447 0.271
    VISp 0.000 1.000 0.000
  }
  
  foreach {matchString r g b} $matchList {
    #puts "matchString= $matchString   r g b = $r $g $b"
    if {[string match $matchString $thePopName]} {
      return [list $r $g $b]
    }
  }
  puts "default color set"
     #set to tan
  return [list .500 .500 .200]
}

proc ::neuro::v1_color_map {theName} {
  #   desired colors
  # Pvalb Blue
  # Sst Deep Gre
  # Htr3a Cyan
  # e23 Deep Pink
  # e4 Red
  # e5 Firebrick
  # e6 Deep Orange
  set matchList {
    Pvalb 0
    Sst 7
    Htr3a 10
    e23 27 
    e4 1
    e5 30
    e6 31
  }
  #default color
  set theColor 5

  
  foreach {matchString c} $matchList {
    #puts "matchString= $matchString c= $c"
    if {[string match -nocase "*${matchString}*" $theName]} {
      set theColor $c
      puts "for $theName set color $c"
      return $theColor
    }
  }
  puts "default color: $theName, color $c"
  return $theColor
}


proc ::neuro::initVars {} {
  # catch/unset all Hashes and Arrays first
  catch {unset ::neuro::morphoHash}
  variable morphoHash
  set morphoHash(-1) ""
  #   used as:  $morphoHash($fileset_num,$nodeType)
  catch {unset ::neuro::spikeHash}
  variable spikeHash
  set spikeHash(-1) ""
  #   used as:  $spikeHash(spikeList,$population) $spikeHash(units,$population)
  catch {unset ::neuro::edge_pop_hash}
  variable edge_pop_hash 
  set edge_pop_hash(-1) ""
  #   used as:  $edge_pop_hash(source_node_population,$fileset_num,$population) and  $edge_pop_hash(target_node_population,$fileset_num,$population)
  # contains per-population attributes from the source_node_id and target_node_id h5 datasets
  catch {unset ::neuro::compartHash}
  variable compartHash
  set compartHash(-1) ""
  #   used as:  $compartHash($population,index_pointer)
  # contains per-population compartment data for attributes from the source_node_id and target_node_id h5 datasets
  catch {unset ::neuro::node}
  variable node
  set node(-1) ""
  catch {unset ::neuro::edge}
  variable edge 
  set edge(-1) "" 
  variable num_filesets 0
  variable num_edge_filesets 0
  # typeList is hash of lists, num_filesets long
  catch {unset ::neuro::typeList}
  variable typeList
  set typeList(-1) ""
  # edge_typeList is hash of lists, num_edge_filesets long
  catch {unset ::neuro::edge_typeList}
  variable edge_typeList
  set edge_typeList(-1) ""
  # typeAttribList is hash of lists, num_filesets long
  catch {unset ::neuro::typeAttribList}
  variable typeAttribList
  set typeAttribList(-1) ""
  variable globalNodeIdCount 0
  variable globalNodeIdList ""
  variable globalEdgeIdCount 0
  variable globalEdgeIdList ""
  variable globalEdgeDataList ""
  # globalEdgeDataList is a list form duplicate of the data in the edge() hash.  Used for sorting and searching. List elements the same as edge(), with globalEdgeId appended since the list will be sorted
  variable spikeList ""
  catch {unset ::neuro::fileset_pop_unskipped_group_list}
  variable fileset_pop_unskipped_group_list
  #fileset_pop_unskipped_group_list provides hierarchy of filesets, populations, and groups. 
  # for early versions, groups with no coords (no x, y, or z) are skipped
  variable edge_fileset_group_list
  catch {unset ::neuro::nodeHash}
  variable nodeHash
  set nodeHash(-1) ""
  catch {unset ::neuro::typeHash}
  variable typeHash
  set typeHash(-1) ""
  catch {unset ::neuro::edge_typeHash}
  variable edge_typeHash
  set edge_typeHash(-1) ""
  catch {unset ::neuro::node_attrib_dictHash}
  variable node_attrib_dictHash
  set node_attrib_dictHash(-1) ""
  # dict of non-standard nodes for each node by globalNodeID
  #example: node_attrib_dictHash(3023) for node with globalId 3023
  # currently, can query values of some, not all, of the standard node attributes that can be searched on
 variable  standard_node_attribs_queryable [list x y z type fileset population node node_id group model_type cartesian]
  variable nrepCount 0
  variable nrepList ""
  #currently null_radius is used during swc morphology read proto_store_swc.
  # This should be replaced by a token, so it can be set on the fly.
  variable null_radius 8
  variable file_piece_size 5000000
  variable file_2d_piece_size 50000

  variable display_virtuals_at_creation False 
  # for release,  display_virtuals_at_creation should default False
  variable display_noncartesians_at_creation True
  # make rainbow and grayscale colorscales 
 variable colorscale_index_offset [colorinfo num]
  # for using VMD 1024-color scales, currently 33 through 1056

 variable colorscale
    #VND-internal colorscales have 256 values, each r,g,b, value from 0 to 1
 for {set i 0} {$i<=255} {incr i} {
   #grayscale
    #WhiteToBlack
    set colorscale(0,$i,r) [expr $i / 255.0]
    set colorscale(0,$i,g) [expr $i / 255.0]
    set colorscale(0,$i,b) [expr $i / 255.0]
 
    #BlackToWhite
    set colorscale(1,$i,r) [expr (255-$i)/255.0]
    set colorscale(1,$i,g) [expr (255-$i)/255.0]
    set colorscale(1,$i,b) [expr (255-$i)/255.0]


   #rainbow (blue to red) colorscale
    if {$i > 127} {
      set colorscale(2,$i,r) [expr ((($i - 128) * 2 ) +1)/255.0 ]
      set colorscale(2,$i,b) 0
      set colorscale(2,$i,g) [expr ((255-$i) *2)/255.0]
    } else {
      set colorscale(2,$i,r) 0
      set colorscale(2,$i,b) [expr ((127-$i) *2)/255.0]
      set colorscale(2,$i,g) [expr ($i*2)/255.0]
    }
  
   #rainbow (red to blue) colorscale
   if {$i > 127} {
      set colorscale(3,$i,b) [expr ((($i - 128) * 2 ) +1)/255.0 ]
      set colorscale(3,$i,r) 0
      set colorscale(3,$i,g) [expr ((255-$i) *2)/255.0]
    } else {
      set colorscale(3,$i,b) 0
      set colorscale(3,$i,r) [expr ((127-$i) *2)/255.0]
      set colorscale(3,$i,g) [expr ($i*2)/255.0]
    }


  
   #tlPutsDebug "i= $i  r= $colorscale(0,$i,r)  g= $colorscale(0,$i,g)  b= $colorscale(0,$i,b)"
   #tlPutsDebug "i= $i  r= $colorscale(1,$i,r)  g= $colorscale(1,$i,g)  b= $colorscale(1,$i,b)"
  }

}

proc ::neuro::status_bar_processing_start {num_items} {
  .neuron.status.pbar configure -maximum $num_items; # define maximum gui progress bar
  ::NeuronVND::statusBarChanges ready
  ::NeuronVND::statusBarChanges processing
  # prepare for text output for tk updates
  puts ""
}

proc ::neuro::proto_retrieve_morphology {the_fileset_num the_nodeType} {
  variable morphoHash
  return $morphoHash($the_fileset_num,$the_nodeType)
}

proc ::neuro::proto_read_store_edge_types {filename fileset_num } {
  # use prototype file reader plugin simulation and file accessors
  # leftmost column in .csv file is column 0
  variable edge_typeHash
  variable edge_typeList
  set fp [open $filename r]
  #set linenum 0
  set header [gets $fp]
  puts "header = $header"
  # look in header of csv file for titles
  set sl [split $header]
  puts "sl = $sl"
  #XX are there alternate header titles?
  #XX lots of checks to do for missing items
  # XX produce errors for non-optional fields absent
  set edge_type_col  [lsearch $sl "edge_type_id"]
  set population_name_col  [lsearch $sl "population"]
  # population seems optional, is used to avoid edge_type_id namespace collision 
  #set pop_name_extra_col  [lsearch $sl "pop_name"]
  #X pop_name appears optional, not used for namespace collision
  # XX add error checks that no required fields are -1 (not found)  
  # puts "in proto_read_store_edge_types   population_name_col= $population_name_col pop_name_extra_col= $pop_name_extra_col "
  #puts "header for $filename: $header"
  #puts "Returning EARLY from proto_read_store_edge_types..."
  #return
  #set typeList($fileset_num) ""
  while { [gets $fp myline] >=0} {
    set lineList [split $myline]
    set thisType [lindex $lineList $edge_type_col]
    set population_name [lindex $lineList $population_name_col]
    #set pop_name_extra [lindex $lineList $pop_name_extra_col]
    #XXX For edges, use population_name to resolve edge_type_id collision (as per SONATA docs).  Not currently done,.
    #XXX Can population number override? 
    #puts  "myline= >$myline<  thisType= $thisType  population_name= $population_name pop_name_extra= >$pop_name_extra<"
     
    
    lappend edge_typeList($fileset_num) $thisType
    set edge_typeHash(popName,$fileset_num,$thisType) $population_name
    #set edge_typeHash(popNameExtra,$fileset_num,$thisType) $pop_name_extra
    # X could check for uniques as add, in case badly-formed input file
    #incr linenum
  }
  
  puts "Completed reading [llength $edge_typeList($fileset_num)] file types for fileset $fileset_num"
  close $fp
  #if {$fileset_num==1} {error "early halt at fileset_num 1"}
}



proc ::neuro::proto_read_store_types_and_morphos {filename fileset_num swc_dir} {
  # use prototype file reader plugin simulation and file accessors
  # set rot_zaxis_col to -1 if not neeeded
  # leftmost column in .cvs file is column 0
  variable typeHash
  variable typeList
  variable typeAttribList
  variable morphoHash 
  variable null_radius
  set fp [open $filename r]
  #set linenum 0
  set header [gets $fp]
  puts "header = $header"
  # look in header of csv file for titles
  set sl [split $header]
  puts "sl = $sl"
  #XX are there alternate header titles?
  #XX lots of checks to do for missing items
  # XX produce errors for non-optional fields absent
  set node_type_col  [lsearch -exact $sl "node_type_id"]
  set morph_col  [lsearch -exact $sl "morphology"]
  set rot_zaxis_col [lsearch -exact $sl "rotation_angle_zaxis"]
  set population_name_col  [lsearch -exact $sl "population"]
  # population seems optional, is used to avoid edge_type_id namespace collision 
  #set pop_name_extra_col  [lsearch -exact $sl "pop_name"]
  set model_type_col  [lsearch -exact $sl "model_type"]
  # now find all the columns that don't match above fields
  set typeAttribList($fileset_num) ""
  set header_col_num 0
  set typeAttribColNumList ""
  foreach header_col $sl {
    puts " checking header_col $header_col.  header_col_num= $header_col_num" 
    # If not among the standard set ...
    if {! ( [string equal $header_col "node_type_id"] || [string equal $header_col "morphology"] || [string equal $header_col "rotation_angle_zaxis"] || [string equal $header_col "population"] || [string equal $header_col "model_type"]) } {
      puts "header_col $header_col not in standard set"
      #  ... and if not already added to typeAttribList...
      if { [lsearch -exact $typeAttribList($fileset_num) $header_col] == -1} {
        lappend typeAttribList($fileset_num) $header_col
        lappend typeAttribColNumList $header_col_num
        puts "lappended $header_col to typeAttribList($fileset_num).  typeAttribList($fileset_num)= $typeAttribList($fileset_num) typeAttribColNumList= $typeAttribColNumList"
      }
    }
    incr header_col_num
  }
  #X pop_name appears optional, not used for namespace collision
  # XX add error checks that no required fields are -1 (not found)  
   puts "in proto_read_store_types_and_morphos.  morph_col= $morph_col   rot_zaxis_col= $rot_zaxis_col   population_name_col= $population_name_col  model_type_col= $model_type_col"
  puts "header for $filename: $header"
  #puts "Returning EARLY from proto_read_store_types_and_morphos..."
  #return
  #set typeList($fileset_num) ""
  set rot_zaxis 0
  while { [gets $fp myline] >=0} {
    set lineList [split $myline]
    set thisType [lindex $lineList $node_type_col]
    set morphoName [lindex $lineList $morph_col]
    set population_name [lindex $lineList $population_name_col]
    #set pop_name_extra [lindex $lineList $pop_name_extra_col]
    set model_type [lindex $lineList $model_type_col]
    #XXX Can population number override? 
    #puts  "myline= >$myline<  thisType= $thisType  morph_col= $morph_col morphoName= >$morphoName<  population_name= $population_name  model_type= >$model_type<"
    if {$rot_zaxis_col != -1 } {
      set rot_zaxis [lindex $lineList $rot_zaxis_col]
      if {($rot_zaxis eq "NULL")} {
        set rot_zaxis 0
      }
    } 
    #if there is no morpho col, so morpho_col=1, then morphoName will be "", so set to NULL. 
    if {!(($morphoName eq "NULL")||($morphoName eq ""))} { 
      # append .swc file suffix if not present
      if  {!([string range $morphoName end-3 end] eq ".swc")} {
        set morphoName "${morphoName}.swc"
      }
    } else {
      set morphoName NULL
    }

    
    

    lappend typeList($fileset_num) $thisType
    #assign standard set of attribs
    set typeHash(popName,$fileset_num,$thisType) $population_name
    #set typeHash(popNameExtra,$fileset_num,$thisType) $pop_name_extra
    set typeHash(morphoName,$fileset_num,$thisType) $morphoName
    set typeHash(rot_zaxis,$fileset_num,$thisType) $rot_zaxis
    set typeHash(model_type,$fileset_num,$thisType) $model_type
 
    # loop through non-standard attribs and store each for this line
    foreach attrib $typeAttribList($fileset_num) attrib_col $typeAttribColNumList {
      set typeHash($attrib,$fileset_num,$thisType) [lindex $lineList $attrib_col]
    } 
    
    # X could check for uniques as add, in case badly-formed input file
    #incr linenum
  }

  #now read in morphology
  foreach e $typeList($fileset_num) {
    set thefilename [file join $swc_dir $typeHash(morphoName,$fileset_num,$e)]
    puts "Now to read in morphology $e $thefilename"
    #XX Add error checks 
    #XX note that we send defaul null_radius 
    proto_store_swc [proto_read_swc  $thefilename $fileset_num $null_radius] $e $fileset_num
  }
  puts "Completed reading [llength $typeList($fileset_num)] file types for fileset $fileset_num"
  close $fp
  #if {$fileset_num==1} {error "early halt at fileset_num 1"}
}


proc ::neuro::proto_read_swc {filename fileset_num null_radius} {
 # this work will be done by a VMD plugin
 # return a memory represenation of the file, maybe with some processing before returning it
 # vector use: for this Tcl data accessor prototype version, all vectors x y z embedded in list of other values will be a sub-list {x y z}
  set pointList ""
  set movedPointList ""
  # make list each meber is list, from SWC format columns:
  #    {n type x y z radius parent} 
  # if NULL file, set as a single point
  # clean this up so works with file dirs or boolean on proc call 
  if {([string range $filename end-3 end] eq "NULL")} {
    #set a single point at 0 0 0 
    #set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] - $somax]  [expr [lindex $e 3] - $somay] [expr [lindex $e 4] - $somaz] [lindex $e 5]  [lindex $e 6]] 
    # we set a single point, with type soma and radius $null_radius
    # XX change to VND_NULL_RADIUS so null_radius can be changed without re-loading data
    #set l [list 0 1 0 0 0 $null_radius 0] 
    # SWC ID's must start at 1, assign own ID as parent
    set l [list 1 1 0 0 0 $null_radius 1] 
    lappend movedPointList $l
} else {
    set fp [open $filename r]
    set linenum 0
    while { [gets $fp myline] >=0} {
      #puts "linenum= $linenum; DATA: >$myline<"
      #skip comments
      if {[string first \# $myline] != 0} {
        set lineList [split $myline]
        if {[lindex $lineList 1] == 1} then {
          #this is the soma
          set somaList $lineList
        }
        lappend pointList $lineList
      }
      incr linenum
    }
    #reset position to 0,0,0
    # XX consider moving this position reset out of read and into proto_store_swc
    set somax [lindex $somaList 2]
    set somay [lindex $somaList 3]
    set somaz [lindex $somaList 4]
    foreach e $pointList {
      # XX make x y z into a sub-list (vector), and change all that use this data to handle the vector list
      set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] - $somax]  [expr [lindex $e 3] - $somay] [expr [lindex $e 4] - $somaz]  [lindex $e 5]  [lindex $e 6]] 
      lappend movedPointList $l
     }
     close $fp
   }
   #set morphoHash($fileset_num,$node_type) $movedPointList
   return $movedPointList

}

proc ::neuro::proto_store_swc {swc_data_list node_type fileset_num} {
 # this work will by done by internal (non-plugin) VMD code
 # takes in memory representation of what is in the file and stores it in data structures that other functions will call
 # for now, we prototype  and provide a hard-coded null_radius
  #XX soon, provide scan for null_radius token, replace with null_radius
  #XX since we want to do all (most) operations after getting data from plugin
  variable morphoHash
  variable null_radius
  set morphoHash($fileset_num,$node_type) $swc_data_list
  #add hash elements so can find parent quickly later
  foreach e $swc_data_list {
    foreach {en etype ex ey ez eradius eparent} $e {}
    set morphoHash($fileset_num,$node_type,$en) $e
  } 
  set datlength [llength $swc_data_list]
  set mlength [llength $morphoHash($fileset_num,$node_type)]
  puts "stored morpho for fileset_num= $fileset_num node_type=$node_type,  length of swc_data_list is $datlength  mlength= $mlength" 
}

proc ::neuro::read_store_swc {filename fileset_num node_type null_radius} {
  error "outdated proc"
  variable morphoHash
  set pointList ""
  set movedPointList ""
  # make list each meber is list, from SWC format columns, {n type x y z radius parent} 
  # if NULL file, set as a single point
  # clean this up so works with file dirs or boolean on proc call 
  if {[string range $filename end-3 end] eq "NULL"} {
    #set a single point at 0 0 0 
      #set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] - $somax]  [expr [lindex $e 3] - $somay] [expr [lindex $e 4] - $somaz] [lindex $e 5]  [lindex $e 6]] 
      # we set a single point, with type soma and radius $null_radius
      # XX change so null_radius can be changed without re-loading data
      set l [list 0 1 0 0 0 $null_radius 0] 
     lappend movedPointList $l
} else {
    set fp [open $filename r]
    set linenum 0
    while { [gets $fp myline] >=0} {
      #puts "linenum= $linenum; DATA: >$myline<"
      #skip comments
      if {[string first \# $myline] != 0} {
        set lineList [split $myline]
        if {[lindex $lineList 1] == 1} then {
          #this is the soma
          set somaList $lineList
        }
        lappend pointList $lineList
      }
      incr linenum
    }
    #reset position to 0,0,0
    set somax [lindex $somaList 2]
    set somay [lindex $somaList 3]
    set somaz [lindex $somaList 4]
    foreach e $pointList {
      set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] - $somax]  [expr [lindex $e 3] - $somay] [expr [lindex $e 4] - $somaz] [lindex $e 5]  [lindex $e 6]] 
      lappend movedPointList $l
     }
   }
   set morphoHash($fileset_num,$node_type) $movedPointList
   return
}


proc ::neuro::show_morph_moved_oldspheres {node_type fileset_num x y z xrot yrot zrot radius_scale} {
  error "outdated proc" 
  variable morphoHash
  variable typeHash
  set pointList $morphoHash($fileset_num $node_type)
  set rotPointList ""
  puts "yrot = $yrot"
  # do rotation here
  set c [expr $node_type % 32]
  draw color $c
  #draw color $theColor
  puts "in show_morph_moved_color, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  puts "node_type= $node_type  type_zrot= $type_zrot"
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    # negative type_zrot:
    set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  set movedPointList ""
  foreach e $rotPointList {
    set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
    #puts "moved show_morph_moved l= $l"
    lappend movedPointList $l
   } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  foreach lineList $movedPointList {
    #puts "lineList=$lineList"
    #set enum 0
    #foreach e $lineList {
    #   if {$e < 0.0} {set e 0.0}
    #   set mat($linenum,$enum) [expr $e + 0.0]
    #   incr enum
    #} 
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 
    #puts "draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}  radius [lindex $lineList 5] resolution 6" 

    # XX sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
      set sphereRes 12
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
    } 
       
    
    draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    #lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    #lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  #draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::show_morph_moved_color_oldspheres {node_type fileset_num x y z xrot yrot zrot radius_scale theColor} {
  variable morphoHash
  variable typeHash
  set pointList $morphoHash($fileset_num,$node_type)
  set rotPointList ""
  puts "yrot = $yrot"
  # do rotation here
  #set c [expr $node_type % 32]
  draw color $theColor
  puts "in show_morph_moved_color, color set to $theColor"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  puts "node_type= $node_type  type_zrot= $type_zrot"
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr  $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  set movedPointList ""
  foreach e $rotPointList {
    set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
    #puts "moved show_morph_moved l= $l"
    lappend movedPointList $l
   } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  foreach lineList $movedPointList {
    #puts "lineList=$lineList"
    #set enum 0
    #foreach e $lineList {
    #   if {$e < 0.0} {set e 0.0}
    #   set mat($linenum,$enum) [expr $e + 0.0]
    #   incr enum
    #} 
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 
    #puts "draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}  radius [lindex $lineList 5] resolution 6" 

    # XX sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
      set sphereRes 12
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
    } 
       
    
    draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    #lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    #lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  #draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::show_morph_moved_color {node_type fileset_num x y z xrot yrot zrot radius_scale theColor} {
  variable morphoHash
  variable typeHash
  set pointList $morphoHash($fileset_num,$node_type)
  set rotPointList ""
  puts "yrot = $yrot"
  # do rotation here
  #set c [expr $node_type % 32]
  draw color $theColor
  puts "in show_morph_moved_color, color set to $theColor"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  puts "node_type= $node_type  type_zrot= $type_zrot"
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  set movedPointList ""
  foreach e $rotPointList {
    set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
    #puts "moved show_morph_moved l= $l"
    lappend movedPointList $l
   } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  foreach lineList $movedPointList {
    #puts "lineList=$lineList"
    #set enum 0
    #foreach e $lineList {
    #   if {$e < 0.0} {set e 0.0}
    #   set mat($linenum,$enum) [expr $e + 0.0]
    #   incr enum
    #} 
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 
    #puts "draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}  radius [lindex $lineList 5] resolution 6" 

    # XX sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
      set sphereRes 12
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
    } 
       
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::sphereList_morph_moved {node_type fileset_num x y z xrot yrot zrot } {
  variable morphoHash
  variable typeHash
  set pointList $morphoHash($fileset_num,$node_type)
  set rotPointList ""
  puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transoffset $x $y $z] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  #set movedPointList ""
  #foreach e $rotPointList {
  #  set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
  #  #puts "moved show_morph_moved l= $l"
  #  lappend movedPointList $l
  # } 
  set sphereList ""
  set radiusList ""
  set linenum 0
 
  #count spheres for XYZ file
  set sphereCount 0 
  foreach lineList $rotPointList {
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

    # XX next line sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    #if {[lindex $lineList 1] == 1} then {
    #  set draw_radius_scale 1.0
    #  set sphereRes 12
    #} else {
    #  set draw_radius_scale $radius_scale
    #  set sphereRes 4 
    #} 
       
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    #lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  ##draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #set sphereCount [llength $sphereList]
  #set fp [open $theFilename w]
  ##puts $theFile $sphereCount
  ##puts $theFile "Halo spheres - node type $node_type"
  #foreach e $sphereList {
  #  puts $theFile "CA [lindex $e 0] [lindex $e 1] [lindex $e 2]" 
  #} 
  ##close $fp
  #set haloMol [mol new $theFilename]
  #mol rename $haloMol "type_$node_type"
  #puts "added haloMol $haloMol"
  #set haloSel [atomselect $haloMol "all"]
  #$haloSel set radius $halo_radius 
  #mol modstyle 0 $haloMol QuickSurf 1.200000 1.700000 1.200000 1.000000 
  #mol modmaterial 0 $haloMol GlassBubble
  #mol modcolor 0 $haloMol ColorID $halo_color
  return $sphereList
}

proc ::neuro::halo_morph_moved {node_type fileset_num x y z xrot yrot zrot radius_scale theFilename halo_radius halo_color halo_label} {
  variable morphoHash
  variable typeHash
  set pointList $morphoHash($fileset_num,$node_type)
  set rotPointList ""
  puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transoffset $x $y $z] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  #set movedPointList ""
  #foreach e $rotPointList {
  #  set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
  #  #puts "moved show_morph_moved l= $l"
  #  lappend movedPointList $l
  # } 
  set sphereList ""
  set radiusList ""
  set linenum 0
 
  #count spheres for XYZ file
  set sphereCount 0 
  foreach lineList $rotPointList {
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

    # XX next line sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
      set sphereRes 12
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
    } 
       
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  ##draw spheretube "$sphereList" radii $radiusList drawtubes 0
  set sphereCount [llength $sphereList]
  set fp [open $theFilename w]
  puts $fp $sphereCount
  puts $fp "Halo spheres - node type $node_type"
  foreach e $sphereList {
    puts $fp "CA [lindex $e 0] [lindex $e 1] [lindex $e 2]" 
  }
  close $fp
  set haloMol [mol new $theFilename]
  mol rename $haloMol "$halo_label"
  puts "added haloMol $haloMol"
  set haloSel [atomselect $haloMol "all"]
  $haloSel set radius $halo_radius 
  mol modstyle 0 $haloMol QuickSurf 1.200000 1.700000 1.200000 1.000000 
  mol modmaterial 0 $haloMol GlassBubble
  mol modcolor 0 $haloMol ColorID $halo_color

}

proc ::neuro::sphereList_morph_moved_soma_only {fileset_num node_type x y z xrot yrot zrot soma_radius_scale} {
  variable morphoHash
  variable typeHash
  
  set sphereList ""
  set radiusList ""
  set linenum 0
  #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

  # XX next line sets color per sphere, so per component of neuron - make this a param setting 
  ## draw color [lindex $lineList 1] 

  #don't scale soma, increase res for soma 
  set draw_radius_scale $soma_radius_scale
  draw spheretube "{ $x $y $z }" radii "{ $soma_radius_scale }" drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::show_morph_moved_soma_only_color_rgb {node_type fileset_num tx y z r g b soma_radius} {
  draw spheretube "{ $x $y $z }" radii "{ $soma_radius }" color "{ $r $g $b}" drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}


proc ::neuro::proto_show_morph_moved_soma_only {node_type fileset_num x y z xrot yrot zrot soma_radius_scale} {
  #variable morphoHash
  variable typeHash
 
  set sphereList ""
  set radiusList ""
  set linenum 0
  #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

  # XX next line sets color per sphere, so per component of neuron - make this a param setting 
  ## draw color [lindex $lineList 1] 

  #don't scale soma, increase res for soma 
  set draw_radius_scale $soma_radius_scale
  #draw spheretube "{ $x $y $z }" radii "{ $soma_radius_scale }" drawtubes 0
  # spheretube seems not being recognized by MoleculeGraphics::find_bounds check
  draw sphere [list $x $y $z] radius  $soma_radius_scale 
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::proto_show_morph_moved_swc_segment {node_type fileset_num x y z xrot yrot zrot radius_scale swc_segment} {
  #variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set rotPointList ""
  puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  #set pointcount 0

  foreach e $pointList {
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transoffset $x $y $z] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set id [lindex $e 0]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    if {$swc_segment == $id} {lappend rotPointList $l}
    #incr pointcount
  } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  foreach lineList $rotPointList {
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

    # XX next line sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
      set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
      #set theRad [expr $draw_radius_scale * [lindex $lineList 5] ] 
      set theRad 10
    } 
      if {$theRad>$radius_scale} {puts "$theRad";set $theRad $radius_scale}   
      lappend radiusList $theRad 
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    ##lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::proto_calc_morph_original_pos_isolated_points {node_type fileset_num} {
  # calculate (copy over) all points in morphology list, but only to create an original-position version of the point cloud
  # no parent-child relationships, no double-counting points.  
  # XX later, for better accuracy, consider: calculate all segments and return midpoint, since some segments may be long
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  # the "isolated_" term reminds this is really a point-cloud-like pointlist, without parent and other info in each element
  set isolated_pointList ""
  foreach e $pointList {
    foreach {en etype ex ey ez eradius eparent} $e {}
    set v [list $ex $ey $ez]
    lappend isolated_pointList $v
  } 
  return $isolated_pointList 
}


proc ::neuro::proto_calc_morph_moved_isolated_points {node_type fileset_num x y z xrot yrot zrot } {
  # calculate all points in morphology list, but only to create a moved version of the point cloud
  # no parent-child relationships, no double-counting points.  
  # XX later, for better accuracy, consider: calculate all segments and return midpoint, since some segments may be long
  variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  # the "isolated_" term reminds this is really a point-cloud-like pointlist, without parent and other info in each element
  set isolated_rotPointList ""
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #No longer true: note the corrective -type_zrot, not true for all data sets
  #Now:type z_rot now being added to zrot 
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr  $type_zrot] rad]]
  foreach e $pointList {
    foreach {en etype ex ey ez eradius eparent} $e {}
    set v [list $ex $ey $ez]
    set vr [coordtrans $m $v]
    lappend isolated_rotPointList $vr
  } 
  return $isolated_rotPointList 
}


proc ::neuro::proto_show_morph_moved_line {node_type fileset_num x y z xrot yrot zrot radius_scale} {
  variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set rotPointList ""
  #puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
     foreach {en etype ex ey ez eradius eparent} $e {}
     #if {$en < 4} {
     #  puts "en= $en  eparent= $eparent eradius= $eradius"
     #}
    #find parent
    set parent_id $eparent 
    if {$parent_id == -1} {
       #puts "no parent: for en= $en, parent_id= $parent_id"
       #set to self if no parent.  
       #this will be the case for soma in morpho, so perhaps should do special high-res case, so can draw rest of morpho at lower/different res.  Or do so, but instead just look for soma type for the section.
       set parent_id $en
    } 
    set parent $morphoHash($fileset_num,$node_type,$parent_id)
    foreach {pen petype pex pey pez peradius peparent} $parent {}

    set v [list $ex $ey $ez]
    set vr [coordtrans $m $v]

    set pv [list $pex $pey $pez]
    set pvr [coordtrans $m $pv]

    #set radius for the current point
    # the 1-only case captures the soma only case, where there is one SWC element starrting at 1.
    if { $en == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set theRad [expr $draw_radius_scale * $eradius ] 
    }
    #set radius for parent   
    if {$pen == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set parentRad [expr $radius_scale * $draw_radius_scale  ] 
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set parentRad [expr $draw_radius_scale * $peradius ] 
    }
    #if {($parentRad > 2.0 ) || ($theRad > 2.0)} {
    # puts "pen= $pen  en=$en parentRad= $parentRad  theRad= $theRad"
    #}
    #draw a 2 element spheretube.  Later, we will draw full tree branches
    #draw spheretube [list $pvr $vr] radii [list $parentRad $theRad] drawtubes 1
    #draw line  $pvr $vr width [expr int($parentRad)]
    draw line  $pvr $vr width 1

    #if {$parentRad >= 5.0} {
    #  puts "parentRad= $parentRad"  
    #}

    #draw line  $pvr $vr
    #diagnostic spheres
    #draw color 0
    #draw sphere $pvr radius $parentRad resolution 6 
    #draw color 1
    #draw sphere $vr radius $theRad resolution 6 
  } 

}

proc ::neuro::proto_show_morph_moved_direct_soma_coordfile {node_type fileset_num x y z xrot yrot zrot radius_scale draw_color the_coordfile} {
  variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set rotPointList ""
  set non_soma_limit 3.0
  #for example, if radius_scale is 3.0, radius_scale_limit will be 9.0
  
  #puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
     foreach {en etype ex ey ez eradius eparent} $e {}
     #if {$en < 4} {
     #  puts "en= $en  eparent= $eparent eradius= $eradius"
     #}
    #find parent
    set parent_id $eparent 
    if {$parent_id == -1} {
       puts "no parent: for en= $en, parent_id= $parent_id"
       #set to self if no parent.  
       #this will be the case for soma in morpho, so perhaps should do special high-res case, so can draw rest of morpho at lower/different res.  Or do so, but instead just look for soma type for the section.
       set parent_id $en
    } 
    set parent $morphoHash($fileset_num,$node_type,$parent_id)
    foreach {pen petype pex pey pez peradius peparent} $parent {}

    set v [list $ex $ey $ez]
    set vr [coordtrans $m $v]

    set pv [list $pex $pey $pez]
    set pvr [coordtrans $m $pv]

    #set radius for the current point
    # the 1-only case captures the soma only case, where there is one SWC element starrting at 1.
    if { $etype == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set theRad [expr $draw_radius_scale * $eradius ] 
      set child_is_soma 1
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set theRad [expr $draw_radius_scale * $eradius ] 
      if {$theRad > $non_soma_limit} {
          set theRad $non_soma_limit
      }
      set child_is_soma 0
    }
    #set radius for parent   
    if {$petype == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set parentRad [expr $draw_radius_scale * $peradius ] 
      set parent_is_soma 1
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set parentRad [expr $draw_radius_scale * $peradius ] 
      if {$parentRad > $non_soma_limit} {
          set parentRad $non_soma_limit
      }
      set parent_is_soma 0
    }

     
    #
    #if {($parentRad > 2.0 ) || ($theRad > 2.0)} {
    # puts "pen= $pen  en=$en parentRad= $parentRad  theRad= $theRad"
    #}
    #draw a 2 element spheretube.  Later, we will draw full tree branches
    #Both draw onscreen and append to the file
    draw spheretube [list $pvr $vr] radii [list $parentRad $theRad] drawtubes 1
    puts $the_coordfile  "[format {%.5f %.5f %.5f} {*}$pvr] [format %.5f $parentRad] [format {%.5f %.5f %.5f} {*}$vr] [format %.5f $theRad] $draw_color $parent_is_soma $child_is_soma"
    #diagnostic spheres
    #draw color 0
    #draw sphere $pvr radius $parentRad resolution 6 
    #draw color 1
    #draw sphere $vr radius $theRad resolution 6 
  } 

}

proc ::neuro::proto_show_morph_moved_const_soma_coordfile {node_type fileset_num x y z xrot yrot zrot radius_scale draw_color the_coordfile} {
  variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set rotPointList ""
  set non_soma_limit 3.0
  #for example, if radius_scale is 3.0, radius_scale_limit will be 9.0
  
  #puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr  $type_zrot] rad]]
  foreach e $pointList {
     foreach {en etype ex ey ez eradius eparent} $e {}
     #if {$en < 4} {
     #  puts "en= $en  eparent= $eparent eradius= $eradius"
     #}
    #find parent
    set parent_id $eparent 
    if {$parent_id == -1} {
       puts "no parent: for en= $en, parent_id= $parent_id"
       #set to self if no parent.  
       #this will be the case for soma in morpho, so perhaps should do special high-res case, so can draw rest of morpho at lower/different res.  Or do so, but instead just look for soma type for the section.
       set parent_id $en
    } 
    set parent $morphoHash($fileset_num,$node_type,$parent_id)
    foreach {pen petype pex pey pez peradius peparent} $parent {}

    set v [list $ex $ey $ez]
    set vr [coordtrans $m $v]

    set pv [list $pex $pey $pez]
    set pvr [coordtrans $m $pv]

    #set radius for the current point
    # the 1-only case captures the soma only case, where there is one SWC element starrting at 1.
    if { $etype == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
      set child_is_soma 1
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set theRad [expr $draw_radius_scale * $eradius ] 
      if {$theRad > $non_soma_limit} {
          set theRad $non_soma_limit
      }
      set child_is_soma 0
    }
    #set radius for parent   
    if {$petype == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set parentRad [expr $radius_scale * $draw_radius_scale  ] 
      set parent_is_soma 1
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set parentRad [expr $draw_radius_scale * $peradius ] 
      if {$parentRad > $non_soma_limit} {
          set parentRad $non_soma_limit
      }
      set parent_is_soma 0
    }

     
    #
    #if {($parentRad > 2.0 ) || ($theRad > 2.0)} {
    # puts "pen= $pen  en=$en parentRad= $parentRad  theRad= $theRad"
    #}
    #draw a 2 element spheretube.  Later, we will draw full tree branches
    #Both draw onscreen and append to the file
    draw spheretube [list $pvr $vr] radii [list $parentRad $theRad] drawtubes 1
    puts $the_coordfile  "[format {%.5f %.5f %.5f} {*}$pvr] [format %.5f $parentRad] [format {%.5f %.5f %.5f} {*}$vr] [format %.5f $theRad] $draw_color $parent_is_soma $child_is_soma"
    #diagnostic spheres
    #draw color 0
    #draw sphere $pvr radius $parentRad resolution 6 
    #draw color 1
    #draw sphere $vr radius $theRad resolution 6 
  } 

}

proc ::neuro::proto_show_morph_moved_coordfile {node_type fileset_num x y z xrot yrot zrot radius_scale draw_color the_coordfile} {
  variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set rotPointList ""
  #puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr  $type_zrot] rad]]
  foreach e $pointList {
     foreach {en etype ex ey ez eradius eparent} $e {}
     #if {$en < 4} {
     #  puts "en= $en  eparent= $eparent eradius= $eradius"
     #}
    #find parent
    set parent_id $eparent 
    if {$parent_id == -1} {
       puts "no parent: for en= $en, parent_id= $parent_id"
       #set to self if no parent.  
       #this will be the case for soma in morpho, so perhaps should do special high-res case, so can draw rest of morpho at lower/different res.  Or do so, but instead just look for soma type for the section.
       set parent_id $en
    } 
    set parent $morphoHash($fileset_num,$node_type,$parent_id)
    foreach {pen petype pex pey pez peradius peparent} $parent {}

    set v [list $ex $ey $ez]
    set vr [coordtrans $m $v]

    set pv [list $pex $pey $pez]
    set pvr [coordtrans $m $pv]

    #set radius for the current point
    # the 1-only case captures the soma only case, where there is one SWC element starrting at 1.
    if { $en == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set theRad [expr $draw_radius_scale * $eradius ] 
    }
    #set radius for parent   
    if {$pen == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      set parentRad [expr $radius_scale * $draw_radius_scale  ] 
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set parentRad [expr $draw_radius_scale * $peradius ] 
    }
    #if {($parentRad > 2.0 ) || ($theRad > 2.0)} {
    # puts "pen= $pen  en=$en parentRad= $parentRad  theRad= $theRad"
    #}
    #draw a 2 element spheretube.  Later, we will draw full tree branches
    #draw spheretube [list $pvr $vr] radii [list $parentRad $theRad] drawtubes 1
    puts $the_coordfile  "$pvr $parentRad $vr $theRad $draw_color"
    #diagnostic spheres
    #draw color 0
    #draw sphere $pvr radius $parentRad resolution 6 
    #draw color 1
    #draw sphere $vr radius $theRad resolution 6 
  } 

}

proc ::neuro::proto_show_morph_moved_spheretube {node_type fileset_num x y z xrot yrot zrot radius_scale} {
  variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set rotPointList ""
  set non_soma_limit 3.0
  #for example, if radius_scale is 3.0, radius_scale_limit will be 9.0

  #puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
     foreach {en etype ex ey ez eradius eparent} $e {}
     #if {$en < 4} {
     #  puts "en= $en  eparent= $eparent eradius= $eradius"
     #}
    #find parent
    set parent_id $eparent 
    if {$parent_id == -1} {
       puts "no parent: for en= $en, parent_id= $parent_id"
       #set to self if no parent.  
       #this will be the case for soma in morpho, so perhaps should do special high-res case, so can draw rest of morpho at lower/different res.  Or do so, but instead just look for soma type for the section.
       set parent_id $en
    } 
    set parent $morphoHash($fileset_num,$node_type,$parent_id)
    foreach {pen petype pex pey pez peradius peparent} $parent {}

    set v [list $ex $ey $ez]
    set vr [coordtrans $m $v]

    set pv [list $pex $pey $pez]
    set pvr [coordtrans $m $pv]

    #set radius for the current point
    # the 1-only case captures the soma only case, where there is one SWC element starrting at 1.
    #XX some SWC files start numbering with 0; should really be looking for type (etype) == 1.  And hadling soma-only as special case. 
    if { $etype == 1} then {
      set draw_radius_scale 1.0
      #set sphereRes 12
      # allow soma radius to vary 
      set theRad [expr $draw_radius_scale * $eradius ] 
      #puts "en is 1:  en= $en  pen= $pen radius_scale= $radius_scale; theRad= $theRad, eradius= $eradius, peradius= $peradius"
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set theRad [expr $draw_radius_scale * $eradius ] 
      if {$theRad > $non_soma_limit} {
          set theRad $non_soma_limit
      }
    }
    #set radius for parent   
    if { $petype == 1} then {
      #puts "pen is 1: en= $en  pen= $pen radius_scale= $radius_scale; theRad= $theRad, eradius= $eradius, peradius= $peradius"
      set draw_radius_scale 1.0
      #set sphereRes 12
      # allow soma radius to vary
      set parentRad [expr $draw_radius_scale * $peradius ] 
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set parentRad [expr $draw_radius_scale * $peradius ] 
      if {$parentRad > $non_soma_limit} {
          set parentRad $non_soma_limit
      }
    }
    #puts "about to test parentRad"
    #if {($parentRad > 10.0 ) || ($theRad > 10.0)} {
    #   puts "large rad: pen= $pen  en=$en parentRad= $parentRad  theRad= $theRad"
    #}

    #if {($parentRad > 2.0 ) || ($theRad > 2.0)} {
    # puts "pen= $pen  en=$en parentRad= $parentRad  theRad= $theRad"
    #}
    #draw a 2 element spheretube.  Later, we will draw full tree branches
        
    draw spheretube [list $pvr $vr] radii [list $parentRad $theRad] drawtubes 1
    #diagnostic spheres
    #draw color 0
    #draw sphere $pvr radius $parentRad resolution 6 
    #draw color 1
    #draw sphere $vr radius $theRad resolution 6 
  }

}

proc ::neuro::proto_show_morph_moved_swc_range {node_type fileset_num x y z xrot yrot zrot radius_scale swc_beg swc_end style c_r c_g c_b} {
  variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set color_rgb_single [list $c_r $c_g $c_b] 
  set color_rgb_single_list [list [list $c_r $c_g $c_b] ]
  set color_rgb_double_list [list [list $c_r $c_g $c_b] [list $c_r $c_g $c_b] ]
  #puts "color_rgb_double_list =$color_rgb_double_list"
  set tube_res 3
  set rotPointList ""
  set sphereList ""
  set colorList ""
  set radiusList ""
  #puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
    foreach {eid etype ex ey ez eradius eparent} $e {}
    if {($eid >= $swc_beg) && ($eid <= $swc_end) } {
            #set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
      set v [list $ex $ey $ez]
      set vr [coordtrans $m $v]

      #set radius, all soma to same scale
      if {$etype == 1} then {
        set draw_radius_scale 1.0
        set theRad [expr $radius_scale * $draw_radius_scale  ] 
      } else {
        set draw_radius_scale $radius_scale
        set theRad [expr $draw_radius_scale * $eradius ] 
      } 
      if {$theRad>$radius_scale} {
        set $theRad $radius_scale
      }   
      switch $style {
        spheretube {
          #get parent info and draw parent to current (child)
          set parent_id $eparent 
          if {$parent_id == -1} {
            puts "no parent: for eid= $eid, parent_id= $parent_id"
            #set to self if no parent.  
            #this will be the case for soma in morpho, so perhaps should do special high-res case, so can draw rest of morpho at lower/different res.  Or do so, but instead just look for soma type for the section.
            set parent_id $eid
          } 

          set parent $morphoHash($fileset_num,$node_type,$parent_id)
          foreach {peid petype pex pey pez peradius peparent} $parent {}
          
          set pv [list $pex $pey $pez]
          set pvr [coordtrans $m $pv]
          if {$petype == 1} then {
            set draw_radius_scale 1.0
            set theParentRad [expr $radius_scale * $draw_radius_scale  ] 
          } else {
            set draw_radius_scale $radius_scale
            set theParentRad [expr $draw_radius_scale * $peradius ] 
          } 
          if {$theParentRad>$radius_scale} {
            set $theParentRad $radius_scale
          }   
          draw spheretube [list $pvr $vr] radii [list $theParentRad $theRad] colors $color_rgb_double_list  drawtubes 1 resolution $tube_res
        }
        sphere {
          #draw all spheres later with a single spheretube command
          lappend sphereList "[list $ex $ey $ez ]" 
          lappend colorList $color_rgb_single 
          lappend radiusList $theRad 
        }
        line {
          #get parent info and draw parent to current (child)
          set parent_id $eparent 
          if {$parent_id == -1} {
            puts "no parent: for eid= $eid, parent_id= $parent_id"
            #set to self if no parent.  
            #this will be the case for soma in morpho, so perhaps should do special high-res case, so can draw rest of morpho at lower/different res.  Or do so, but instead just look for soma type for the section.
            set parent_id $eid
          } 

          set parent $morphoHash($fileset_num,$node_type,$parent_id)
          foreach {peid petype pex pey pez peradius peparent} $parent {}
          
          set pv [list $pex $pey $pez]
          set pvr [coordtrans $m $pv]
          if {$petype == 1} then {
            set draw_radius_scale 1.0
            set theParentRad [expr $radius_scale * $draw_radius_scale  ] 
          } else {
            set draw_radius_scale $radius_scale
            set theParentRad [expr $draw_radius_scale * $peradius ] 
          } 
          if {$theParentRad>$radius_scale} {
            set $theParentRad $radius_scale
          }   
          #color setting is the problem here - need color scale of countable colors
          draw line $pvr $vr width [expr int ($parentRad)
        }
        default {
          puts "error: style for swc compartment must be spheretube or sphere"
        }
      }
    }
  }

  if {$style == "spheretube" } { 
    draw spheretube "$sphereList" radii $radiusList colors $colorList drawtubes 0 resolution $tube_res
  }

}




proc ::neuro::proto_show_morph_moved {node_type fileset_num x y z xrot yrot zrot radius_scale {sphereRes 4}} {
  #variable morphoHash
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  set rotPointList ""
  #puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    # negative type_zrot:
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transoffset $x $y $z] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  #set movedPointList ""
  #foreach e $rotPointList {
  #  set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
  #  #puts "moved show_morph_moved l= $l"
  #  lappend movedPointList $l
  # } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  set radius_scale_limit [expr 3 * $radius_scale]
  foreach lineList $rotPointList {
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

    # XX next line sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    # Now we check for type == soma
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
      set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
    } else {
      set draw_radius_scale $radius_scale
      #set sphereRes 4 
      set theRad [expr $draw_radius_scale * [lindex $lineList 5] ] 
    } 

    # bug in commented lines - had no affect
    #if {$theRad>$radius_scale_limit} {
    #  #puts "$theRad"
    #  set $theRad $radius_scale_limit
    #}   
    lappend radiusList $theRad 
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    ##lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::proto_show_morph_moved_morph_only_count_renders {node_type fileset_num x y z xrot yrot zrot radius_scale} {
  #variable morphoHash
  #only show neurons that have biophysical morphology - this means length of pointlist > 1.  
   #XX Will also ignore any bizarre morphologies with only one point.  Maybe conceivable for placeholders, so consider a more explicit way of indicating 'no morphology associated'.
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  #   each memeber of pointlist list  is a list, following the SWC format columns:
  #       {n type x y z radius parent} 
  ##puts "length of pointlist is [llength $pointList]"
  if {[llength $pointList] <= 1} {
    return
  }
  set rotPointList ""
  ##puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    # negative type_zrot:
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transoffset $x $y $z] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  #set movedPointList ""
  #foreach e $rotPointList {
  #  set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
  #  #puts "moved show_morph_moved l= $l"
  #  lappend movedPointList $l
  # } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  foreach lineList $rotPointList {
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

    # XX next line sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      puts "node_type $node_type SOMA  -- the point RADIUS = [lindex $lineList 5]   n= [lindex $lineList 0] type= [lindex $lineList 1]"
      #lappend ::neuro_soma_log "$node_type [lindex $lineList 5]  [lindex $lineList 0] [lindex $lineList 1]"
      #set draw_radius_scale 1.0
      # if radius_scale is 3.0, theRad will be 3.0*2.66=8
      # hacky: 2.333 for soma size 7, 2.6667 for soma size 8
      set draw_radius_scale 2.333 
      set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
      puts "soma theRad= $theRad"
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
      set theRad [expr $draw_radius_scale * [lindex $lineList 5] ] 
      if {$theRad > 8.0} {set theRad [expr 1.2 * $theRad]; puts "large non-soma RADIUS= $theRad  n= [lindex $lineList 0] type= [lindex $lineList 1]"}
 #  lappend ::neuro_nonsoma_log  [list $node_type $theRad  [lindex $lineList 0] [lindex $lineList 1]]  
    } 
      #apparent failed effort to bound theRad to radius_scale
      #if {$theRad>$radius_scale} {puts "$theRad";set $theRad $radius_scale}   
      lappend radiusList $theRad 
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    ##lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::proto_show_morph_moved_morph_only {node_type fileset_num x y z xrot yrot zrot radius_scale} {
  #variable morphoHash
  #only show neurons that have biophysical morphology - this means length of pointlist > 1.  
   #XX Will also ignore any bizarre morphologies with only one point.  Maybe conceivable for placeholders, so consider a more explicit way of indicating 'no morphology associated'.
  variable typeHash
  set pointList [proto_retrieve_morphology $fileset_num $node_type ]
  #   each memeber of pointlist list  is a list, following the SWC format columns:
  #       {n type x y z radius parent} 
  ##puts "length of pointlist is [llength $pointList]"
  if {[llength $pointList] <= 1} {
    return
  }
  set rotPointList ""
  ##puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  
  #note the corrective -type_zrot, not true for all data sets
  #puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    # negative type_zrot:
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transoffset $x $y $z] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  #set movedPointList ""
  #foreach e $rotPointList {
  #  set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
  #  #puts "moved show_morph_moved l= $l"
  #  lappend movedPointList $l
  # } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  foreach lineList $rotPointList {
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

    # XX next line sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      puts "node_type $node_type SOMA  -- the point RADIUS = [lindex $lineList 5]   n= [lindex $lineList 0] type= [lindex $lineList 1]"
      #lappend ::neuro_soma_log "$node_type [lindex $lineList 5]  [lindex $lineList 0] [lindex $lineList 1]"
      #set draw_radius_scale 1.0
      # if radius_scale is 3.0, theRad will be 3.0*2.66=8
      # hacky: 2.333 for soma size 7, 2.6667 for soma size 8
      set draw_radius_scale 2.333 
      set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
      puts "soma theRad= $theRad"
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
      set theRad [expr $draw_radius_scale * [lindex $lineList 5] ] 
      if {$theRad > 8.0} {set theRad [expr 1.2 * $theRad]; puts "large non-soma RADIUS= $theRad  n= [lindex $lineList 0] type= [lindex $lineList 1]"}
 #  lappend ::neuro_nonsoma_log  [list $node_type $theRad  [lindex $lineList 0] [lindex $lineList 1]]  
    } 
      #apparent failed effort to bound theRad to radius_scale
      #if {$theRad>$radius_scale} {puts "$theRad";set $theRad $radius_scale}   
      lappend radiusList $theRad 
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    ##lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}

proc ::neuro::show_morph_moved {node_type fileset_num x y z xrot yrot zrot radius_scale} {
  variable morphoHash
  variable typeHash
  set pointList $morphoHash($fileset_num,$node_type)
  set rotPointList ""
  puts "yrot = $yrot"
  # do rotation here
  #don't set color
  #set c [expr $node_type % 32]
  #draw color $c
  #puts "in show_morph_moved, color set to $c"
  set type_zrot $typeHash(rot_zaxis,$fileset_num,$node_type)
  #puts "node_type= $node_type  type_zrot= $type_zrot"
  #note the corrective -type_zrot, not true for all data sets
  puts "transoffset $x $y $z =  [transoffset [list $x $y $z]]"
  set m [transmult  [transoffset [list $x $y $z]] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr $type_zrot] rad]]
  foreach e $pointList {
    
    # need sequential type_zrot, zrot, yrot, xrot
    # XX later, add type_xrot and type_yrot if these are ever used
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad]]
    # negative type_zrot:
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transoffset $x $y $z] [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z [expr -1.0 * $type_zrot] rad]]
    #set m [transmult  [transaxis x $xrot rad ] [transaxis y $yrot rad] [transaxis z $zrot rad] [transaxis z $type_zrot rad]]
    #set m [transaxis z $type_zrot rad]
    #set m [transaxis z 0 rad]
    set v [list [lindex $e 2] [lindex $e 3] [lindex $e 4]]
    set vr [coordtrans $m $v]
    #puts "vr = $vr, v 0 = [lindex $vr 0]"
    set l [list [lindex $e 0] [lindex $e 1] [lindex $vr 0]  [lindex $vr 1]   [lindex $vr 2]   [lindex $e 5]  [lindex $e 6]]
    #puts "rot show_morph_moved l= $l"
    lappend rotPointList $l
  } 
  #set movedPointList ""
  #foreach e $rotPointList {
  #  set l [list [lindex $e 0] [lindex $e 1] [expr [lindex $e 2] + $x]  [expr [lindex $e 3] + $y] [expr [lindex $e 4] + $z] [lindex $e 5]  [lindex $e 6]] 
  #  #puts "moved show_morph_moved l= $l"
  #  lappend movedPointList $l
  # } 
  set sphereList ""
  set radiusList ""
  set linenum 0
  foreach lineList $rotPointList {
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 

    # XX next line sets color per sphere, so per component of neuron - make this a param setting 
    ## draw color [lindex $lineList 1] 

    #don't scale soma, increase res for soma 
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
      set sphereRes 12
      set theRad [expr $radius_scale * $draw_radius_scale  ] 
    } else {
      set draw_radius_scale $radius_scale
      set sphereRes 4 
      set theRad [expr $draw_radius_scale * [lindex $lineList 5] ] 
    } 
      if {$theRad>$radius_scale} {puts "$theRad";set $theRad $radius_scale}   
      lappend radiusList $theRad 
    
    #draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution  $sphereRes 
    lappend sphereList "[list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]"
    ##lappend radiusList  [expr $draw_radius_scale * [lindex $lineList 5] ] 
    #puts "$linenum: [lrange $radiusList 0 4], "
    #puts "[lrange $sphereList 0 4], "
    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
  draw spheretube "$sphereList" radii $radiusList drawtubes 0
  #draw spheretube "$sphereList" radii $radiusList drawtubes 1
}


proc ::neuro::show_morph {fileset_num node_type radius_scale} {
  variable morphoHash
  foreach lineList $morphoHash($fileset_num,$node_type) {
    #puts "lineList=$lineList"
    #set enum 0
    #foreach e $lineList {
    #   if {$e < 0.0} {set e 0.0}
    #   set mat($linenum,$enum) [expr $e + 0.0]
    #   incr enum
    #} 
    #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 
    #puts "draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}  radius [lindex $lineList 5] resolution 6" 
     
    draw color [lindex $lineList 1] 
    #don't scale soma 
    if {[lindex $lineList 1] == 1} then {
      set draw_radius_scale 1.0
    } else {
      set draw_radius_scale $radius_scale
    } 
       
    
    draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution 12 

    #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
    #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
    incr linenum
  }
}




proc ::neuro::read_swc {filename radius_scale} {
  set fp [open $filename r]
  set linenum 0
  while { [gets $fp myline] >=0} {
  #puts "linenum= $linenum; DATA: >$myline<"
      #skip comments
      if {[string first \# $myline] != 0} {
        set lineList [split $myline]
        #set enum 0
        #foreach e $lineList {
        #   if {$e < 0.0} {set e 0.0}
        #   set mat($linenum,$enum) [expr $e + 0.0]
        #   incr enum
        #} 
        #puts "1:[lindex $lineList 2] 2:[lindex $lineList 3] 3:[lindex $lineList 4]  4:[lindex $lineList 5]" 
        #puts "draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}  radius [lindex $lineList 5] resolution 6" 
         
        draw color [lindex $lineList 1] 
        #don't scale soma 
        if {[lindex $lineList 1] == 1} then {
          set draw_radius_scale 1.0
        } else {
          set draw_radius_scale $radius_scale
        } 
           

        draw sphere [list [lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4] ]  radius [expr $draw_radius_scale * [lindex $lineList 5] ] resolution 12 

        #draw sphere "{[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]}"  radius [lindex $lineList 5] resolution 8
        #draw sphere {[lindex $lineList 2] [lindex $lineList 3] [lindex $lineList 4]} radius  [lindex $lineList 5] resolution 8" 
        incr linenum
    }
  }
  #set matSize $linenum
  #puts "mat(0,0)=$mat(0,0), matSize= $matSize"
  close $fp
}

proc ::neuro::read_store_spike_csv {filenamestart filenameend} {
  variable spikeList
  set spikecsvfilename "${filenamestart}${filenameend}"
  set spikeList ""
  #add zero-fill vectors at length of idv above for any empty file names
  set thefile [open $spikecsvfilename r]
  while { [gets $thefile myline] >=0} {
    set vec [split $myline]
    #store as: node_id spiketime (gid can work for node_id sometimes, but makes assumptions, depends how used, see SONATA gid discussion on web)
    set e [list [lindex $vec 1] [lindex $vec 0]] 
    lappend spikeList $e
  }
  close $thefile
   
  set spikeList [lsort -real -index 1 $spikeList] 
  puts "spikeList has [llength $spikeList] elements"
  return
}

proc ::neuro::read_store_spike {filenamestart filenameend} {
  variable spikeList
  set spikefilename "${filenamestart}timestamps${filenameend}"
  set idfilename "${filenamestart}node_ids${filenameend}"
  #add zero-fill vectors at length of idv above for any empty file names
  foreach vec {idv spiketimev} fn {idfilename spikefilename} {
    set thefilename [set $fn]
    puts "vec= $vec thefilename= $thefilename"
    if {$thefilename != ""} {
      #XX exit with error if idfilename
      #XX count idv size when it is made, then make idv-long zero-fill here
      puts "opened $thefilename"
      set thefile [open $thefilename r]
      # XXX change so works for something that is not last line in file
      while { [gets $thefile myline] >=0} {
        set $vec [split $myline]
      }
      close $thefile
   }
  }

  #XX only show yrot so far, add zero-fill compensators at length of idv above for any empty
  set spikeList ""
  foreach eid $idv espiketime $spiketimev {
    #XX FIX with zero filling so can handle absent rots
    set e [list $eid $espiketime]
    
    lappend spikeList $e
  }
  set spikeList [lsort -real -index 1 $spikeList] 
  puts "spikeList has [llength $spikeList] elements"
  return
} 

proc ::neuro::show_spike_timing_morph_from_list_render {start end filenamestart filenameend rotinc subsetNodeIdList stride windowSize molidForGraphics waitTime {rad_scale 4} } {
  set theFrame 0
  mol top $molidForGraphics
  variable spikeList
  variable node
  puts "length spikeList is [llength $spikeList]"
  set invWinSizeIncr [expr 1.0 / ($windowSize + 1)]               
  for {set t $start} {$t<=$end} {set t [expr $t + $stride]} {
    set rangeEnd [expr $t + $windowSize]
    #puts "$t rangeEnd = $rangeEnd" 
    set showList ""
    set fadeList ""
    foreach e $spikeList {
      set val [lindex $e 1]
      set spikeNodeId [lindex $e 0]
      if {($val>=$t) && ($val<=$rangeEnd)} {
        #puts "t=$t, val=$val  rangeEnd= $rangeEnd"
        foreach theId $subsetNodeIdList {
          if {$spikeNodeId == $theId} {
            lappend showList $e 
            lappend fadeList [expr  1 - (($start - $t) * $invWinSizeIncr) ]
            # linear scale for alpha, 1.0 at time t, scaled so smoothly to 0 at $windowsize +1] 
          }
        }
      }
    } 
    display update off
    draw delete all
    puts "Range $t to $rangeEnd  length showList= [llength $showList]" 
    foreach e $showList {
      set n [lindex $e 0]
      set p $node($n)
      #puts "p= $p"
      set c [expr [lindex $p 6] % 32 ] 
      #draw color $c
      #force to white
      draw color 8 

      #puts "show_morph_moved [lindex $p 6] [lindex $p 0] [lindex $p 1] [lindex $p 2]  [lindex $p 3] [lindex $p 4] [lindex $p 5]  3"
      show_morph_moved [lindex $p 6] [lindex $p 7] [lindex $p 0] [lindex $p 1] [lindex $p 2]  [lindex $p 3] [lindex $p 4] [lindex $p 5] $rad_scale 
      #draw sphere [list [lindex $p 0] [lindex $p 1] [lindex $p 2]] radius 8 resolution 12
    }
    display update on
    display update
    set fname "$filenamestart[format %05d $theFrame]$filenameend"
    render TachyonLOptiXInternal $fname  
    incr theFrame
    rotate y by $rotinc
    after $waitTime
  }
}

proc ::neuro::cmd_show_spike_pop_seqeunce_from_fullsel {style colorMethod material rad_scale sph_resolution full_selection_string start end pop node_stride time_stride windowSize waitTime {zoomscale .25} {v1_special_skip False} } {
  #show sequence of spikes in OpenGL window
  # X  later: include all pops in selection, instead of specifying a single pop
  #waitTime is in ms
  # add option for rendering?
  # zoomscale is temp hack, must address size of viewing box
  variable globalNodeIdList
  variable spikeHash
  set molidTopAtCall [molinfo top]
  set molidForGraphics [mol new]
  display resetview
  #scale by $zoomscale

  if {$v1_special_skip} {
     #XX hack for showing v1 
     set displayableGlobalNodeIdList [stride_list_skip_special 1 $globalNodeIdList]
  } else {
    set displayableGlobalNodeIdList $globalNodeIdList 
  }

  set myNodeIdList [stride_list $node_stride [parse_full_selection_string $full_selection_string node] ]

  #loop to show a series of moments


  if {[catch {set spikeLength  [llength $spikeHash(spikeList,$pop)]}]} {
    puts "ERROR: spike time series has not been loaded for population: $pop"
    return 1
  }
      
  for {set t $start} {$t<=$end} {set t [expr $t + $time_stride]} {
    show_spike_pop_moment_from_list  $style $colorMethod $material $rad_scale $sph_resolution  $t [expr $t + $windowSize -1] $pop $myNodeIdList $windowSize $molidForGraphics 
    after $waitTime
  }
}

proc ::neuro::show_spike_pop_moment_from_list  {style colorMethod material rad_scale sph_resolution  start end pop subsetNodeIdList windowSize molidForGraphics } {
  variable spikeHash
  variable node
  puts "length spikeHash(spikeList,$pop) is [llength $spikeHash(spikeList,$pop)]"
  set invWinSizeIncr [expr 1.0 / ($windowSize + 1)]               
  set rangeEnd $end 
  #puts "$t rangeEnd = $rangeEnd" 
  set showList ""
  set fadeList ""

  foreach spike  $spikeHash(spikeList,$pop) {
    set val [lindex $spike 1]
    set spikeNodeId [lindex $spike 0]
    if {($val>=$start) && ($val<=$rangeEnd)} {
      #puts "start=$start, val=$val  rangeEnd= $rangeEnd"
      foreach theId $subsetNodeIdList {
        foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
        if {($spikeNodeId eq $enode_id) && ($pop eq $epop)} {
          #lappend showList $spike 
          # record the global node id, for use by node()
          lappend showList [list $theId $val]
          lappend fadeList [expr  1 - (($start - $val) * $invWinSizeIncr) ]
          # linear scale for alpha, 1.0 at time start, scaled so smoothly to 0 at $windowsize +1] 
          # X limit fade scaling so never negative
        }
      }
    } 
  } 
  mol top $molidForGraphics
  display update off
  draw delete all
  if {$colorMethod!="Type"} {
    draw color $colorMethod
    puts "set assigned color $colorMethod" 
  }
  puts "Range $start  to $rangeEnd  length showList= [llength $showList]" 
  foreach e $showList fade $fadeList {
    set n [lindex $e 0]
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($n) {}
    set p $node($n)
    #puts "p= $p"
    if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
    }
    draw material $material
    switch $style {
      soma { proto_show_morph_moved_soma_only $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale}
      morphology_draft {proto_show_morph_moved $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale}
      morphology {proto_show_morph_moved_spheretube $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale}
      default {showError "style $style not recognized"
        return -1
      }
    }
    #proto_show_morph_moved_soma_only $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale
    #puts "show_morph_moved [lindex $p 6] [lindex $p 0] [lindex $p 1] [lindex $p 2]  [lindex $p 3] [lindex $p 4] [lindex $p 5]  3"
    #show_morph_moved [lindex $p 6] [lindex $p 0] [lindex $p 1] [lindex $p 2]  [lindex $p 3] [lindex $p 4] [lindex $p 5] $rad_scale
    #draw sphere [list [lindex $p 0] [lindex $p 1] [lindex $p 2]] radius 8 resolution 12
  }
  display update on
  display update
}

proc ::neuro::halo_spike_timing_morph_from_list {start end subsetNodeIdList stride windowSize molidForGraphics waitTime halo_radius halo_color halo_label} {
  mol top $molidForGraphics
  variable spikeList
  variable node
  puts "length spikeList is [llength $spikeList]"
  set invWinSizeIncr [expr 1.0 / ($windowSize + 1)]               
  for {set t $start} {$t<=$end} {set t [expr $t + $stride]} {
    set rangeEnd [expr $t + $windowSize]
    #puts "$t rangeEnd = $rangeEnd" 
    set showList ""
    set fadeList ""
    foreach e $spikeList {
      set val [lindex $e 1]
      set spikeNodeId [lindex $e 0]
      if {($val>=$t) && ($val<=$rangeEnd)} {
        #puts "t=$t, val=$val  rangeEnd= $rangeEnd"
        foreach theId $subsetNodeIdList {
          if {$spikeNodeId == $theId} {
            lappend showList $e 
            lappend fadeList [expr  1 - (($start - $t) * $invWinSizeIncr) ]
            # linear scale for alpha, 1.0 at time t, scaled so smoothly to 0 at $windowsize +1] 
          }
        }
      }
    } 
    display update off
    draw delete all
    puts "Range $t to $rangeEnd  length showList= [llength $showList]" 
    foreach e $showList {
      set n [lindex $e 0]
      set p $node($n)
      #puts "p= $p"
      set c [expr [lindex $p 6] % 32 ] 
      #draw color $c
      #force to white
      draw color 8 

      halo_morph_moved [lindex $p 6] [lindex $p 7] [lindex $p 0] [lindex $p 1] [lindex $p 2]  [lindex $p 3] [lindex $p 4] [lindex $p 5] 3   "/tmp/out.xyz" $halo_radius $halo_color $halo_label
      #draw sphere [list [lindex $p 0] [lindex $p 1] [lindex $p 2]] radius 8 resolution 12
    }
    display update on
    display update
    after $waitTime
  }
}

proc ::neuro::show_spike_timing_from_list {start end subsetNodeIdList stride windowSize molidForGraphics waitTime} {
  mol top $molidForGraphics
  variable spikeList
  variable node
  puts "length spikeList is [llength $spikeList]"
  set invWinSizeIncr [expr 1.0 / ($windowSize + 1)]               
  for {set t $start} {$t<=$end} {set t [expr $t + $stride]} {
    set rangeEnd [expr $t + $windowSize]
    #puts "$t rangeEnd = $rangeEnd" 
    set showList ""
    set fadeList ""
    foreach e $spikeList {
      set val [lindex $e 1]
      set spikeNodeId [lindex $e 0]
      if {($val>=$t) && ($val<=$rangeEnd)} {
        #puts "t=$t, val=$val  rangeEnd= $rangeEnd"
        foreach theId $subsetNodeIdList {
          if {$spikeNodeId == $theId} {
            lappend showList $e 
            lappend fadeList [expr  1 - (($start - $t) * $invWinSizeIncr) ]
            # linear scale for alpha, 1.0 at time t, scaled so smoothly to 0 at $windowsize +1] 
          }
        }
      }
    } 
    display update off
    draw delete all
    puts "Range $t to $rangeEnd  length showList= [llength $showList]" 
    foreach e $showList {
      set n [lindex $e 0]
      set p $node($n)
      #puts "p= $p"
      set c [expr [lindex $p 6] % 32 ] 
      #draw color $c
      #force to white
      draw color 8 
      draw sphere [list [lindex $p 0] [lindex $p 1] [lindex $p 2]] radius 8 resolution 12
    }
    display update on
    display update
    after $waitTime
  }
}


proc ::neuro::show_spike_timing {start end stride windowSize molidForGraphics waitTime} {
  mol top $molidForGraphics
  variable spikeList
  variable node
  puts "length spikeList is [llength $spikeList]"
  set invWinSizeIncr [expr 1.0 / ($windowSize + 1)]               
  for {set t $start} {$t<=$end} {set t [expr $t + $stride]} {
    set rangeEnd [expr $t + $windowSize]
    #puts "$t rangeEnd = $rangeEnd" 
    set showList ""
    set fadeList ""
    foreach e $spikeList {
      set val [lindex $e 1]
      if {($val>=$t) && ($val<=$rangeEnd)} {
        #puts "t=$t, val=$val  rangeEnd= $rangeEnd"
        lappend showList $e
        # linear scale for alpha, 1.0 at time t, scaled so smoothly to 0 at $windowsize +1] 
        lappend fadeList [expr  1 - (($start - $t) * $invWinSizeIncr) ]
      }
    } 
    display update off
    draw delete all
    puts "Range $t to $rangeEnd  length showList= [llength $showList]" 
    foreach e $showList {
      set n [lindex $e 0]
      set p $node($n)
      #puts "p= $p"
      set c [expr [lindex $p 6] % 32 ] 
      draw color $c
      draw sphere [list [lindex $p 0] [lindex $p 1] [lindex $p 2]] radius 8 resolution 12
    }
    display update on
    display update
    after $waitTime
  }
}


#proc ::neuro::read_store_nodes {filenamestart filenameend y_rot_only} {
#  error "outdated proc"
#  return
#
#  variable node
#  variable morphoHash 
#  variable globalNodeIdList
#  set xfilename "${filenamestart}x${filenameend}"
#  set yfilename "${filenamestart}y${filenameend}"
#  set zfilename "${filenamestart}z${filenameend}"
#  set typefilename "${filenamestart}node_type${filenameend}"
#  set idfilename "${filenamestart}node_id${filenameend}"
#  set xaxisfilename "${filenamestart}rotation_angle_xaxis${filenameend}"
#  set yaxisfilename "${filenamestart}rotation_angle_yaxis${filenameend}"
#  set zaxisfilename "${filenamestart}rotation_angle_zaxis${filenameend}"
#  if {$y_rot_only} {
#    set xaxisfilename ""
#    set zaxisfilename ""
#   
#  } else {
#    set xaxisfilename "${filenamestart}rotation_angle_xaxis${filenameend}"
#    set zaxisfilename "${filenamestart}rotation_angle_zaxis${filenameend}"
#  }
#  #XX only show yrot so far, add zero-fill compensators at length of idv above for any empty file names
#  foreach vec {idv xv yv zv xrotv yrotv zrotv typev} fn {idfilename xfilename yfilename zfilename xaxisfilename yaxisfilename zaxisfilename typefilename} {
#    set thefilename [set $fn]
#    puts "vec= $vec thefilename= $thefilename"
#    if {$thefilename != ""} {
#      #count idfilename vector size, this file is read before all others
#      set thefile [open $thefilename r]
#      # XXX change so works for entries that are not last line in file
#      while { [gets $thefile myline] >=0} {
#        set $vec [split $myline]
#      }
#      if {$vec == "idv"} {
#        set theVecLength [llength $idv]
#        puts "read_store_nodes theVecLength = $theVecLength"
#      }
#      close $thefile
#    } else {
#      #XX add better error check for idv
#      #exit with error if no idv, thus no idfilename 
#      if {$vec == "idv"} {
#        puts "ERROR: read_store_nodes needs id file name"
#        return
#      }
#      for {set i 0} {$i<$theVecLength} {incr i} {
#        lappend $vec 0
#      }
#      puts "set $vec to 0 vector with length [llength [set $vec]]"
#    }
#  } 
# # now assign to nodes 
#  set globalNodeIdList ""
#  foreach eid $idv ex $xv ey $yv ez $zv exrot $xrotv eyrot $yrotv  ezrot $zrotv etype $typev {
#
#
#    ##XX FIX with zero filling so can handle absent rots
#    ##set exrot 0
#    ##set ezrot 0
#    set node($eid) [list $ex $ey $ez $exrot $eyrot $ezrot $etype]
#    
#    lappend globalNodeIdList $eid
#  }
#  
#} 

proc ::neuro::show_nodes_from_list_soma_only_color {theColor subsetNodeIdList} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    set c [expr $etype % 32 ] 
    draw color $c
    puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved_soma_only_color $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3 $theColor
    incr n
  }
}

proc ::neuro::show_nodes_from_list_radprescale_oldspheres {radprescale subsetNodeIdList} {

  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype} $node($theId) {}
    #puts "list elem: $n  theId: $theId line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    #set c [expr $etype % 32 ] 
    #draw color $theColor
    #puts "set color to $theColor" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved_oldspheres $etype $ex $ey $ez $exrot $eyrot $ezrot [expr 3 * $radprescale] 
    incr n
  }
}



proc ::neuro::show_nodes_from_list_color_radprescale {theColor radprescale subsetNodeIdList} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    #set c [expr $etype % 32 ] 
    draw color $theColor
    puts "set color to $theColor" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved_color $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot [expr 3 * $radprescale] $theColor
    incr n
  }
}


proc ::neuro::show_nodes_from_list_soma_only_single_color {subsetNodeIdList theColor radPreScale} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node
  variable typeHash
  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    #set c [v1_color_map $typeHash(popName,$efileset,$etype)]
    #set c [expr $etype % 32 ] 
    draw color $theColor
    puts "set color to $theColor" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved_soma_only $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $radPreScale
    incr n
  }
}

proc ::neuro::show_nodes_from_list_single_color {subsetNodeIdList theColor} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node
  variable typeHash
  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    draw color $theColor
    puts "set color to $theColor" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved $etype $ex $ey $ez $exrot $eyrot $ezrot 3
    incr n
  }
}

proc ::neuro::show_nodes_from_list_soma_v1_color {subsetNodeIdList {radius_scale 3}} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node
  variable typeHash
  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    set c [v1_color_map $typeHash(popName,$efileset_num,$etype)]
    draw color $c
    puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved_soma_only  $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $radius_scale
    incr n
  }
}

proc ::neuro::show_nodes_from_list_v1_color {subsetNodeIdList} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node
  variable typeHash
  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    set c [v1_color_map $typeHash(popName,$efileset_num,$etype)]
    #set c [expr $etype % 32 ] 
    draw color $c
    puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved $etype $ex $ey $ez $exrot $eyrot $ezrot 3
    incr n
  }
}

proc ::neuro::halo_nodes_soma_only_bygroup_from_list {subsetNodeIdList halo_color halo_radius {group_label ""} } {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc

  set tempFilename "/tmp/out.xyz" 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  set combSphereList ""
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype} $node($theId) {}
    #puts "list elem: $n  theId: $theId line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    #set c [expr $etype % 32 ] 
    #draw color $c
    #puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    #set sphereList [sphereList_morph_moved $etype $ex $ey $ez $exrot $eyrot $ezrot] 
    #puts $sphereList
    puts "pre-append length of combSphereList is [llength $combSphereList]"
    #puts "length of sphereList is [llength $sphereList]"
    lappend combSphereList [list $ex $ey $ez]
    puts "length of combSphereList is [llength $combSphereList]"
    incr n
  }
  #count spheres for XYZ file
  set sphereCount [llength $combSphereList]
  #puts $combSphereList
  puts "sphereCount = $sphereCount"
  set fp [open $tempFilename w]
  puts $fp $sphereCount
  puts $fp "Halo - $group_label"
  foreach e $combSphereList {
    puts $fp "CA [lindex $e 0] [lindex $e 1] [lindex $e 2]" 
  }
  close $fp
  set haloMol [mol new $tempFilename]
  mol rename $haloMol "halo $group_label"
  puts "added haloMol $haloMol"
  set haloSel [atomselect $haloMol "all"]
  $haloSel set radius $halo_radius 
  mol modstyle 0 $haloMol QuickSurf 1.200000 1.700000 1.200000 1.000000 
  mol modmaterial 0 $haloMol GlassBubble
  mol modcolor 0 $haloMol ColorID $halo_color
  return $sphereCount
}

proc ::neuro::halo_nodes_bygroup_from_list {subsetNodeIdList halo_radius halo_color {group_label ""} } {
  # XXX creates merged, blobby results
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc

  set tempFilename "/tmp/out.xyz" 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  set combSphereList ""
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    #set c [expr $etype % 32 ] 
    #draw color $c
    #puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    set sphereList [sphereList_morph_moved $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot] 
    #puts $sphereList
    puts "pre-append length of combSphereList is [llength $combSphereList]"
    puts "length of sphereList is [llength $sphereList]"
    foreach e $sphereList {
      lappend combSphereList $e 
    }
    puts "length of combSphereList is [llength $combSphereList]"
    incr n
  }
  #count spheres for XYZ file
  set sphereCount [llength $combSphereList]
  #puts $combSphereList
  puts "sphereCount = $sphereCount"
  set fp [open $tempFilename w]
  puts $fp $sphereCount
  puts $fp "Halo - $group_label"
  foreach e $combSphereList {
    puts $fp "CA [lindex $e 0] [lindex $e 1] [lindex $e 2]" 
  }
  close $fp
  set haloMol [mol new $tempFilename]
  mol rename $haloMol "halo $group_label"
  puts "added haloMol $haloMol"
  set haloSel [atomselect $haloMol "all"]
  $haloSel set radius $halo_radius 
  mol modstyle 0 $haloMol QuickSurf 1.200000 1.700000 1.200000 1.000000 
  mol modmaterial 0 $haloMol GlassBubble
  mol modcolor 0 $haloMol ColorID $halo_color
  return $sphereCount
}


proc ::neuro::halo_nodes_from_list {subsetNodeIdList halo_radius halo_color} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    set c [expr $etype % 32 ] 
    draw color $c
    puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    set halo_label "id $theId"
    halo_morph_moved $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3 "/tmp/out.xyz" $halo_radius $halo_color $halo_label
    incr n
  }
}

proc ::neuro::proto_show_nodes_from_list_single_swc_segment {subsetNodeIdList swc_segment theColor} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
  puts "proto_show_nodes   swc_segment = $swc_segment"
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    #set c [expr $etype % 32 ] 
    set c $theColor
    draw color $c
    puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    proto_show_morph_moved_swc_segment $etype $fileset_num $ex $ey $ez $exrot $eyrot $ezrot 3 $swc_segment
    incr n
  }
}

proc ::neuro::proto_show_nodes_from_list_morph_only_offset_v1_color {subsetNodeIdList offset_vector} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node
  variable typeHash

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach {ov_x ov_y ov_z} $offset_vector {}
 
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    set shifted_x [expr $ex + $ov_x]
    set shifted_y [expr $ey + $ov_y]
    set shifted_z [expr $ez + $ov_z]
    puts "list elem: $n  theId: $theId line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    #set c [expr $etype % 32 ] 
    set c [v1_color_map $typeHash(popName,$efileset_num,$etype)]
    draw color $c
    puts "in proto_show_nodes_from_list_morph_only_offset_v1_color --  set color to $c in " 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    proto_show_morph_moved_morph_only $etype $efileset_num $shifted_x $shifted_y $shifted_z $exrot $eyrot $ezrot 3
    incr n
  }
}

proc ::neuro::proto_show_nodes_from_list_morph_only_offset {subsetNodeIdList offset_vector} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach {ov_x ov_y ov_z} $offset_vector {}
 
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    set shifted_x [expr $ex + $ov_x]
    set shifted_y [expr $ey + $ov_y]
    set shifted_z [expr $ez + $ov_z]
    #puts "list elem: $n  theId: $theId line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    set c [expr $etype % 32 ] 
    # avoid black
    if {$c == 16} {set c 31}
    draw color $c
    #puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    proto_show_morph_moved_morph_only $etype $efileset_num $shifted_x $shifted_y $shifted_z $exrot $eyrot $ezrot 3
    incr n
  }
}

proc ::neuro::proto_show_nodes_from_list_morph_only {subsetNodeIdList} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    set c [expr $etype % 32 ] 
    draw color $c
    puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    proto_show_morph_moved_morph_only $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3
    incr n
  }
}

proc ::neuro::proto_show_nodes_from_list_morpho_line {subsetNodeIdList colorMethod} {
  #XX merge this proc with similar procs and use style
  # Display the nodes with morphology 
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0

  if {$colorMethod!="Type"} {
    #look up color name, set a default if not found
    if [catch {set c [colorinfo index $colorMethod]}] {
       set c 8
     }
    draw color $c
    puts "set assigned color $c" 
  }


  puts "about to display [llength $subsetNodeIdList] nodes"
  status_bar_processing_start [llength $subsetNodeIdList];

  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    if {$ecartesian} {
      #only draw if this node has Cartesian coordinates for soma
    
      if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
      }
      #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
      ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
      #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
      proto_show_morph_moved_line $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3
      incr n
    }
    incr ::NeuronVND::statusPbarVal; # update gui progress bar  
    update
  }
}

proc ::neuro::proto_show_nodes_from_list_morpho_exact_soma_coordfile {subsetNodeIdList colorMethod coordfile_name {width_scale_min 1} {width_scale_max 1} } {
  #  constant (fixed) soma radius 
  # Display the nodes with morphology 
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  # open in append mode.  Helps for calling multiple times in succession to show many reps.
  # for GUI or single command to  render all reps , should use differently for output, and start with new file, with user if file exists 
  set the_coordfile [open $coordfile_name a]
  set node_radius 1 
  set node_scale 1
  set n 0
  #set default_rad_scale 3
  set default_rad_scale 1
  set width_scale_max_min [expr $width_scale_max - $width_scale_min]
  if {$width_scale_max_min < 0.0} {set width_scale_max_min [expr - $width_scale_max_min]}

  if {$colorMethod!="Type"} {
    set c $colorMethod
    draw color $c
    puts "set assigned color $c" 
  }



  puts "about to display [llength $subsetNodeIdList] nodes"
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    if {$ecartesian} {
      #only draw if this node has Cartesian coordinates for soma
    
      if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
      }
      # now adjust for color-based width changes by changing rad_scale 
      set rad_scale [expr $default_rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]

      #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
      ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
      #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
      proto_show_morph_moved_direct_soma_coordfile $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale $c $the_coordfile
      incr n
    }
  }
  close $the_coordfile
}

proc ::neuro::proto_show_nodes_from_list_morpho_direct_soma_coordfile {subsetNodeIdList colorMethod coordfile_name {width_scale_min 1} {width_scale_max 1} } {
  #  constant (fixed) soma radius 
  # Display the nodes with morphology 
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  # open in append mode.  Helps for calling multiple times in succession to show many reps.
  # for GUI or single command to  render all reps , should use differently for output, and start with new file, with user if file exists 
  set the_coordfile [open $coordfile_name a]
  set node_radius 1 
  set node_scale 1
  set n 0
  set default_rad_scale 3
  set width_scale_max_min [expr $width_scale_max - $width_scale_min]
  if {$width_scale_max_min < 0.0} {set width_scale_max_min [expr - $width_scale_max_min]}

  if {$colorMethod!="Type"} {
    set c $colorMethod
    draw color $c
    puts "set assigned color $c" 
  }



  puts "about to display [llength $subsetNodeIdList] nodes"

  .neuron.status.pbar configure -maximum [llength $subsetNodeIdList]; # define maximum gui progress bar
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    if {$ecartesian} {
      #only draw if this node has Cartesian coordinates for soma
    
      if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
      }
      # now adjust for color-based width changes by changing rad_scale 
      set rad_scale [expr $default_rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]

      #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
      ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
      #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
      proto_show_morph_moved_direct_soma_coordfile $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale $c $the_coordfile
      incr n
    }
    incr ::NeuronVND::statusPbarVal; # update gui progress bar
    update
  }
  close $the_coordfile
}

proc ::neuro::proto_show_nodes_from_list_morpho_const_soma_coordfile {subsetNodeIdList colorMethod coordfile_name {width_scale_min 1} {width_scale_max 1} } {
  #  constant (fixed) soma radius 
  # Display the nodes with morphology 
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  # open in append mode.  Helps for calling multiple times in succession to show many reps.
  # for GUI or single command to  render all reps , should use differently for output, and start with new file, with user if file exists 
  set the_coordfile [open $coordfile_name a]
  set node_radius 1 
  set node_scale 1
  set n 0
  set default_rad_scale 3
  set width_scale_max_min [expr $width_scale_max - $width_scale_min]
  if {$width_scale_max_min < 0.0} {set width_scale_max_min [expr - $width_scale_max_min]}

  if {$colorMethod!="Type"} {
    set c $colorMethod
    draw color $c
    puts "set assigned color $c" 
  }



  puts "about to display [llength $subsetNodeIdList] nodes"
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    if {$ecartesian} {
      #only draw if this node has Cartesian coordinates for soma
    
      if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
      }
      # now adjust for color-based width changes by changing rad_scale 
      set rad_scale [expr $default_rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]

      #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
      ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
      #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
      proto_show_morph_moved_const_soma_coordfile $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale $c $the_coordfile
      incr n
    }
  }
  close $the_coordfile
}
proc ::neuro::proto_show_nodes_from_list_morpho_coordfile {subsetNodeIdList colorMethod coordfile_name {width_scale_min 1} {width_scale_max 1} } {
  #XX merge this proc with similar procs and use style
  # Display the nodes with morphology 
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  # open in append mode.  Helps for calling multiple times in succession to show many reps.
  # for GUI or single command to  render all reps , should use differently for output, and start with new file, with user if file exists 
  set the_coordfile [open $coordfile_name a]
  set node_radius 1 
  set node_scale 1
  set n 0
  set default_rad_scale 3
  set width_scale_max_min [expr $width_scale_max - $width_scale_min]
  if {$width_scale_max_min < 0.0} {set width_scale_max_min [expr - $width_scale_max_min]}

  if {$colorMethod!="Type"} {
    set c $colorMethod
    draw color $c
    puts "set assigned color $c" 
  }



  puts "about to display [llength $subsetNodeIdList] nodes"
  
  .neuron.status.pbar configure -maximum [llength $subsetNodeIdList]; # define maximum gui progress bar
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    if {$ecartesian} {
      #only draw if this node has Cartesian coordinates for soma
    
      if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
      }
      # now adjust for color-based width changes by changing rad_scale 
      set rad_scale [expr $default_rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]

      #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
      ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
      #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
      proto_show_morph_moved_coordfile $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale $c $the_coordfile
      incr n
    }
    incr ::NeuronVND::statusPbarVal; # update gui progress bar
    update
  }
  close $the_coordfile
}

proc ::neuro::proto_show_nodes_from_list_morpho_spheretube {subsetNodeIdList colorMethod {width_scale_min 1} {width_scale_max 1} } {
  #XX merge this proc with similar procs and use style
  # Display the nodes with morphology 
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  set default_rad_scale 3
  set width_scale_max_min [expr $width_scale_max - $width_scale_min]
  if {$width_scale_max_min < 0.0} {set width_scale_max_min [expr - $width_scale_max_min]}

  if {$colorMethod!="Type"} {
    #look up color name, set a default if not found
    if [catch {set c [colorinfo index $colorMethod]}] {
       set c 8
     }
    draw color $c
    puts "set assigned color $c" 
  }


  puts "about to display [llength $subsetNodeIdList] nodes"
  status_bar_processing_start [llength $subsetNodeIdList];
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    if {$ecartesian} {
      #only draw if this node has Cartesian coordinates for soma
    
      if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
      }
      # now adjust for color-based width changes by changing rad_scale 
      set rad_scale [expr $default_rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]

      #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
      ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
      #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
      proto_show_morph_moved_spheretube $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale 
      incr n
    }
    incr ::NeuronVND::statusPbarVal; # update gui progress bar  
    update
  }
}

proc ::neuro::proto_show_node_swc_range {globalNodeId swc_beg swc_end val_min val_max val style colorMethod } {
  # display a range of swc segments
  # coor by val 
  #variable globalNodeIdList
  
  variable node
  variable colorscale
  variable colorscale_index_offset
  set node_radius 1 
  set node_scale 1
  set n 0


  #if {$colorMethod!="Type"} {
  #  draw color $colorMethod
  #  puts "set assigned color $colorMethod" 
  #}

  set theId $globalNodeId 
  #send to a function
  if {$colorMethod=="WhiteToBlack"} {
    set colorMethod "WBlack"
  }
  if {$colorMethod=="BlackToWhite"} {
    set colorMethod "BlackW"
  }
  if {$colorMethod=="BlueToRed"} {
    set colorMethod "BGR"
  }
  if {$colorMethod=="RedToBlue"} {
    set colorMethod "RGB"
  }
  
  if {$colorMethod=="WBlack"} {
     set  0
  }
  if {$colorMethod=="BlackW"} {
    set cm 1
  }
  if {$colorMethod=="BGR"} {
     set cm 2
  }
  if {$colorMethod=="RGB"} {
     set cm 3 
  } 
  #for now, only using VMD internal color scales for soma spheres
  #using the internal VND array for morphology 
  color scale method $colorMethod
  
  foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
  #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
  if {$ecartesian} {
    #only draw if this node has Cartesian coordinates for soma
      
     
    set val_scaled [expr int (255 * ( ($val -$val_min) / ($val_max - $val_min)) )]
    set val_scaled_1024 [expr int (1023 *( ($val -$val_min) / ($val_max - $val_min)) )]
    if {$val_scaled < 0} {set val_scaled 0}
    if {$val_scaled > 255} {set val_scaled 255}
    if {$val_scaled_1024 < 0} {set val_scaled_1024 0}
    if {$val_scaled_1024 > 1023} {set val_scaled_1024 1023 }
    #puts "val= $val   val_scaled= $val_scaled val_min= $val_min  val_max= $val_max "
    set c_r $colorscale($cm,$val_scaled,r)
    set c_g $colorscale($cm,$val_scaled,g)
    set c_b $colorscale($cm,$val_scaled,b)
    set c_index [expr $colorscale_index_offset+  $val_scaled_1024] 
  
 
    #if {$colorMethod=="Type"} {
    #  set c [expr $etype % 32 ] 
    #  #set black color to gray, since black is most common background
    #  if {$c ==16} {set c 2}
    #  draw color $c
    #  #puts "set color to $c" 
    #}

    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    proto_show_morph_moved_swc_range $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3 $swc_beg $swc_end $style $c_r $c_g $c_b

    incr n
  }
  
}

proc ::neuro::proto_show_nodes_from_list {subsetNodeIdList colorMethod  {width_scale_min 1} {width_scale_max 1}} {
  # Display the nodes with morphology 
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  set default_rad_scale 3
  set width_scale_max_min [expr $width_scale_max - $width_scale_min]
  if {$width_scale_max_min < 0.0} {set width_scale_max_min [expr - $width_scale_max_min]}
  puts "width_scale_max_min = $width_scale_max_min"
  if {$colorMethod!="Type"} {
    #look up color name, set a default if not found
    if [catch {set c [colorinfo index $colorMethod]}] {
       set c 8
     }
    draw color $c
    puts "set assigned color $c" 
  }

  


  puts "about to display [llength $subsetNodeIdList] nodes"
  status_bar_processing_start [llength $subsetNodeIdList];

  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"
    if {$ecartesian} {
      #only draw if this node has Cartesian coordinates for soma
    
      if {$colorMethod=="Type"} {
        set c [expr $etype % 32 ] 
        #set black color to gray, since black is most common background
        if {$c ==16} {set c 2}
        draw color $c
        #puts "set color to $c" 
      }
      # now adjust for color-based width changes by changing rad_scale 
      set rad_scale [expr $default_rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]
      puts "c= $c  rad_scale= $rad_scale"
      #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
      ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
      #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
      proto_show_morph_moved $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot $rad_scale
      incr n
    }
    incr ::NeuronVND::statusPbarVal; # update gui progress bar  
    update
  }
}

proc ::neuro::show_nodes_from_list {subsetNodeIdList} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype} $node($theId) {}
    puts "list elem: $n  theId: $theId line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    set c [expr $etype % 32 ] 
    draw color $c
    puts "set color to $c" 
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    show_morph_moved $etype $ex $ey $ez $exrot $eyrot $ezrot 3
    incr n
  }
}

proc ::neuro::show_nodes_from_list_soma_only_color_lookup_rgb {subsetNodeIdList soma_radius} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
  variable node
  variable typeHash
  set colorList ""
  set sphereList ""
  set radiiusList ""
  # uniform radius in this proc, but a current spheretube bug (apparent) forcing use of radiusList
  #variable globalNodeIdList

  #set node_radius 1 
  #set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    lappend colorList [cortex_color_map $typeHash(popName,$efileset_num,$etype)]
    lappend sphereList [list $ex $ey $ez]
    lappend radiusList $soma_radius
    incr n
  }
   #puts "#draw spheretube \"$sphereList\" colors \"$colorList\" radius $soma_radius  drawtubes 0" 
  draw spheretube "$sphereList" radii "$radiusList" drawtubes 0 colors "$colorList"
   #draw spheretube "$sphereList" radius $soma_radius  drawtubes 0 
}

proc ::neuro::proto_show_nodes_from_list_soma_only {subsetNodeIdList colorMethod} {
  # Display the nodes as soma spheres only
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  # multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node
  variable typeHash
  variable display_virtuals_at_creation
  puts "starting proto_show_nodes_from_list_soma_only.  colorMethod is $colorMethod"
  set node_radius 1 
  set node_scale 1
  set n 0
  if {$colorMethod!="Type"} {
    #look up color name, set a default if not found
    if [catch {set c [colorinfo index $colorMethod]}] {
       set c 8
     }
    draw color $c
    puts "set assigned color $c" 
  }
  puts "about to display [llength $subsetNodeIdList] nodes"
  status_bar_processing_start [llength $subsetNodeIdList];
  foreach theId $subsetNodeIdList {
    #puts "length subsetNodeIdList= >[llength $subsetNodeIdList] theId= $theId node($theId)=>$node($theId)<"
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    
    #catch error?
    set model_type $typeHash(model_type,$efileset_num,$etype)
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian, model_type= $model_type"

    #if {($display_noncartesians_at_creation || $ecartesian) && ( $display_virtuals_at_creation || ($model_type != "virtual")  )} 
    #  Removed: only draw if this node has Cartesian coordinates for soma
    # XX set virtual decision here?
    #   Now, we make virtual and cartesian choices before calling this proc
    if {$colorMethod=="Type"} {
      set c [expr $etype % 32 ] 
      #set black color to gray, since black is most common background
      if {$c ==16} {set c 2}
      draw color $c
      #puts "set color to $c" 
    }
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    proto_show_morph_moved_soma_only $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3
    incr n
    # end of virtual / cartesian check
    incr ::NeuronVND::statusPbarVal; # update gui progressbar
    
  }
}

#proc ::neuro::show_nodes_from_list_soma_only {subsetNodeIdList} {
#  #Now show the nodes
#  #multiple node coordinates by node_scale so same scale as swc
# 
#  #variable globalNodeIdList
#  variable node
#
#  set node_radius 1 
#  set node_scale 1
#  set n 0
#  foreach theId $subsetNodeIdList {
#    foreach {ex ey ez exrot eyrot ezrot etype} $node($theId) {}
#    puts "list elem: $n  line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
#    set c [expr $etype % 32 ] 
#    draw color $c
#    puts "set color to $c" 
#    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
#    ##draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
#    #show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
#    show_morph_moved_soma_only $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3
#    incr n
#  }
#}

proc ::neuro::query_fileset_pop_groups {} {
   #provides a dict-like list of the herarchy of filesets, populations, groups
    variable fileset_pop_unskipped_group_list
    return $fileset_pop_unskipped_group_list
}

proc ::neuro::query_edge_fileset_pop_groups {} {
   #provides a dict-like list of the herarchy of filesets, populations, groups
    variable edge_fileset_pop_group_list
    return $edge_fileset_pop_group_list
}

proc ::neuro::query_node_types_in_group {fileset_num pop group} {
  # returns a list of types whithin a node group, for a given fileset, population, and group
  # should return error if no matching fileset_num pop group, perhaps even if indiviudal missses
  variable globalNodeIdList
  variable node
  set types_in_group ""
  foreach theId $globalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    if { ($efileset_num==$fileset_num) && ($epop==$pop) && ($egroup_id==$group)} {
      lappend types_in_group $etype
    }
  }
  return [lsort -unique $types_in_group]
}

proc ::neuro::query_edge_types_in_group {fileset_num pop group} {
  # returns a list of types whithin an edge group, for a given fileset, population, and group
  # should return error if no matching fileset_num pop group, perhaps even if indiviudal missses
  variable globalEdgeIdList
  variable edge 
  set types_in_group ""
  foreach theId $globalEdgeIdList {
    foreach {etype esource_node_id etarget_node_id eedge_group_id egroup_index eedge_fileset_num epop epos_x epos_y epos_z eaff_swc_id eaff_swc_pos eaff_section_id eaff_section_pos}  $edge($theId) {}
    if { ($eedge_fileset_num==$fileset_num) && ($epop==$pop) && ($eedge_group_id==$group)} {
      lappend types_in_group $etype
      #puts "matched  edge($theId):  etype= $etype esource_node_id= $esource_node_id etarget_node_id= $etarget_node_id  eedge_group_id= $eedge_group_id  egroup_ijndex= $egroup_index  eedge_fileset_num= $eedge_fileset_num  epop= $epop epos_x= $epos_x epos_y= $epos_y epos_z= $epos_z"
    }
  }
  return [lsort -unique $types_in_group]
}

proc ::neuro::query_filesets {} {
  variable typeHash
  variable num_filesets
  set ll ""
  for {set i 0} {$i < $num_filesets} {incr i} {
     lappend ll [list $typeHash(node_filename,$i) $typeHash(node_types_filename,$i)]
  }
  return $ll
}

proc ::neuro::query_edge_filesets {} {
  variable edge_typeHash
  variable num_edge_filesets
  set ll ""
  for {set i 0} {$i < $num_edge_filesets} {incr i} {
     lappend ll [list $edge_typeHash(edge_filename,$i) $edge_typeHash(edge_types_filename,$i)]
  }
  return $ll
} 

proc ::neuro::query_num_edge_types {} {
  variable edge_typeList
  variable num_edge_filesets
  for {set i 0} {$i<$num_edge_filesets} {incr i} {
    lappend ll [llength $edge_typeList($i)]
  }
  return $ll
}

proc ::neuro::query_num_types {} {
  variable typeList
  variable num_filesets
  for {set i 0} {$i<$num_filesets} {incr i} {
    lappend ll [llength $typeList($i)]
  }
  return $ll
}

proc ::neuro::query_edge_type_list {} {
  #XX this proc and elsewhere ignores duplicated .csv files in one model
  #XX the types are considered distinct for each fileset, which could affect some complex selections
  variable num_edge_filesets
  variable edge_typeList
  set ll "" 
  for {set i 0} {$i<$num_edge_filesets} {incr i} {
    lappend ll $edge_typeList($i)
  } 
  return $ll 
}

proc ::neuro::query_type_list {} {
  #XX this proc and elsewhere ignores duplicated .csv files in one model
  #XX the types are considered distinct for each fileset, which could affect some complex selections
  variable num_filesets
  variable typeList
  set ll "" 
  for {set i 0} {$i<$num_filesets} {incr i} {
    lappend ll $typeList($i)
  } 
  return $ll 
}

proc ::neuro::query_rep_list {} {
  variable nrepList
  set ll ""
  foreach e $nrepList {
    lappend ll [lindex $e 0]
  }
  return $ll
}

proc ::neuro::query_num_nreps {} {
  variable nrepList
  return [llength $nrepList]
}

proc ::neuro::query_nreps_molecs {} {
  variable nrepList
  set ll ""
  foreach e $nrepList {
    #for internal diagnostic: nrepid, molecule
    lappend ll [list [lindex $e 0] [lindex $e 1]]
  }
  return $ll
}

proc ::neuro::query_nreps_full {} {
  variable nrepList
  set ll ""
  foreach e $nrepList {
    #for internal diagnostic: all nrep info 
    lappend ll $e
  }
  return $ll
}

proc ::neuro::query_rep_property_list {} {
  variable nrepList
  set ll ""
  foreach e $nrepList {

    foreach {nrepid shown molec style colorMethod material selection stride num_neurons displayed_virtuals_at_creation } $e {}
    #for internal diagnostic: all nrep info 
    lappend ll [list $nrepid $shown $style $colorMethod $material $selection $stride $num_neurons $displayed_virtuals_at_creation] 
  }
  return $ll
}


proc ::neuro::query_nreps_molecs {} {
  variable nrepList
  set ll ""
  foreach e $nrepList {
    lappend ll [lindex $e 0]
  }
  return $ll
}
proc ::neuro::show_nodes {} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1

  set n 0
  foreach theId $globalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype} $node($theId) {}
    #puts "list elem: $n  line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    set c [expr $etype % 32 ] 
    draw color $c
    
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #XX whi is exrot and ezrot turned off?
    show_morph_moved $etype $ex $ey $ez 0 $eyrot 0 3
    incr n
  }
}

proc ::neuro::show_nodes_arrows_from_list {subsetNodeIdList} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  #variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1
  set n 0
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype} $node($theId) {}
    puts "line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    set c [expr $etype % 32 ] 
    draw color $c
    puts "n= $n  line: $ex $ey $ez $exrot $eyrot $ezrot $etype color: $c"
     
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    #draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #rotate a vector along x axis
    set m [transmult  [transaxis x $exrot rad] [transaxis y $eyrot rad] [transaxis z $ezrot rad]]
    set v [list 1 0 0 ]
    set vr [coordtrans $m $v]

    draw_arrow [list $ex $ey $ez] $vr 10 2 1 2 12
    #show_morph_moved $etype $ex $ey $ez $exrot $eyrot $ezrot 3
    incr n
  }
  display resetview
}
proc ::neuro::show_nodes_arrows {} {
  #Now show the nodes
  #multiple node coordinates by node_scale so same scale as swc
 
  variable globalNodeIdList
  variable node

  set node_radius 1 
  set node_scale 1

  foreach theId $globalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype} $node($theId) {}
    puts "line: $ex $ey $ez $exrot $eyrot $ezrot $etype"
    set c [expr $etype % 32 ] 
    draw color $c
    
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    #draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    #rotate a vector along x axis
    set m [transmult  [transaxis x $exrot rad] [transaxis y $eyrot rad] [transaxis z $ezrot rad]]
    set v [list 1 0 0 ]
    set vr [coordtrans $m $v]

    draw_arrow [list $ex $ey $ez] $vr 10 2 1 2 12
    #show_morph_moved $etype $ex $ey $ez $exrot $eyrot $ezrot 3
  }
  display resetview
}
proc ::neuro::read_store_nodes_local {filenamestart filenameend y_rot_only} {
  
  set xfilename "${filenamestart}x${filenameend}"
  set yfilename "${filenamestart}y${filenameend}"
  set zfilename "${filenamestart}z${filenameend}"
  set typefilename "${filenamestart}node_type${filenameend}"
  set idfilename "${filenamestart}node_id${filenameend}"
  set yaxisfilename "${filenamestart}rotation_angle_yaxis${filenameend}"
  if {$y_rot_only} {
    set xaxisfilename ""
    set zaxisfilename ""
   
  } else {
    set xaxisfilename "${filenamestart}rotation_angle_xaxis${filenameend}"
    set zaxisfilename "${filenamestart}rotation_angle_zaxis${filenameend}"
  }
  foreach vec {xv yv zv xrotv yrotv zrotv typev idv } fn {xfilename yfilename zfilename xaxisfilename yaxisfilename zaxisfilename typefilename idfilename} {
    set thefilename [set $fn]
    puts "vec= $vec thefilename= $thefilename"
    if {$thefilename != ""} {
      set thefile [open $thefilename r]
      # XXX change so works for something that is not last line in file
      while { [gets $thefile myline] >=0} {
        set $vec [split $myline]
      }
   }
  }


  set node_radius 1 
  set node_scale 1
  set nodes ""
  foreach ex $xv ey $yv ez $zv etype $typev {
    lappend nodes [list $ex $ey $ez $etype]
  }
  #Now show the nodes
   #multiple node coordinates by node_scale so same scale as swc
    
  foreach e $nodes {
    foreach {ex ey ez etype} $e {}
    puts "line: $ex $ey $ez $etype"
    set c [expr $etype % 32 ] 
    draw color $c
    
    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
    draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
    
  }
}


proc ::neuro::read_nodes {filenamestart filenameend} {
  set xfilename "${filenamestart}x${filenameend}"
  set yfilename "${filenamestart}y${filenameend}"
  set zfilename "${filenamestart}z${filenameend}"
  set typefilename "${filenamestart}node_type${filenameend}"
  set fx [open $xfilename r]
  # XXX change so works for something that is not last line in file
  while { [gets $fx myline] >=0} {
    set xv [split $myline]
   }
  close $fx
  set fy [open $yfilename r]
  while { [gets $fy myline] >=0} {
   set yv [split $myline]
  }
  close $fy
  set fz [open $zfilename r]
  while { [gets $fz myline] >=0} {
   set zv [split $myline]
  }
  close $fz
  set ftype [open $typefilename r]
  while { [gets $ftype myline] >=0} {
   set typev [split $myline]
  }
  close $ftype
  set node_radius 1
  foreach ex $xv ey $yv ez $zv etype $typev {
    puts "line: $ex $ey $ez $etype"
    set c [expr $etype % 32] 
    draw color $c
    #draw sphere [list [expr 1000 * $ex]  [expr 1000 * $ey] [expr ed_000 * $ez]] radius $node_radius resolution 12
    draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4
  }
} 


proc ::neuro::draw_arrow {from dir length  arrowlength lineradius arrowradius resolution } {
    puts "dir= $dir"
    set norm  [vecnorm $dir ]
    set endline  [vecadd  $from [vecscale $norm  [expr $length - $arrowlength] ]]
    set endarrow  [vecadd  $endline [vecscale $norm $arrowlength ] ]
  
        #might need short or disk-like cylinder  
        #ensures arrowhead point is at actual "to"/length position              
    if {$length < $arrowlength} {
        set endline $from
    }


    draw cylinder $from  $endline  radius  $lineradius resolution $resolution filled yes

    draw cone $endline $endarrow radius $arrowradius resolution $resolution

    return

}

proc ::neuro::check_not_null {} {
 variable globalNodeIdList
 variable node
 set typeList ""
 set i 0
 set nn 0
  foreach e $globalNodeIdList {
  set theType [lindex $node($e) 6]
  if  {$theType > 200000000} {
    incr nn
    lappend typeList [list $nn $i $theType]
  }
  incr i
 }  
 #puts $typeList
 puts "i = $i, nn= $nn length typeList= [llength $typeList]"
 #set uList [lsort -integer -unique $typeList]
 #puts "uList= $uList"
 #puts "unique types: [llength $uList]"
}

proc ::neuro::check_unique_types {} {
 variable globalNodeIdList
 variable node
 set typeList ""
 foreach e $globalNodeIdList {
  lappend typeList [lindex $node($e) 6]
 }  
 set uList [lsort -integer -unique $typeList]
 puts "uList= $uList"
 puts "unique types: [llength $uList]"
}

proc ::neuro::stride_list_skip_special {stride theList} {
  variable node
  set outList ""
  set n 0
  foreach e $theList {
    #puts "node($e)= $node($e)"
    if {([expr $n % $stride] == 0) && ([lindex $node($e) 6] != 471819401) } {
      lappend outList $e
    }
    incr n
  }
  return $outList
}

proc ::neuro::stride_list {stride theList} {
  set outList ""
  set n 0
  foreach e $theList {
    if {[expr $n % $stride] == 0} {
      lappend outList $e
    }
    incr n
  }
  return $outList
}

proc ::neuro::within_soma_select_list {radius target_node_global_id theList} {
  #find node_ids within radius of target_node_id.  Only soma is compared to soma (single cental coordinate per neuron) 
  variable node
  
  foreach {tx ty tz txrot tyrot tzrot ttype tfileset_num tpop tnode_id tgroup_id tgroup_index tcartesian} $node($target_node_global_id) {}
  set outList ""
  set radius_sq [expr $radius * $radius]
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if {$ecartesian} {
      set rad_sq_calc [expr ($ex - $tx)* ($ex - $tx) + ($ey - $ty)* ($ey - $ty) + ($ez - $tz) *($ez - $tz) ]
      if {$rad_sq_calc < $radius_sq} {
       puts "e= $e  radius_sq= $radius_sq rad_sq_calc= $rad_sq_calc"
       lappend outList $e
      } 
    }
  }
  return $outList
}

proc ::neuro::geom_select_list {comp_axis comp_op comp_val theList} {
  variable node
  set outList ""
  puts "list length: [llength $theList]"
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    switch $comp_axis {
      x {set compvar $ex}
      y {set compvar $ey}
      z {set compvar $ez}
      default {puts "geom_select_list ERROR: ** axis ** must be x, y, or z"
        return -1
      }
    }  
    switch $comp_op {  
      gt {if {$compvar >= $comp_val} {lappend outList $e}}
      lt {if {$compvar < $comp_val} {lappend outList $e}}
      eq {if {$compvar == $comp_val} {lappend outList $e}}
      default {puts "geom_select_list ERROR: ** comp ** must be eq or gt or lt" 
        return -1
      }
    }
  }
  #puts "geom selection ending.  outlist= $outlist"
  return $outList
}
 
proc ::neuro::geom_morph_select_list {comp_axis comp_op comp_val theList} {
  #select by geometry, including spheres in full morphology
  variable node
  variable morphoHash
  variable typeHash
  set outList ""
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if {$ecartesian} {
      set pointList $morphoHash($efileset_num,$etype)
      set rotPointList ""
      set type_zrot $typeHash(rot_zaxis,$efileset_num,$etype)
      #note the corrective -type_zrot, not true for all data sets
      set m [transmult  [transoffset [list $ex $ey $ez]] [transaxis x $exrot rad ] [transaxis y $eyrot rad] [transaxis z $ezrot rad] [transaxis z [expr $type_zrot] rad]]
      foreach pe $pointList {
          set v [list [lindex $pe 2] [lindex $pe 3] [lindex $pe 4]]
          set vr [coordtrans $m $v]
          #puts "vr = $vr, v 0 = [lindex $vr 0]"

        switch $comp_axis {
          x {set compvar [lindex $vr 0]} 
          y {set compvar [lindex $vr 1]} 
          z {set compvar [lindex $vr 2]} 
          default { puts "geom_select_list ERROR: ** axis ** must be x, y, or z"
                    return -1
          }
        }  
        switch $comp_op {  
          # leave pointList foreach loop after successful comparison
          gt {if {$compvar >= $comp_val} {lappend outList $e; break}}
          lt {if {$compvar < $comp_val} {lappend outList $e; break}}
          eq {if {$compvar == $comp_val} {lappend outList $e; break}}
          default {puts "geom_select_list ERROR: ** comp ** must be eq or gt or lt" 
            return -1
          }
        }
      } 
    }
  }
  return $outList
}


proc ::neuro::group_select_list {comp_op comp_val theList} { 
  # filter a list of globalNodeId
  variable node
  set outList "" 
  #for now, we ignore comp_op (eq,gt,lt are all taken as eq)
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if {$egroup_id==$comp_val} {
      lappend outList $e
    }
  }
  return $outList
}

proc ::neuro::model_type_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  variable node
  variable typeHash
  puts "in model_type_select_list, comp_op=$comp_op comp_val=$comp_val"
  set outList "" 
  #for now, we ignore comp_op (eq,gt,lt are all taken as eq)
  #XX generate error message for comparator that is not == (eq).  This includes the generating error for the != (neq) symbol  
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if {$typeHash(model_type,$efileset_num,$etype)==$comp_val} {
      lappend outList $e
    }
  }
  return $outList
}

proc ::neuro::pop_name_extra_match_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  #XX edit this to use pop_name user-defined field
  variable node
  variable typeHash
  puts "in pop_name_extra_match_list, comp_op=$comp_op comp_val=$comp_val"
  set outList "" 
  #for now, we ignore comp_op (eq,gt,lt are all taken as eq)
  #XX generate error message for comparator that is not == (eq).  This includes the generating error for the != (neq) symbol  
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if {[string match "*${comp_val}*" $typeHash(popNameExtra,$efileset_num,$etype) ]  } {
      lappend outList $e
    }
  }
  return $outList
}

proc ::neuro::node_attrib_select_list {attrib comp_op comp_val theList} {
  # filter a list of globalNodeId
  variable node
  variable typeHash
  variable typeAttribList
  variable node_attrib_dictHash
  #puts "in node_attrib_select_list, attrib= $attrib, comp_op=$comp_op comp_val=$comp_val. Length theList= [llength $theList]"
  set outList "" 
  #for now, we ignore comp_op (eq,gt,lt are all taken as eq)
  #XX generate error message for comparator that is not == (eq).  This includes the generating error for the != (neq) symbol  
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    #if this is a field for this node's fileset, look up the value. Othwewise, set to empty string.
    if {[lsearch -exact $typeAttribList($efileset_num) $attrib]==-1} { 
        set attrib_value "" 
    } else {
      #First check for per-node attrib value.  If there isn't one, then check for type
      # need 'catch' to work around 'info exists' not working for hash lists of dicts 
      set dict_exists 0;  catch {set dict_exists [ dict exists $::neuro::node_attrib_dictHash($e) $attrib]};
      if ($dict_exists) {
        set attrib_value [dict get  $node_attrib_dictHash($e) $attrib]
      } else {
          #check per-type data
          if {[info exists typeHash($attrib,$efileset_num,$etype)]} {  
          set attrib_value $typeHash($attrib,$efileset_num,$etype)  
        } else {
          set attrib_value {}
        }
      }
    }
    #should even allow a complete wildcard match "*" to empty set (non-defined for a node).
    #puts "comp_val= $comp_val  attrib_value=>${attrib_value}<, efileset_num= $efileset_num  etype= $etype<"
    #puts "attrib_value=>${attrib_value}< comp_val= >${comp_val}<"
    if {[string is double $comp_val]} {
      if { [string is double $attrib_value]} {
        switch $comp_op {  
          gt {if {$attrib_value >= $comp_val} {lappend outList $e}}
          lt {if {$attrib_value < $comp_val} {lappend outList $e}}
          eq {if {$attrib_value == $comp_val} {lappend outList $e}}
          default {puts "attrib_select_list ERROR: ** comp ** must be eq or gt or lt" 
            return -1
            }
        }
      }
    } else { 
      if {[string match "${comp_val}" $attrib_value]} {
        lappend outList $e
        #puts "added >$e< to outlist, attrib_value=>${attrib_value}< comp_val= >${comp_val}<"
      }
    }
  }
  return $outList
}

proc ::neuro::pop_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  variable node
  puts "in pop_select_list, comp_op=$comp_op comp_val=$comp_val"
  set outList "" 
  #for now, we ignore comp_op (eq,gt,lt are all taken as eq)
  #XX generate error message for comparator that is not == (eq).  This includes the generating error for the != (neq) symbol  
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if {$epop==$comp_val} {
      lappend outList $e
    }
  }
  return $outList
}

proc ::neuro::cartesian_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  variable node
  puts "in pop_select_list, comp_op=$comp_op comp_val=$comp_val"
  set outList "" 
  #for now, we ignore comp_op (eq,gt,lt are all taken as eq)
  #XX generate error message for comparator that is not == (eq).  This includes the generating error for the != (neq) symbol  
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if {$ecartesian==$comp_val} {
      lappend outList $e
    }
  }
  return $outList
}

proc ::neuro::has_morpho_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId for those with morphology
  variable node
  puts "in pop_select_list, comp_op=$comp_op comp_val=$comp_val"
  set outList "" 
  #for now, we ignore comp_op (eq,gt,lt are all taken as eq)
  #XX generate error message for comparator that is not == (eq).  This includes the generating error for the != (neq) symbol  
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    set pointList [proto_retrieve_morphology $efileset_num $etype ]
    #   each memeber of pointlist list  is a list, following the SWC format columns:
    #       {n type x y z radius parent} 
    ##puts "length of pointlist is [llength $pointList]"
    if {[llength $pointList] <= 1} {
      set has_morpho_state False
    } else {
      set has_morpho_state True
    }
    if {$has_morpho_state==$comp_val} {
      lappend outList $e
    }
  }
  return $outList
}


proc ::neuro::type_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  variable node
  set outList "" 
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    set compvar $etype
    switch $comp_op {  
        # leave pointList foreach loop after successful comparison
        gt {if {$compvar >= $comp_val} {lappend outList $e}}
        lt {if {$compvar < $comp_val} {lappend outList $e}}
        eq {if {$compvar == $comp_val} {lappend outList $e}}
        default {puts "type_select_list ERROR: ** comp ** must be eq or gt or lt" 
          return -1
        }
      }
   }
  return $outList
}

proc ::neuro::global_node_id_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  #comp_val can be list one number long or multiple numbers
  # multiple numbers only used if === used 
  variable node
  set outList "" 
  puts "global_node_id_select comp_op= $comp_op comp_val= $comp_val"
  if {$comp_op=="eq"} {
    set comp_val_list $comp_val
  } elseif {($comp_op=="gt") || ($comp_op=="lt")} {
    set comp_val_list [lindex $comp_val 0]
  } else { puts "global_node_id_select_list ERROR: ** comp ** must be gt or eq or lt" 
          return -1
  }
  foreach comp_val_e $comp_val {
    puts "global_node_id_select_list  comp_val_e= >$comp_val_e<"
    foreach e $theList {
      foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
      #comparing to actual globalNodeId, so:
      set compvar $e
      #puts "global_node_id_select compvar= $compvar comp_val_e= $comp_val_e"
      switch $comp_op {  
        # leave pointList foreach loop after successful comparison
        gt {if {$compvar >= $comp_val_e} {lappend outList $e}}
        lt {if {$compvar < $comp_val_e} {lappend outList $e}}
        eq {if {$compvar == $comp_val_e} {lappend outList $e}}
        default {puts "global_node_id_select_list ERROR: ** comp ** must be gt or eq or lt" 
          return -1
        }
      }
    }
  }
  #puts "global_node_id_select outList= >$outList<"
  return $outList
}

proc ::neuro::node_id_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  #comp_val can be list one number long or multiple numbers
  # multiple numbers only used if === used 
  variable node
  set outList "" 
  puts "node_id_select comp_op= $comp_op comp_val= $comp_val"
  if {$comp_op=="eq"} {
    set comp_val_list $comp_val
  } else {
    set comp_val_list [lindex $comp_val 0]
  }
  foreach comp_val_e $comp_val {
    puts "node_id_select_list  comp_val_e= >$comp_val_e<"
    foreach e $theList {
      foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
      set compvar $enode_id
      switch $comp_op {  
        # leave pointList foreach loop after successful comparison
        gt {if {$compvar >= $comp_val_e} {lappend outList $e}}
        lt {if {$compvar < $comp_val_e} {lappend outList $e}}
        eq {if {$compvar == $comp_val_e} {lappend outList $e}}
        default {puts "node_id_select_list ERROR: ** comp ** must be gt or eq or lt" 
          return -1
        }
      }
    }
  }
  puts "node_id_select outList= >$outList<"
  return $outList
}

proc ::neuro::fileset_select_list {comp_op comp_val theList} {
  # filter a list of globalNodeId
  variable node
  set outList "" 
  foreach e $theList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    set compvar $efileset_num
    switch $comp_op {  
        # leave pointList foreach loop after successful comparison
        gt {if {$compvar >= $comp_val} {lappend outList $e}}
        lt {if {$compvar < $comp_val} {lappend outList $e}}
        eq {if {$compvar == $comp_val} {lappend outList $e}}
        default {puts "fileset_select_list ERROR: ** comp ** must be gt or lt" 
          return -1
        }
      }
   }
  return $outList
}
proc ::neuro::node_type_from_node_list {theList} {
  variable node
  set ll ""
  foreach e $theList {
    lappend ll [lindex $node($e) 6]
  }
  return $ll
}
  
     
proc ::neuro::v1_reset_view {} {
 display resetview
 scale by 0.025
 translate by 0 1.2 0
 display projection Orthographic
}

proc ::neuro::list_extract_if_morph {subsetList} {
  variable node
  variable typeHash
  set ll ""
  foreach n $subsetList {
    set t [lindex $node($n) 6]
    if {$t>110000000} {
      lappend ll $n
    }
  }
  return $ll
}

proc ::neuro::make_colmap_cortex {} {
  set ll [list AIv #FFFFE0 GU #FFFF99 AIp #FFE302 AId #FFEA17 VISC #FFFF14 VISam #32174d VISpm #c9a0dc VISa #645394 RSPagl #9f00ff RSPd #ee82ee RSPv #7f00ff ILA #0000CD ORBm #4682B4 FRP #00BFFF ACAv #191970 ORBvl #000080 ORBl #F0F8FF ACAd #87CEFA PL #1E90FF MOs #0000FF SSp-un #e23d28 SSp-tr #660000 SSp-ll #FFA07A SSp-n #CD5C5C SSp-ul #FF6347 SSp-m #DC143C SSp-bfd #FF4500 MOp #B22222 SSs #FF0000 PERI #c46210 AUDpo #ff8c00 AUDd #ed9121 ECT #ff7538 AUDv #ff8200 AUDp #ff9f00 TEa #ff7f00 VISli #00a693 VISal #006a4e VISrl #66ff00 VISpl #00cc99 VISpor #ace1af VISl #177245 VISp #00ff00]

  foreach {popname colorhex} $ll  {
    set s [string range $colorhex 1 6] 
    set r [format %.3f [expr 0x[string range $s 0 1]/255.0]]
    set g [format %.3f [expr 0x[string range $s 2 3]/255.0]]
    set b [format %.3f [expr 0x[string range $s 4 5]/255.0]]
    puts "$popname $r $g $b"
  }
}

proc ::neuro::cmd_load_model_config_file {user_working_dir config_file_pathname {reading_edges False}} {
  # parameters: 
  #   user_working_dir --  the current working directory (cwd), probably  from VND (startup or terminal)  e.g.  /home/janedoe/myref/trial3
  #   config_file_pathname -- absolute filename, e.g.  /home/janedoe/mymodel/config.json
  #   reading_edges -- Boolean.  Optional, defaults to False.  
  #     Currently, larger files edge files cause memory problems and crashes, so defaults False for use in releasess.
  
  #
  # In this mockup, only one model, so:
  initVars
  # read the configuration file and load the model
  read_sonata_circuit_json  $user_working_dir $config_file_pathname $reading_edges
  #only one model allowed, so hardcode this 
  set new_model_id 0
  # create a default preview represenation
  set theStride 1
  # limit crowding in the default preview
  if {[cmd_query "num_neurons"] > 10000} {set theStride 5}
  if {[cmd_query "num_neurons"] > 100000} {set theStride 50}
  if {[cmd_query "num_neurons"] > 1000000} {set theStride 500}
   
  #cmd_create_rep soma Type Opaque "all" $theStride true
  
  # forces the v1 special skip -- needed for early canned demos
  # later, stride will be a part of proper boolean and nested-parenthesis  selections -- but if common, consider a default filter
  return $new_model_id
}

proc ::neuro::load_hdf5_edge_file_pair {edge_fileset_num edge_filename  edge_types_filename } {
  variable edge_typeList 
  variable edge_typeHash
  variable edge_pop_hash
  puts "in load_hdf5_edge_file_pair:\n  edge_fileset_num= $edge_fileset_num  edge_filename=  $edge_filename\n   edge_types_filename= $edge_types_filename\n"  
  # load in the types and morphos for this file pair (same for all populations and groups)
  #XX need means of maintaing per-file name space for types, and not re-reading files.  But add the re-read feature later.
  # This is file set number $edge_fileset_num.  
  # save the filenames for future reference to guide user
  set edge_typeHash(edge_filename,$edge_fileset_num) $edge_filename 
  set edge_typeHash(edge_types_filename,$edge_fileset_num) $edge_types_filename 
  #clear the typeList for this fileset
  set edge_typeList($edge_fileset_num) ""
  proto_read_store_edge_types $edge_types_filename $edge_fileset_num
#find the populations and groups for this hdf5 edge file
  set edge_pop_group_list [hdf5_list_sonata_edge_pops_groups $edge_filename]
  
  #iterate through the populations and groups for this hdf5 edge file
  foreach e $edge_pop_group_list {
    foreach {pop group_list} $e {
      puts "pop=>$pop<  group_list=>$group_list<"
      foreach group $group_list {
         puts "sonata edge group is $group"
         # no groups are skipped for edges
         #get the data for this populations
         set edge_group_list [read_store_hdf5_edges_pop $edge_filename $edge_fileset_num $pop $group_list ]
         # get the source and target attributes for this population
         set edge_pop_hash(source_node_population,$edge_fileset_num,$pop) [hdf5_simple_attribute $edge_filename "/edges/$pop/source_node_id" "node_population"]

         set edge_pop_hash(target_node_population,$edge_fileset_num,$pop) [hdf5_simple_attribute $edge_filename "/edges/$pop/target_node_id" "node_population"]
      }
      # X use is very close to a dict
      lappend pop_group_list [list $pop $group_list]
    }
  }  
    #  For each file pair, all pops have same cols in edge_types file
  #Determine if each pop has coords, if pop has no coords skip or mark flag
   
  #read_store_hdf5_edges $edge_filename $edge_h5path  False
  # use file normalize since hdf5dump is picky about file paths
  return $pop_group_list
}



proc ::neuro::load_hdf5_node_file_pair {fileset_num node_filename  node_types_filename morphologies_dir} {
  variable typeList 
  variable typeHash
  puts "in load_hdf5_node_file_pair:\n  fileset_num= $fileset_num  node_filename=  $node_filename\n   node_types_filename= $node_types_filename\n   morphologies_dir= $morphologies_dir" 
  # XX hard-coded sphere radii - should be shared var
  set null_radius 8
  # load in the types and morphos for this file pair (same for all populations and groups)
  #XX need means of maintaing per-file name space for types, and not re-reading files.  But add the re-read feature later.
  # This is file set number $fileset_num.  
  # save the filenames for future reference to guide user
  set typeHash(node_filename,$fileset_num) $node_filename 
  set typeHash(node_types_filename,$fileset_num) $node_types_filename 
  #clear the typeList for this fileset
  set typeList($fileset_num) ""
  proto_read_store_types_and_morphos $node_types_filename $fileset_num $morphologies_dir 
#find the populations and groups for this hdf5 node file
  set pop_group_list [hdf5_list_sonata_pops_groups $node_filename]
  
  #iterate through the populations and groups for this hdf5 node file
  set pop_unskippedgroup_list ""
  foreach e $pop_group_list {
    foreach {pop group_list} $e {
      puts "pop=>$pop<  group_list=>$group_list<"
      # earlier , this would skip some groups (those with no x, no y, and no z).  Would return only the non-skipped groups.  But now no groups are skipped, and a purely non-cartesian group gets has_cartesian=Falseset.
      set unskipped_group_list [read_store_hdf5_nodes_pop $node_filename $fileset_num $pop $group_list False ]
      # X use is very close to a dict
      lappend pop_unskippedgroup_list [list $pop $unskipped_group_list]
    }
  }  
    #  For each file pair, all pops have same cols in node_types file
  #Determine if each pop has coords, if pop has no coords skip or mark flag
   
  # force y-rot_only param to False since auto-check of datasets should handle
  #read_store_hdf5_nodes $node_filename $node_h5path  False
  # use file normalize since hdf5dump is picky about file paths
  return $pop_unskippedgroup_list
}





proc ::neuro::cmd_load_model { directory} {
  #for first mockup, we completely fake this
  #in this mockup, only one model, so:
  initVars
  #read hardcoded file, v1 network
  proto_read_store_types_and_morphos /Projects/barryi/vmd/scripts/neuro_viz/v1/Biophysical_network/network/v1_node_types.csv 2 4 6 /home/barryi/projects/vmd/scripts/neuro_viz/v1/Biophysical_network/biophys_components/morphologies 8

  read_store_nodes /Projects/barryi/vmd/scripts/neuro_viz/v1_dat_files/v1_longline_ .dat true

  #only one model allowed, so hardcode this 
  set new_model_id 0
  # create a default represenation
  set theStride 1
  if {[cmd_query "num_neurons"] > 10000} {set theStride 5}
  if {[cmd_query "num_neurons"] > 100000} {set theStride 50}
  if {[cmd_query "num_neurons"] > 1000000} {set theStride 500}
  cmd_create_rep soma 11 Opaque true "all" $theStride true
 # uses stride 20 and forces the v1 special skip -- needed for early canned demos
 # later, stride will be a part of proper boolean and nested-parenthesis  selections -- but if common, consider a default filter
  return $new_model_id
}

proc ::neuro::parse_selection_string {selString theList} {
  #use selection string to choose from theList
  #set lselString [string tolower $selString]
  set non_standard_node_attribs [query_non_standard_node_attribs]
  set compselString [regsub -all {\s+} $selString " "]
  set e [split $compselString]
  # XX handle whitespaces better, such as consecutive space characters
  set e0 [lindex $e 0]
  set e1 [lindex $e 1]
  set e2 [lindex $e 2]
  set e3 [lindex $e 3]
  set e4 [lindex $e 4]

  puts "parsing: e0= $e0  e1= $e1  e2= $e2 e3= $e3 e4= $e4"
  #do substitutions for easier proc calling
  switch $e1 {
    "<"     {set e1 "lt"}
    ">"     {set e1 "gt"}
    "="    {set e1 "eq"}
    "=="    {set e1 "eq"}
    default {set e1 $e1}
  }
  switch $e2 {
    "<"     {set e2 "lt"}
    ">"     {set e2 "gt"}
    "="    {set e2 "eq"}
    "=="    {set e2 "eq"}
    default {set e2 $e2}
  }
  
  #check which selection and make the selection
  switch $e0 {
    all { 
      set outputList $theList
    }
    population {
      set outputList [pop_select_list $e1 $e2 $theList] 
     # Example: population == lgn
    }
    type {
       set outputList [type_select_list $e1 $e2 $theList] 
    }
    group {
       set outputList [group_select_list $e1 $e2 $theList] 
    }
    node {
      set itemList [lrange $e 2 end]
      puts "in node_id, itemList= >$itemList<"
      set outputList [node_id_select_list $e1 $itemList $theList] 
    }
    node_id {
      set itemList [lrange $e 2 end]
      puts "in node_id, itemList= >$itemList<"
      set outputList [node_id_select_list $e1 $itemList $theList] 
    }
    global_node_id {
      set itemList [lrange $e 2 end]
      puts "in global_node_id, itemList= >$itemList<"
      set outputList [global_node_id_select_list $e1 $itemList $theList] 
    }
    fileset {
      set outputList [fileset_select_list $e1 $e2 $theList] 
    }
    cartesian {
      set outputList [cartesian_select_list $e1 $e2 $theList] 
    }
    model_type {
      set outputList [model_type_select_list $e1 $e2 $theList] 
    }
    stride {
      set outputList [stride_list $e1 $theList]
    }
    stride_v1_special {
      set outputList [stride_list_skip_special $e1 $theList]
    }
    #pop_name_extra {
    #  set outputList [pop_name_extra_match_select_list $e1 $e2 $theList] 
    # # substring match
    #}
    has_morpho {
      set outputList [has_morpho_select_list $e1 $e2 $theList] 
    }
    soma  {
      #if {$e2 == "<"} {set e2 "lt"}
      #if {$e2 == ">"} {set e2 "gt"}
      set outputList [geom_select_list $e1 $e2 $e3 $theList]
      # Example: soma z > 100
    }
    morphology {
       #if {$e2 == "<"} {set e2 "lt"}
       #if {$e2 == ">"} {set e2 "gt"}
       set outputList [geom_morph_select_list $e1 $e2 $e3 $theList]
       # Example: morphology x < 31.2  
    }
    within {
      #XXX get working
      set outputList [within_soma_select_list $e1 $e4 $theList]
      #XX will take any text as words e1 and e4, 
      #XX do check, intention is: within 10 of node 2323 (ultimately, nested selectitons and selection objects (lists)
    } 
    default {
       #now look for non-standard attributes 
       if { ([lsearch -exact $non_standard_node_attribs $e0 ] != -1)} {
         set outputList [node_attrib_select_list $e0 $e1 $e2 $theList]
       } else {
         puts "ERROR: selection not recognized. Examples:  soma x < 3, node_id == 10 20 30, node_id < 5, node, global_node_id == 20, stride 5, type == 10, fileset eq 0, population == 2, group == 3, all"
         set outputList -1
      }
    }
    
  }
  return $outputList
}




proc ::neuro::cmd_modmaterial {repid nmol materialRequest} {
  variable nrepList
  set listPos [lsearch -exact -index 0 $nrepList $repid]
  puts "cmd_modmaterial listPos= $listPos"
  if  {$listPos >=0}  {
    #remove the molecule we are using to hold nrep $repid
    foreach {nrepid shown molec style colorMethod material selection stride num_neurons displayed_virtuals_at_creation} [lindex $nrepList $listPos] {}
    puts "hiding: nrep $repid = molec $molec"
    if {[catch {graphics $molec material $materialRequest}]} {
      neuro::showError "Failed to find material $materialRequest for neuro rep $repid"
      return 1
    } else { 
    #set the material property to the new material 
    lreplace $nrepList $listPos $listPos [list $nrepid $shown $molec $style $colorMethod $materialRequest $selection $stride $num_neurons $displayed_virtuals_at_creation]
    }
  } else {
    :neuro::showError "Representation $repid does not exist"
    return 1
  } 
}


proc ::neuro::cmd_create_rep_source_target_edges_fullsel {style colorMethod material sph_radius sph_resolution cyl_radius cyl_resolution full_selection_string_source full_selection_string_target {stride 1} {v1_special_skip False}} {
  # XX special stride parameter is temporary for testing - stride will be a part of proper selection language with boolean and nested-parenthesis  selections
  variable nrepList   
  variable nrepCount
  # number of created nreps. At initVars, set to 0.  Also is the index of the next nrep to be created, so first nrep created has index 0.
  variable globalNodeIdList
  puts "attempt to create rep $nrepCount: $style $colorMethod $material source= >$full_selection_string_source< target= >$full_selection_string_target $stride $v1_special_skip"
  # use nrep for "neuro represenation" so not confused with internal VMD reps.
  # Note that for this implementation, there is one nrep  per molecule.
  #
  set molec [mol new]
  set shown true
   
  # here, draw needed edges 
  # make selection

  if {$v1_special_skip} {
     #XX hack for showing v1 
     set displayableGlobalNodeIdList [stride_list_skip_special 1 $globalNodeIdList]
  } else {
    set displayableGlobalNodeIdList $globalNodeIdList 
  }
  # Note that parse_selection_string and all the procs it calls take in a list of globalNodeId and output a list of globalNodeId. This could be used for nested / complex selections. 

  #do stride after selection matching
  #set myNodeIdList [stride_list $stride [parse_full_selection_string $full_selection_string node] ]
  set combined_printable_selection_string "edges_source_to_target ($full_selection_string_source, $full_selection_string_target)"
  set mySourceNodeIdList [parse_full_selection_string $full_selection_string_source node] 
  set myTargetNodeIdList [parse_full_selection_string $full_selection_string_target node] 
  set source_target_edges [edges_source_nodes_target_nodes $mySourceNodeIdList $myTargetNodeIdList] 
  if { (($mySourceNodeIdList == -1) || ($myTargetNodeIdList == -1))} {
    puts "ERROR: parsing problem in source or node selection text"
    return -1
  }
  puts "length of mySourceNodeIdList is [llength $mySourceNodeIdList]"
  puts "length of myTargetNodeIdList is [llength $myTargetNodeIdList]"
  #proto_show_nodes_from_list [stride_list 4000 $::skipBadNodeIdList]
  #do cases for styles
  set num_edges [llength $source_target_edges]
  set newNrepid $nrepCount
  set displayed_virtuals_at_creation True
   #for now, force True for all edges - edges consider all nodes loaded
  lappend nrepList [list $newNrepid $shown $molec $style $colorMethod $material $combined_printable_selection_string $stride $num_edges $displayed_virtuals_at_creation]
    #so now the num_neurons position in nrepList is now more of a num_objects.  A flag should be added to the rep to show if it is an edge or a node, since they will likely have some different (non-overlapping) characteristics, and they should be properly named to user (e.g. "Number of neurons" (node) vs "Number of neural connections (edges)" edge.)
  incr nrepCount
  puts "Now to draw $num_edges edges in style $style with colorMethod $colorMethod" 
     

  switch $style {
    simple_edge   {
                    proto_show_edges_from_list $source_target_edges $style $colorMethod  $sph_radius $sph_resolution $cyl_radius $cyl_resolution
                    #put other edge styles in switch statements below this one 
                    # for instance, thickness from number of connectons, curving, start and/or end soma only (no connecting line, good for diagnostics with colors).  The same options, with sphere at morph target. line start/end location (source, target, or both) at morph position vs soma.  Coloring methods by edge type, source or target type. Cutoffs for number of connections to source or target?)
    } 
    source_soma   { proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    target_soma   { proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    simple_edge_swc   {
                    proto_show_edges_from_list $source_target_edges $style $colorMethod  $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    } 
    source_sphere_swc   { proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    target_sphere_swc   { proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    source_target_sphere_swc {proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    source_morphology   { proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    target_morphology   { proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    source_target_soma {proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    source_morph_sphere {proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    target_morph_sphere {proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    source_target_morph_sphere {proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    }
    simple_edge_morph {proto_show_edges_from_list $source_target_edges $style $colorMethod $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    } 
    default {
                  showError "style \"$style\" not recognized for connections (edges).  Style should be one of: simple_edge, source_soma, target_soma, source_target_soma, simple_edge_swc, source_sphere_swc, target_sphere_swc, source_target_sphere_swc, source_morph_sphere, target_morph_sphere, source_target_morph_sphere"
                  return -1
    } 
  }
  # XX still must add colors and representations
 
  # XX track limits and fit selection in view instead of hardcoded scaling
  #display resetview; scale by 0.021; translate by 0 1 0; display projection Orthographic
  # something is needed to bring all molecules into alignment.  
  display resetview; 
  # call existing procs 
  return $newNrepid
}

proc ::neuro::cmd_create_rep_node_fullsel {style colorMethod material full_selection_string {stride 1} {v1_special_skip False} {width_scale_min 1} {width_scale_max 1} {out_filename default.vndcoord} } {
  # XX special stride parameter is temporary for testing - stride will be a part of proper selection language with boolean and nested-parenthesis  selections
  variable nrepList   
  variable nrepCount
  # number of created nreps. At initVars, set to 0.  Also is the index of the next nrep to be created, so first nrep created has index 0.
  variable display_virtuals_at_creation 
  variable globalNodeIdList
  puts "to create rep $nrepCount: $style $colorMethod $material >$full_selection_string< $stride $v1_special_skip"

  # use nrep for "neuro represenation" so not confused with internal VMD reps.
  # Note that for this implementation, there is one nrep  per molecule.
  #
  set molec [mol new]
  set shown true
 
  # here, draw needed neurons 
  # make selection

  if {$v1_special_skip} {
     #XX hack for showing v1 
     set displayableGlobalNodeIdList [stride_list_skip_special 1 $globalNodeIdList]
  } else {
    set displayableGlobalNodeIdList $globalNodeIdList 
  }
  # Note that parse_selection_string and all the procs it calls take in a list of globalNodeId and output a list of globalNodeId. This could be used for nested / complex selections. 
  set searchAppend " && ( !(model_type == virtual) )"
  if $display_virtuals_at_creation { 
    set full_selection_string_virt_check  $full_selection_string
  } else {
    set full_selection_string_virt_check [append combined $full_selection_string $searchAppend] 
  }
  #XX the v1_special_skip check is ignored here.  
  #do stride after selection matching
  set myNodeIdList [stride_list $stride [parse_full_selection_string $full_selection_string_virt_check node] ]
  if {$myNodeIdList == -1} {
    return -1
  }
  puts "length of myNodeIdList is [llength $myNodeIdList]"
  #proto_show_nodes_from_list [stride_list 4000 $::skipBadNodeIdList]
  #do cases for styles
  set num_neurons [llength $myNodeIdList]
  set newNrepid $nrepCount
  set displayed_virtuals_at_creation $display_virtuals_at_creation
  lappend nrepList [list $newNrepid $shown $molec $style $colorMethod $material $full_selection_string $stride $num_neurons $displayed_virtuals_at_creation ]
  incr nrepCount
 

  switch $style {
    soma {proto_show_nodes_from_list_soma_only $myNodeIdList $colorMethod}
    morphology_draft {proto_show_nodes_from_list $myNodeIdList $colorMethod}
    morphology_draft_width_scale {
          #set rad_scale [expr $rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]  
          #uses optional width parameters
          proto_show_nodes_from_list $myNodeIdList $colorMethod $width_scale_min $width_scale_max
    }
    morphology {proto_show_nodes_from_list_morpho_spheretube $myNodeIdList $colorMethod}
    morphology_coordfile {proto_show_nodes_from_list_morpho_coordfile $myNodeIdList $colorMethod  $out_filename  $width_scale_min $width_scale_max}
    morphology_const_soma_coordfile {proto_show_nodes_from_list_morpho_const_soma_coordfile $myNodeIdList $colorMethod  $out_filename  $width_scale_min $width_scale_max}
    morphology_direct_soma_coordfile {proto_show_nodes_from_list_morpho_direct_soma_coordfile $myNodeIdList $colorMethod  $out_filename  $width_scale_min $width_scale_max}
    morphology_exact_soma_coordfile {proto_show_nodes_from_list_morpho_exact_soma_coordfile $myNodeIdList $colorMethod  $out_filename  $width_scale_min $width_scale_max}
    morphology_width_scale {
        #set rad_scale [expr $rad_scale * ($width_scale_min + (($c +1)/32.0)*$width_scale_max_min)]  
    proto_show_nodes_from_list_morpho_spheretube $myNodeIdList $colorMethod $rad_scale $width_scale_min $width_scale_max
    }
    morphology_line {proto_show_nodes_from_list_morpho_line $myNodeIdList $colorMethod}
    default {showError "style $style not recognized"
        return -1
    } 
  }
  # XX still must add colors and representations
 
  # XX track limits and fit selection in view instead of hardcoded scaling
  display resetview

  # call existiing procs 
    
  return $newNrepid
}



  
proc ::neuro::cmd_create_rep {style colorMethod material selection {stride 1} {v1_special_skip False}} {
  # XX special stride parameter is temporary for testing - stride will be a part of proper selection language with boolean and nested-parenthesis  selections
 #  XX delete this proc soon, since doesn't track virtual display state, proc is not used by modern commands
  variable nrepList   
  variable nrepCount
  # number of created nreps. At initVars, set to 0.  Also is the index of the next nrep to be created, so first nrep created has index 0.
  variable globalNodeIdList
  puts "attempt to create rep $nrepCount: $style $colorMethod $material >$selection< $stride $v1_special_skip"
  # use nrep for "neuro represenation" so not confused with internal VMD reps.
  # Note that for this implementation, there is one nrep  per molecule.
  #
  set molec [mol new]
  set shown true
 
  # here, draw needed neurons 
  # make selection

  if {$v1_special_skip} {
     #XX hack for showing v1 
     set displayableGlobalNodeIdList [stride_list_skip_special 1 $globalNodeIdList]
  } else {
    set displayableGlobalNodeIdList $globalNodeIdList 
  }
  # Note that parse_selection_string and all the procs it calls take in a list of globalNodeId and output a list of globalNodeId. This could be used for nested / complex selections. 

  #do stride after selection matching
  set myNodeIdList [stride_list $stride [parse_selection_string $selection $displayableGlobalNodeIdList] ]
  if {$myNodeIdList == -1} {
    return -1
  }
  puts "length of myNodeIdList is [llength $myNodeIdList]"
  #proto_show_nodes_from_list [stride_list 4000 $::skipBadNodeIdList]
  #do cases for styles
  set num_neurons [llength $myNodeIdList]
  set newNrepid $nrepCount
  set displayed_virtuals_at_creation True
   #forcing True, just to have some entry for nrepList compatiblity.  This proc should really be deleted if not called with correct concept of virtuals.
  lappend nrepList [list $newNrepid $shown $molec $style $colorMethod $material $selection $stride $num_neurons $displayed_virtuals_at_creation]
  incr nrepCount
 

  switch $style {
    soma {proto_show_nodes_from_list_soma_only $myNodeIdList $colorMethod}
    morphology {proto_show_nodes_from_list $myNodeIdList $colorMethod}
    default {showError "style $style not recognized"
        return -1
    } 
  }
  # XX still must add colors and representations
 
  # XX track limits and fit selection in view instead of hardcoded scaling
  display resetview
  #scale by 0.021; translate by 0 1 0; display projection Orthographic

  # call existiing procs 
    
  return $newNrepid
}


proc ::neuro::cmd_delete_rep {repid} {
    variable nrepList
    set listPos [lsearch -exact -index 0 $nrepList $repid]
    if  {$listPos >=0}  {
      #remove the molecule we are using to hold nrep $repid
      set theMol [lindex [lindex $nrepList $listPos] 2]
      puts "deleting nrep $repid = molec $theMol"
      mol delete $theMol
      #delete the item from the list
      set nrepList [lreplace $nrepList $listPos $listPos]
    } else {
      ::neuro::showError "Representation $repid does not exist"
      return 1
   }  
  return 0
}


proc ::neuro::showMessage {messageString} {
  puts "Message (VND): $messageString" 
}
proc ::neuro::showError {errorString} {
  puts "  Error (VND): $errorString" 
}

proc ::neuro::cmd_show_rep {repid} {
  puts "starting cmd_show_rep..."
  variable nrepList
  set listPos [lsearch -exact -index 0 $nrepList $repid]
  puts "cmd_show_rep listPos= $listPos"
  if  {$listPos >=0}  {
    #remove the molecule we are using to hold nrep $repid
    foreach {nrepid shown molec style colorMethod material selection stride num_neurons displayed_virtuals_at_creation} [lindex $nrepList $listPos] {}
    puts "showing nrep $repid = molec $molec"
    mol on $molec
    #set the shown property to true 
    set shown true
    set nrepList [lreplace $nrepList $listPos $listPos [list $nrepid $shown $molec $style $colorMethod $material $selection $stride $num_neurons $displayed_virtuals_at_creation]]
    } else {
      ::neuro::showError "Representation $repid does not exist."
      return 1
   }
}

proc ::neuro::cmd_hide_rep {repid} {
  puts "starting cmd_hide_rep..."
  variable nrepList
  set listPos [lsearch -exact -index 0 $nrepList $repid]

  puts "cmd_hide_rep listPos= $listPos"
  if  {$listPos >=0}  {
    #remove the molecule we are using to hold nrep $repid
    foreach {nrepid shown molec style colorMethod material selection stride num_neurons displayed_virtuals_at_creation} [lindex $nrepList $listPos] {}
    puts "hiding: nrep $repid = molec $molec"
    mol off $molec
    #set the shown property to false
    set shown false
    set nrepList [lreplace $nrepList $listPos $listPos [list $nrepid $shown $molec $style $colorMethod $material $selection $stride $num_neurons $displayed_virtuals_at_creation]] 
    } else {
      ::neuro::showError "Representation $repid does not exist"
      return 1
   }
}



proc ::neuro::cmd_query {property {param_1 null} {param_2 null} {param_3 null} } {
  #list reps with details
  variable globalNodeIdList
  variable globalEdgeIdList
  variable standard_node_attribs_queryable
  switch $property {
    num_neurons { return [llength $globalNodeIdList]}
    # X cache this non_virtual query
    num_nodes   { return [llength $globalNodeIdList]}
      #num_nodes is a synonym of num_neurons
    num_neurons_non_virtual { return [llength  [parse_full_selection_string "!(model_type == virtual)" node] ] }
    num_nodes_non_virtual   { return [llength  [parse_full_selection_string "!(model_type == virtual)" node] ] }
      #num_nodes_non_virtual is a synonym of num_neurons_non_virtural
    num_edges { return [llength $globalEdgeIdList]}
    #num_morphologies {}
    num_reps { return [query_num_nreps]} 
    num_types { return [query_num_types]} 
    num_edge_types { return [query_num_edge_types]} 
    rep_list { return [query_rep_list]}
    type_list { return [query_type_list]}
    edge_type_list { return [query_edge_type_list]}
    filesets { return [query_filesets]}
    edge_filesets { return [query_edge_filesets]}
    fileset_pop_groups {return [query_fileset_pop_groups]}
    edge_fileset_pop_groups {return [query_edge_fileset_pop_groups]}
    rep_property_list { return [query_rep_property_list]}
    node_types_in_group { if {($param_1=="null") || ($param_2=="null") || ($param_3=="null")} {
                            showError "Node_types_in_group requires three non-null paramarters fileset population group"
                            return -1
                          } else {
                            return [query_node_types_in_group $param_1 $param_2 $param_3] 
                          }
                        }
    edge_types_in_group { if {($param_1=="null") || ($param_2=="null") || ($param_3=="null")} {
                            showError "edge_types_in_group requires three non-null paramaters: fileset population group"
                            return -1 
                          } else {
                            return [query_edge_types_in_group $param_1 $param_2 $param_3] 
                          }
                        }
    
    compartment_time_ranges {return [query_compartment_time_ranges]}
    compartment_var_names {return [query_compartment_var_names]}
    compartment_data_min_max {return [query_compartment_data_min_max]}
    standard_node_attribs {return $standard_node_attribs_queryable}
    non_standard_node_attribs {return [query_non_standard_node_attribs]}
    non_standard_node_attribs_by_fileset { return [query_non_standard_node_attribs_by_fileset]}

    node_list_attrib_values { if {($param_1=="null") || ($param_2=="null")}  {
                            showError "node_list_attribe_values requires 2 non-null parameters: list_of_node_attributes list_of_global_node_ids" 
                            return -1
                              } else {
                            return [query_node_list_attrib_values $param_1 $param_2]
                              }
                            }
    morpho_details { if {($param_1=="null") || ($param_2=="null")} {
                            showError "morpho_details requires two paramaters; output_style (-no_coords, -original_coords, or -moved_coords) and selection_text"
                            return -1 
                     } else {
                       switch $param_1 {
                            "-no_coords" {
                             query_morpho_details_no_coords [parse_full_selection_string $param_2]
                            } 
                            "-original_coords" {
                               query_morpho_details_original_pos [parse_full_selection_string $param_2]
                            }
                            "-moved_coords" {
                              query_morpho_details_moved [parse_full_selection_string $param_2]
                            }
                            default {
                             puts "morpho_details default to -no_coords"
                             query_morpho_details_no_coords [parse_full_selection_string $param_2]
                            }
                       }
                     }
                   }
    default { set errString ""
 
              set helpString "${errString} Query should be one of: num_neurons, num_nodes, num_neurons_non_virtual,  num_nodes_non_virtual, num_edges, num_reps, rep_list, num_types, num_edge_types, type_list, edge_type_list, filesets, edge_filesets, fileset_pop_groups, edge_fileset_pop_groups,  rep_property_list, node_types_in_group FILESET POPULATION GROUP, edge_types_in_group FILESET POPULATION GROUP, compartment_time_ranges, compartment_var_names, compartment_data_min_max, standard_node_attribs, non_standard_node_attribs, non_standard_node_attribs_by_fileset, morpho_details OUTPUT_STYLE SELECTION_TEXT "
              if {$property eq "help"} {
                showMessage $helpString
              } else {
                set errString "Query $property is not recognized. $helpString" 
                showError $errString
                return -1
              }
    }
  }
}

proc ::neuro::query_compartment_time_ranges {} {
  # returns dictionary-like lists of
  # {pop_name 1 {time_min time_max time_incr time_index_max} } {pop_name_2 {} } 
  # empty brackets indicates no compartment data for that pop
  #time_min, time_max, time_incr are in actual time units (like milliseconds), 
  #  Example: {v1 {0 2000 0.1 19999}} {virt {}}
  #  time_index_max is largest time_index (0 counting), so time range 0 2000 with increment 0.1 will be 19999
  # and actually have time values 0 to 1999.9 
  variable compartHash
  #get list of all pops
  set ll  [cmd_query fileset_pop_groups]
  set pop_list ""
  foreach e $ll  {
     foreach e1 [lindex $e 1 ] {
        lappend pop_list [lindex $e1 0]
     }
  }
  set rangeList ""
  #we use only pop to identify ranges since compartment data not linked to fileset numbers
  foreach pop $pop_list {
    set the_range -1 
    if {[catch {set the_range $compartHash($pop,time)} ] } {
      lappend rangeList [list $pop {}]
    } else {
      lappend the_range $compartHash($pop,t_index_max)
      lappend rangeList [list $pop $the_range]
    }
  }
  return $rangeList
} 

proc ::neuro::query_compartment_var_names {} {
  # retrieves var names for data sets
  # for example v to indicate voltage
  variable compartHash
  #get list of all pops
  set ll  [cmd_query fileset_pop_groups]
  set pop_list ""
  foreach e $ll  {
     foreach e1 [lindex $e 1 ] {
        lappend pop_list [lindex $e1 0]
     }
  }
  set varList ""
  #we use only pop to identify ranges since compartment data not linked to fileset numbers
  foreach pop $pop_list {
    set the_var -1 
    if {[catch {set the_var $compartHash($pop,var_name)} ] } {
      lappend varList [list $pop {}]
    } else {
      lappend varList [list $pop [list $the_var]]
    }
  }
  return $varList
} 

proc ::neuro::query_compartment_data_min_max {} {
  # retrieves var names for data sets
  # for example v to indicate voltage
  variable compartHash
  #get list of all pops
  set ll  [cmd_query fileset_pop_groups]
  set pop_list ""
  foreach e $ll  {
     foreach e1 [lindex $e 1 ] {
        lappend pop_list [lindex $e1 0]
     }
  }
  set varList ""
  #we use only pop to identify ranges since compartment data not linked to fileset numbers
  foreach pop $pop_list {
    set the_var -1 
    if {[catch {set the_minmax [list $compartHash($pop,data,val_min) $compartHash($pop,data,val_max)]} ] } {
      lappend varList [list $pop {}]
    } else {
      lappend varList [list $pop $the_minmax]
    }
  }
  return $varList
}     

proc ::neuro::hdf5_list_sonata_edge_pops_groups {filename} {

  # XX Note: a copy of hdf5_list_sonata_pops_groups (note the added edge in title)
  # XX   Later, merge with this proc, so edge vs. node is a param
  # h5dump output into array
  # heuristic to find sonata populations and groups in an hdf5 node file
  # produce:  {popname_a {group_0, group_1}, popname_b {group_0} }
  # do not confuse terms: hdf5 groups (non-datasets) vs. sonata groups (part of a population)
  # first find directories inside nodes/
  # group      /
  # group      /edges
  # group      /edges/bkg (bkg is population)
  # group      /edges/bkg/0 (0 is group within population)

  # XX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to: exec h5dump -n $filename"
  set result [exec h5dump -n $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set pop_list ""
  foreach line $file_lines {
    if {$linenum > 1} {
      #puts "linenum: $linenum follows:"
      #puts $line
      # match popname_a in  "group      /edges/popname_a" but not in "group      /edgess/popname_a/0"
      if {[regexp {^\s*group\s+\/edges\/([^\s\/]+)\s*$}  $line  thematch submatch1]} {
        puts "$submatch1= >$submatch1<"
        lappend pop_list $submatch1
        puts "linenum= $linenum  added >$submatch1< to pop_list, length of pop_list = [llength $pop_list]" 
      }
    }
    incr linenum
  }
  set pop_group_list ""
  set linenum 0
  foreach pop $pop_list {
    set group_list ""
    foreach line $file_lines {
      if {$linenum > 1} {
        #puts "linenum: $linenum follows:"
        #puts $line
        # match item after popname_a (here, group_0) in   "group      /edges/popname_a/group_0" but not "group      /edges/popname_a/group_0/unexpected_subgroup" 
        if {[regexp   [subst -nocommands -nobackslashes {^\s*group\s+\/edges\/$pop\/([^\s\/]+)\s*}] $line  thematch submatch1]} {
          #for now, we ignore the optional helper  indices (sometimes spelled "indicies")
          if {! ( ($submatch1 eq "indices") || ($submatch1 eq "indicies"))} {
            lappend group_list $submatch1
            puts "linenum= $linenum  added >$submatch1< to group_list, length of group_list = [llength $group_list]" 
          }
        }
      }
      incr linenum
    } 
    lappend pop_group_list [list $pop $group_list]
  }
  #puts "val_list to return: $val_list"
  return $pop_group_list
}
proc ::neuro::hdf5_list_group_ns_attribs {filename pop group} {
  #return all attributes in this group except for x, y, z
  puts "Attrib search starts. pop: $pop  group: $group\n"
  
  # h5dump output into array
  # heuristic to find non-standard attribs for a given population and group in an hdf5 node file
  # so ignore: "x" "y" "z" "rotation_angle_xaxis" "rotation_angle_yaxis""rotation_angle_zaxis"
  # XX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to: exec h5dump -n $filename"
  set result [exec h5dump -n $filename]
  set file_lines [split $result "\n"]
  puts "Result for $filename: $result" 
  puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set ns_attrib_list ""
  foreach line $file_lines {
    if {$linenum > 1} {
      #puts "linenum: $linenum follows:"
      #puts $line
      #match for given popname and group
        if {[regexp   [subst -nocommands -nobackslashes {^\s*dataset\s+\/nodes\/$pop\/$group\/([^\s]+)\s*}] $line  thematch submatch1]} {
          if {($submatch1 ne "x") && ($submatch1 ne "y") && ($submatch1 ne "z") && ($submatch1 ne "rotation_angle_xaxis") && ($submatch1 ne "rotation_angle_yaxis") && ($submatch1 ne "rotation_angle_zaxis")} {
            lappend ns_attrib_list $submatch1
            puts "attrib check: linenum= $linenum  population= $pop group= $group added >$submatch1< to ns_attrib_list, length of ns_attrib_list = [llength $ns_attrib_list]" 
         } 
      }
    }
    incr linenum
  }
  return $ns_attrib_list
}


proc ::neuro::hdf5_list_sonata_pops_groups {filename} {

  # h5dump output into array
  # heuristic to find sonata populations and groups in an hdf5 node file
  # produce:  {popname_a {group_0, group_1}, popname_b {group_0} }
  # do not confuse terms: hdf5 groups (non-datasets) vs. sonata groups (part of a population)
  # first find directories inside nodes/
  # group      /
  # group      /nodes
  # group      /nodes/bkg (bkg is population)
  # group      /nodes/bkg/0 (0 is group within population)

  # XX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to: exec h5dump -n $filename"
  set result [exec h5dump -n $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set pop_list ""
  foreach line $file_lines {
    if {$linenum > 1} {
      #puts "linenum: $linenum follows:"
      #puts $line
      # match popname_a in  "group      /nodes/popname_a" but not in "group      /nodes/popname_a/0"
      if {[regexp {^\s*group\s+\/nodes\/([^\s\/]+)\s*$}  $line  thematch submatch1]} {
        lappend pop_list $submatch1
        puts "linenum= $linenum  added >$submatch1< to pop_list, length of pop_list = [llength $pop_list]" 
      }
    }
    incr linenum
  }
  set pop_group_list ""
  set linenum 0
  foreach pop $pop_list {
    set group_list ""
    foreach line $file_lines {
      if {$linenum > 1} {
        #puts "linenum: $linenum follows:"
        #puts $line
        # match item after popname_a (here, group_0) in   "group      /nodes/popname_a/group_0" but not "group      /nodes/popname_a/group_0/unexpected_subgroup" 
        if {[regexp   [subst -nocommands -nobackslashes {^\s*group\s+\/nodes\/$pop\/([^\s\/]+)\s*}] $line  thematch submatch1]} {
          lappend group_list $submatch1
          puts "linenum= $linenum  added >$submatch1< to group_list, length of group_list = [llength $group_list]" 
        }
      }
      incr linenum
    } 
    lappend pop_group_list [list $pop $group_list]
  }
  #puts "val_list to return: $val_list"
  return $pop_group_list
}


proc ::neuro::hdf5_list_nwb_spike_datasets {filename} {

  #h5dump output into array
  #heuristic to find paths.
  #first find directories inside nodes/
  #from there, take: 
  #0/x
  #0/y
  #0/z
  #0/rotation_angle_xaxis
  #0/rotation_angle_yaxis
  #0/rotation_angle_zaxis
  # ... defaults if needed
  # XXX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to get attribute: exec h5dump -n $filename"
  set result [exec h5dump -n $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set val_list ""
  foreach line $file_lines {
    if {$linenum > 1} {
     #puts "linenum: $linenum follows:"
     #puts $line
     if {[regexp {^\s*dataset\s+(\S*)\s*$}  $line  thematch submatch1]} {
       if {[regexp {/processing/(.*)/spike_train/(.*)/data} $submatch1 thematch2 submatch2a submatch2b ]} {  
         puts "matched >$submatch2a< >$submatch2b< in $submatch1" 
         lappend val_list [list $submatch2a $submatch2b $submatch1] 
        puts "linenum= $linenum  added >$submatch1< to val_list, length of val_list = [llength $val_list]" 
       }
      }
    }
    incr linenum
  }
  #puts "val_list to return: $val_list"
  return $val_list
}


proc ::neuro::write_nwb_spike_pop {spike_filename pop} {
  variable node
  variable spikeHash
  #first, get a list of all neuron_ids in the pop
  #make a temp working dir
  set tmp_dir  [file join "/tmp" "vnd.[pid]" ]
  file mkdir $tmp_dir
  #get complete path of spike_filename
  set spike_filename_normalized [file normalize $spike_filename]
  #get basename of spike_filename (basename will appear inside the file itself)
  set spike_filename_basename [file tail $spike_filename]
  set spike_filename_working [file join $tmp_dir $spike_filename_basename]
  #get the globl node ids for this population
  set myGlobalNodeIdList [parse_full_selection_string "population == $pop"] 
  set myNodeIdList ""
  foreach e $myGlobalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    lappend myNodeIdList $enode_id
  }
  puts "for population $pop, myNodeIdList= >$myNodeIdList<"
  #now make list of spike times for each nodeId
  
  array unset spike_by_node
  foreach spike  $spikeHash(spikeList,$pop) {
    foreach {enode_id spike_time} $spike {}
    lappend spike_by_node($enode_id) $spike_time
    #puts "lappending $enode_id $spike_time" 
  }
  set i 0
  # create the new file
  # delete working (tempdir) spike filename if present
  file delete $spike_filename_working  
  foreach n $myNodeIdList {
    if {1} {
      # h5import to the working output file
      if [info exists spike_by_node($n)] {
        set spike_train_length [llength $spike_by_node($n)]
        set conf_filename_working [file join $tmp_dir "$spike_filename_basename.$i.conf"]
        set data_filename_working [file join $tmp_dir "$spike_filename_basename.$i.data"]
        set attrib_filename_working [file join $tmp_dir "$spike_filename_basename.$i.attrib"]
        puts "i= $i  localNode= $n  spike_train_length= $spike_train_length" 
          
        set ATTRIB_FILE [open $conf_filename_working w]
        #write out file-wide unit info. to attrib file
      # write out the current conf file
        set CONF_FILE [open $conf_filename_working w]
        # write out the current data
        puts $CONF_FILE "PATH /processing/trial_0/spike_train/$n/data"
        puts $CONF_FILE "      INPUT-CLASS TEXTFP"
        puts $CONF_FILE "      RANK 1"
        puts $CONF_FILE "      DIMENSION-SIZES  $spike_train_length"
        puts $CONF_FILE "      OUTPUT-CLASS FP"
        puts $CONF_FILE "      OUTPUT-SIZE 64"
        puts $CONF_FILE "      OUTPUT-ARCHITECTURE IEEE"
        puts $CONF_FILE "      OUTPUT-BYTE-ORDER LE"
        puts $CONF_FILE "      CHUNKED-DIMENSION-SIZES $spike_train_length"
        puts $CONF_FILE "      MAXIMUM-DIMENSIONS $spike_train_length"
        close $CONF_FILE

        set DATA_FILE [open $data_filename_working w]
        foreach e $spike_by_node($n) {
          puts $DATA_FILE $e
        }
        close $DATA_FILE
        puts "about to exec:  h5import $data_filename_working -c $conf_filename_working -o $spike_filename_working"
        set result [exec h5import $data_filename_working -c $conf_filename_working -o $spike_filename_working]
        #add commands to attrib file for this group
      } else {
          puts "i= $i  localNode= $n  spike_by_node($n) does not exist" 
      }
    } else {
      break
    }
    #close working conf and data files
 
    #delete the conf and data files for this round
    #file delete $conf_filename_working
    #file delete $data_filename_working
     
    incr i
  }
  #edit the nwb file with the attrib file
  
  #copy out the nwb file
  puts "Now to:  file copy $spike_filename_working $spike_filename_normalized"
  file copy $spike_filename_working $spike_filename_normalized
  #delete the attrib file (preserve for diagnostics) 
  #file delete $attrib_filename_working
}

proc ::neuro::read_store_nwb_spike_pop {spike_filename pop} {

  variable spikeHash
  variable file_piece_size 
  #read in data for a single population within a simple nwb spike file
  #take all the datasets in processing/*/spike_train/*
  set avail_datasets [hdf5_list_datasets $spike_filename]
  set spike_datasets [hdf5_list_nwb_spike_datasets $spike_filename]
 
  set i 0
  set the_spikeList ""
  # we will fill spikelist with N lists, each list containing {node_id timestamp}
  foreach d $spike_datasets {
    #this is node id in pop, not globalNodeId, 
    foreach {trial_name node_id data_path} $d {}
    if {[lsearch -exact $avail_datasets $data_path]==-1} {
      showError "ERROR: required hdf5 dataset $data_path was not found"
      return
    } 
     
    if {$i < 3} {
      puts "trial= $trial_name  node_id= $node_id  data_path= $data_path"
    }
    #now get data from each fileset and add to spikeHash
    #puts "about to hdf5_piecewise_dataset $spike_filename $data_path $file_piece_size]"

    set vec [hdf5_piecewise_dataset $spike_filename $data_path $file_piece_size]
    puts "i=$i"
    foreach spike_timestamp $vec {
      lappend the_spikeList [list $node_id $spike_timestamp]
    }
    incr i
  } 

  set spikeHash(spikeList,$pop) $the_spikeList

  #take units from final data_path
  #XX really should check that all match and check for consistency and/or convert if needed
  set spikeHash(units,$pop) "SET UNITS"
  #set spikeHash(units,$pop) [hdf5_simple_attribute $spike_filename $data_path "unit"]
     
  
  puts "spikeHash(units,$pop) is $spikeHash(units,$pop) "
  puts "length spikeHash(spikeList,$pop) is [llength $spikeHash(spikeList,$pop)]"

}



proc ::neuro::hdf5_list_datasets {filename} {

  #h5dump output into array
  #heuristic to find paths.
  #first find directories inside nodes/
  #from there, take: 
  #0/x
  #0/y
  #0/z
  #0/rotation_angle_xaxis
  #0/rotation_angle_yaxis
  #0/rotation_angle_zaxis
  # ... defaults if needed
  # XXX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to get attribute: exec h5dump -n $filename"
  set result [exec h5dump -n $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set val_list ""
  foreach line $file_lines {
    if {$linenum > 1} {
     #puts "linenum: $linenum follows:"
     #puts $line
     if {[regexp {^\s*dataset\s+(\S*)\s*$}  $line  thematch submatch1]} {
       lappend val_list $submatch1
        puts "linenum= $linenum  added >$submatch1< to val_list, length of val_list = [llength $val_list]" 
      }
    }
    incr linenum
  }
  #puts "val_list to return: $val_list"
  return $val_list
}

proc ::neuro::hdf5_simple_attribute {filename dataset attribute} {

  #request attribute info from h5dump 
  #heuristic to extract the attribute from output.
  # ... defaults if needed
  # XXX hacky 'exec h5dump' must be replaced with better startup method
  #puts "about to: exec h5dump -d $dataset y $filename"
  #set result [exec h5dump -A -d $dataset $filename]
  set result [exec h5dump -a "$dataset/$attribute" $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
 
  while {[llength $file_lines] > 0} {
    set line [lindex $file_lines 0]
    #puts "the lines is $line"
    # XX swap in actual string
    if {[regexp "ATTRIBUTE \"$attribute\""  $line] } {
      #found attribute we want 
      set file_lines [lrange $file_lines 9 end]
      set line  [lindex $file_lines 0] 
      #puts "about to search line $line"
      if {[regexp {^\s*\(0\): \"(\S*)\"}  $line thematch submatch1]} {
        return $submatch1
      } else {
        puts "Error: did not find expected atrribute $attribute for dataset $dataset in file $filename"
        return -1 
      }
    }
    #similar to lremove or lpop in future Tcl versions
    set file_lines [lrange $file_lines 1 end]
  }
  puts "Error: did not find expected atrribute $attribute for dataset $dataset in file $filename"
  return -1 
}

proc ::neuro::hdf5_piecewise_2d_dataset {filename dataset piece_size} {

  # h5dump output into array
  # process with piece_size 2-D hyperslab of hdf5 data
  #heuristic to find paths.
  # ... defaults if needed
  # XXX hacky 'exec h5dump' must be replaced with better startup method
  #puts "about to get size of simple 2-D dataset"
  set header_result [exec h5dump -d $dataset -H $filename]
  set header_lines [split $header_result "\n"]
  foreach line $header_lines {
    if { [regexp {\s*DATASPACE\s+SIMPLE\s*\{\s*\(\s*([0-9]*)\,\s*([0-9]*)\s*\)} $line thematch submatch1 submatch2 ] } {
          set data_size_y $submatch1
          set data_size_x $submatch2
          set testval [expr 2 * $data_size_x]
          #puts  "thematch= $thematch submatch1= $submatch1 submatch2= $submatch2 data_size_x= $data_size_x  data_size_y= $data_size_y testval= $testval"  
          break
        }
  } 
  #noww loop, taking chunks of piece_size elements
  set full_val_list ""
  set y_start 0
  #puts "about to: loop over dataset with several h5dump calls. y_start= $y_start piece_size= $piece_size data_size_y= $data_size_y"
  while { $y_start + $piece_size < $data_size_y} {
      #read in piece_size elements
      puts "about to hdf5_simple_2d_dataset_range $filename $dataset $data_size_x $y_start $piece_size   data_size_x = $data_size_x y_start= $y_start"
      lappend full_val_list {*}[hdf5_simple_2d_dataset_range $filename $dataset $data_size_x $y_start $piece_size ] 
      set y_start [expr $y_start + $piece_size]
  }  
  # now read the remaining elements (smaller than piece_size)
  set remain_size [expr $data_size_y % $piece_size]
  if { $remain_size > 0 } {
    puts "now for clean-up dataset_range call, y_start= $y_start  data_size_y= $data_size_y   piece_size= $piece_size   dataset= $dataset  remain_size= $remain_size  length full_val_list= [llength $full_val_list] "
    lappend full_val_list {*}[hdf5_simple_2d_dataset_range $filename $dataset $data_size_x $y_start $remain_size ]
  } else {
    puts "no need for  clean-up  2d_dataset_range call, y_start= $y_start  data_size_y= $data_size_y   piece_size= $piece_size   dataset= $dataset  remain_size= $remain_size  length full_val_list= [llength $full_val_list] "
  }  
  puts "ending 2d_piecewise. finished final dataset_range call , data_size_y= $data_size_y   length full_val_list= [llength $full_val_list] "
  
  return $full_val_list
}

proc ::neuro::hdf5_piecewise_dataset {filename dataset piece_size} {

  #h5dump output into array
  # process with piece_size 1-D hyperslab of hdf5 data
  #heuristic to find paths.
  #first find directories inside nodes/
  #from there, take: 
  #0/x
  #0/y
  #0/z
  #0/rotation_angle_xaxis
  #0/rotation_angle_yaxis
  #0/rotation_angle_zaxis
  # ... defaults if needed
  # XX hacky 'exec h5dump' must be replaced with better startup method
  # XXX Note that may need to traverse by block in both x and y dimensions, since very wide fields may be too long for printing input / parsing via h5dump 
  #puts "about to get size of simple 1-D dataset"
  set header_result [exec h5dump -d $dataset -H $filename]
  set header_lines [split $header_result "\n"]
  foreach line $header_lines {
    if { [regexp {\s*DATASPACE\s+SIMPLE\s*\{\s*\(\s*([0-9]*)\s*\)} $line thematch submatch1 ]} {
          set data_size $submatch1
          set testval [expr 2 * $data_size]
          #puts  "thematch= $thematch submatch1= $submatch1 data_size= $data_size testval= $testval"  
          break
        }
  } 
  #puts "about to: loop over dataset with several h5dump calls.exec h5dump -d $dataset --start XXX -count YYY -w1 -y $filename"
  #noww loop, taking chunks of piece_size elements
  set val_list ""
  set start 0
  while { $start + $piece_size < $data_size} {
      #read in piece_size elements
      lappend val_list {*}[hdf5_simple_dataset_range $filename $dataset $start $piece_size ] 
      set start [expr $start + $piece_size]
  }  
  # now read the remaining elements
  set remain_size [expr $data_size % $piece_size ]
  #puts "now for final read, dataset= $dataset  remain_size= $remain_size  start= $start length val_list= [llength $val_list] "
  lappend val_list {*}[hdf5_simple_dataset_range $filename $dataset $start $remain_size ]

  #puts "finished final read,  length val_list= [llength $val_list] "
  
  return $val_list

  #set result [exec h5dump -d $dataset -w1 -y $filename]
  #set file_lines [split $result "\n"]
  
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  #set submatch1 ""
  #set linenum 0
  #set val_list ""
  #foreach line $file_lines {
  #  if {$linenum > 3} {
  #   #puts "linenum: $linenum follows:"
  #   #puts $line
  #   if {[regexp {^\s*([0-9\.\-]+)}  $line  thematch submatch1]} {
  #     lappend val_list $submatch1
  #     # puts "linenum= $linenum  added >$submatch1< to val_list, length of val_list = [llength $val_list]" 
  #    }
  # }
  #  incr linenum
  #}
  #puts "val_list to return: $val_list"
}

proc ::neuro::hdf5_simple_2d_dataset_range {filename dataset data_size_x y_start_val count_val} {

  #h5dump output into 2D array
  # XXX hacky 'exec h5dump' must be replaced with better startup method
  #puts "about to: exec h5dump -d $dataset --start $y_start_val --count $count_val --stride 1 --block 1 -w1 -y $filename"
  set execstring "h5dump -d $dataset --start \"$y_start_val, 0\" --count \"$count_val, $data_size_x\" --stride \"1,1\" --block \"1,1\" -w1 -y $filename"
  puts "about to exec h5dump $execstring"
  #set aa {*}$execstring
  #puts "aa is $aa"
  set result [exec {*}$execstring]
#  puts "result= $result"
  #note x and y are swapped since stored in HDF5 as row,col and x=col and y=row.
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set val_list ""
  set combo_val_list ""
  set x_counter 0
  foreach line $file_lines {
    if {$linenum > 9} {
       #puts "linenum: $linenum >>$line<<" 
       if {[regexp {^\s*([0-9\.\-]+)}  $line  thematch submatch1]} {
         lappend val_list $submatch1
         incr x_counter
         # puts "linenum= $linenum  added >$submatch1< to val_list, length of val_list = [llength $val_list]" 
         # length of val_list = [llength $val_list]" 
        }
      if {$x_counter >= $data_size_x} {
        #puts "about to lappend val_list, length is [llength $val_list]"
        lappend combo_val_list $val_list
        set val_list ""
        set x_counter 0
      }
    }
    #puts "x_counter= $x_counter length of val_list   = [llength $val_list ]" 
    incr linenum
  }
  puts "Pre-dataset_range final append length of combo_val_list is [llength $combo_val_list].  c_v_l 0th elem length is [llength [lindex $combo_val_list 0]]"
  if {[llength $val_list] > 0} { 
    lappend combo_val_list $val_list
    puts "Appended [llength $val_list] values at end of 2D dataset_range file read"
  }
  #puts "val_list to return: $val_list"
  puts "post-dataset_range final append length of combo_val_list is [llength $combo_val_list]"
  return $combo_val_list
}

proc ::neuro::hdf5_simple_dataset_range {filename dataset start_val count_val} {

  #h5dump output into array
  #heuristic to find paths.
  #first find directories inside nodes/
  #from there, take: 
  #0/x
  #0/y
  #0/z
  #0/rotation_angle_xaxis
  #0/rotation_angle_yaxis
  #0/rotation_angle_zaxis
  # ... defaults if needed
  # XXX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to: exec h5dump -d $dataset --start $start_val --count $count_val --stride 1 --block 1 -w1 -y $filename"
  set result [exec h5dump -d $dataset --start $start_val --count $count_val --stride 1 --block 1 -w1 -y $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set val_list ""
  foreach line $file_lines {
    if {$linenum > 9} {
     #puts "linenum: $linenum follows:"
     #puts $line
     if {[regexp {^\s*([0-9\.\-]+)}  $line  thematch submatch1]} {
       lappend val_list $submatch1
       # puts "linenum= $linenum  added >$submatch1< to val_list, length of val_list = [llength $val_list]" 
      }
    }
    incr linenum
  }
  #puts "val_list to return: $val_list"
  return $val_list
}

proc ::neuro::hdf5_simple_dataset {filename dataset} {

  #h5dump output into array
  #heuristic to find paths.
  #first find directories inside nodes/
  #from there, take: 
  #0/x
  #0/y
  #0/z
  #0/rotation_angle_xaxis
  #0/rotation_angle_yaxis
  #0/rotation_angle_zaxis
  # ... defaults if needed
  # XXX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to: exec h5dump -d $dataset -w1 -y $filename"
  set result [exec h5dump -d $dataset -w1 -y $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set val_list ""
  foreach line $file_lines {
    if {$linenum > 3} {
     #puts "linenum: $linenum follows:"
     #puts $line
     #read nan or Nan 
     if {[regexp {^\s*([NAna0-9\.\-]+)}  $line  thematch submatch1]} {
       lappend val_list $submatch1
       # puts "linenum= $linenum  added >$submatch1< to val_list, length of val_list = [llength $val_list]" 
      }
    }
    incr linenum
  }
  #puts "val_list to return: $val_list"
  return $val_list
}

proc ::neuro::hdf5_simple {filename} {
  #h5dump output into array
  #heuristic to find paths.
  #first find directories inside nodes/
  #from there, take: 
  #0/x
  #0/y
  #0/z
  #0/rotation_angle_xaxis
  #0/rotation_angle_yaxis
  #0/rotation_angle_zaxis
  # ... defaults if needed
  set result [exec h5dump -n $filename]
  puts "Result for $filename: $result" 
  set result ""
  return $result
 }  


#proc ::neuro::read_store_hdf5_edges_local {mainfilename pathstart y_rot_only} {
#  
#  # XX - for neatness, remove terminal / from pathstart 
#  # for now, hardcode node_group to 0 
#  set node_group 0  
#  # each _path is an HDF5 path
#  set x_path "${pathstart}/$node_group/x"
#  set y_path "${pathstart}/$node_group/y"
#  set z_path "${pathstart}/$node_group/z"
#  set type_path "${pathstart}/node_type_id"
#  set id_path "${pathstart}/node_id"
#  set yaxis_path "${pathstart}/$node_group/rotation_angle_yaxis"
#  if {$y_rot_only} {
#    set xaxis_path ""
#    set zaxis_path ""
#   
#  } else {
#    set xaxis_path "${pathstart}$node_group/rotation_angle_xaxis"
#    set zaxis_path "${pathstart}$node_group/rotation_angle_zaxis"
#  }
#  foreach vec {xv yv zv xrotv yrotv zrotv typev idv } pathname {x_path y_path z_path xaxis_path yaxis_path zaxis_path type_path id_path} {
#    set the_path [set $pathname]
#    puts "vec= $vec the_path= $the_path"
#    if {$the_path != ""} {
#        puts "about to hdf5_simple_dataset $mainfilename $the_path"
#        set $vec [hdf5_simple_dataset $mainfilename $the_path]
#   }
#  }
#  set node_radius 1 
#  set node_scale 1
#  set nodes ""
#  foreach ex $xv ey $yv ez $zv etype $typev {
#    lappend nodes [list $ex $ey $ez $etype]
#  }
#  puts "lappended -- length of xv is [llength $xv]"
#  #Now show the nodes
#   #multiple node coordinates by node_scale so same scale as swc
#    
#  foreach e $nodes {
#    foreach {ex ey ez etype} $e {}
#    #puts "line: $ex $ey $ez $etype"
#    set c [expr $etype % 32 ] 
#    draw color $c
#    
#    #draw sphere [list [expr 10 * $ex]  [expr 10 * $ey] [expr 10 * $ez]] radius $node_radius resolution 12
#    draw sphere [list [expr $ex]  [expr $ey] [expr $ez]] radius $node_radius resolution 4 
#    
#  }
#}

proc ::neuro::read_store_hdf5_edges_pop {mainfilename edge_fileset_num pop group_list} { 
  # read in data for a single population within an hdf5 edges file.  The group_list for that population is provided.  
  variable edge 
  variable morphoHash 
  variable globalEdgeIdCount
  variable globalEdgeIdList
  variable globalEdgeDataList
  variable globalEdgeDataListSortedSource
  variable globalEdgeDataListSortedTarget
  variable edge_pop_hash
  variable file_piece_size
  set edge_group_list ""
  set avail_datasets [hdf5_list_datasets $mainfilename]

  #first, read in 4 population-wide fields for the whole pop

  set type_path "/edges/${pop}/edge_type_id"
  set source_node_id_path "/edges/${pop}/source_node_id"
  set target_node_id_path "/edges/${pop}/target_node_id"
  set group_id_path "/edges/${pop}/edge_group_id"
  set group_index_path "/edges/${pop}/edge_group_index"
  # XX not yet taking things like dynamics_params, afferent_center_[x_y_z]

  # XX not yet taking the optional indices/ directory for fast enumeration
  # Read in these 5 fields, which must be present for each population ...
  #   This data is provided for all the edges in the population, not found within the group edge datasets within the population
  foreach vec {typev source_node_idv target_node_idv group_idv group_indexv} pathname {type_path source_node_id_path target_node_id_path group_id_path group_index_path} {
    set the_path [set $pathname]
        puts "vec= $vec the_path= $the_path "
    if {[lsearch -exact $avail_datasets $the_path]==-1} {
        showError "ERROR: required hdf5 dataset $the_path was not found"
        return
      }
      if {$the_path != ""} {
        # XXX do other tests and zero-fill if need be.
        puts "about to hdf5_piecewise_dataset $mainfilename $the_path $file_piece_size]"

        set $vec [hdf5_piecewise_dataset $mainfilename $the_path $file_piece_size]
      } else {
          showError "ERROR: required hdf5 dataset $the_path not found"
      }
  }
  #now assign to a lookup list of popEdges, all the edges in this population
  set popEdges ""
  foreach  etype $typev esource_node_id $source_node_idv etarget_node_id $target_node_idv egroup_id $group_idv egroup_index $group_indexv {
    lappend popEdges [list $etype $esource_node_id $etarget_node_id $egroup_id $egroup_index]
  }
  #puts "about to loop over group_list.  group_list=>$group_list<" 
  foreach edge_group $group_list { 
    # second, read in the group specific fields 
    # puts "starting edge_group $edge_group"
    # find the number of edges in this group
  
    set groupEdges [ lsearch -inline -all -index 3 $popEdges $edge_group]
    set sortedGroupEdges [lsort -integer -increasing -index 4  $groupEdges]
    set theVecLength [llength $groupEdges] 
    puts "just produced sortedGroupEdges.  edge_group= >$edge_group<  pop=$pop theVecLength=$theVecLength   length of sortedGroupEdges= [llength $sortedGroupEdges] length of popEdges= [llength $popEdges] length of groupEdges= [llength $groupEdges]"
    #error "early halt" 
    set check [lindex $sortedGroupEdges 0]
    puts "the 0th element of sortedGroupEdges is $check" 
    set pos_x_path "/edges/${pop}/$edge_group/pos_x"
    set pos_y_path "/edges/${pop}/$edge_group/pos_y"
    set pos_z_path "/edges/${pop}/$edge_group/pos_z"
    #XXX For now, we ignore type defined in h5 file. So, no overrides, just take from pop_level edge_type_id.  (If indeed this field is intended to override, should verify)
    set type_path "/edges/${pop}/$edge_group/type"
    set aff_swc_id_path "/edges/${pop}/$edge_group/afferent_swc_id"
    set aff_swc_pos_path "/edges/${pop}/$edge_group/afferent_swc_pos"
    set aff_section_id_path "/edges/${pop}/$edge_group/afferent_section_id"
    set aff_section_pos_path "/edges/${pop}/$edge_group/afferent_section_pos"
    foreach vec {pos_xv pos_yv pos_zv typev aff_swc_idv aff_swc_posv aff_section_idv aff_section_posv} pathname {pos_x_path pos_y_path pos_z_path type_path aff_swc_id_path aff_swc_pos_path aff_section_id_path aff_section_pos_path} {
      set $vec ""
      set the_path [set $pathname]
      puts "vec= $vec the_path= $the_path  (group id)=edge_group= $edge_group"
      #note group_index is the position in this list, the index as stored in hdf5 dataset, counting from 0
      #below, when we set edge_group_index for each edge, we make use of this fact
      if {[lsearch -exact $avail_datasets $the_path]==-1} {
        puts "WARNING: could not find dataset $the_path"
        set the_path ""
      }
      if {$the_path != ""} {
        # XXX do other tests and zero-fill if need be.
        puts "about to hdf5_simple_dataset $mainfilename $the_path vec=$vec"
        # set the referenced var, example: when $vec=xv, set xv [...]
        set $vec [hdf5_simple_dataset $mainfilename $the_path]
        puts "pop=$pop edge_group=$edge_group  just set $vec with length [llength [expr $$vec]]"
      } else {
        # populate with NULLS if corresponding hdf5 path not preset
        # display does not rely on these
        if {$vec eq "aff_swc_id_path" || $vec eq "aff_swc_pos_path" || $vec eq "aff_section_id_path" || $vec eq "aff_section_pos_path"} {
          set nullval "NULL"
        } else {
          set nullval 0
        }
        puts "about to fill with value >$nullval< for $the_path vec= $vec"
        for {set i 0} {$i<$theVecLength} {incr i} {
          #lappend $vec NULL
          lappend $vec $nullval 
        }
        puts "set $vec to 0 vector with length [llength [set $vec]]"
      } 
    } 
    #now assign to edges
    set group_index 0
    foreach epos_x $pos_xv epos_y $pos_yv epos_z $pos_zv efromdatasettype $typev eaff_swc_id $aff_swc_idv eaff_swc_pos $aff_swc_posv eaff_section_id $aff_section_idv eaff_section_pos $aff_section_posv curEdge $sortedGroupEdges {
      #XXX ignoring the type vector?  efromsatasettype reminds us that we are ignoring dataset level type 
      foreach {type source_node_id target_node_id check_group_id check_group_index} $curEdge {}
      #puts "for group_index= $group_index, curEdge. source_node_id= $source_node_id target_node_id= $target_node_id check_group_id= $check_group_id"
      set edge($globalEdgeIdCount) [list $type $source_node_id $target_node_id $edge_group $group_index $edge_fileset_num $pop $epos_x $epos_y $epos_z $eaff_swc_id $eaff_swc_pos $eaff_section_id $eaff_section_pos]
      lappend globalEdgeDataList "$edge($globalEdgeIdCount) $globalEdgeIdCount" 
      #note that there is no fileset-wide edge ID.  Likely since: no higher level object in model/simulatiom needs to refer to it, so fine for it to be a list (albeit indexable).  We do need fileset-wide node ID's since the edges use node_id's to identify sources and targets.
      
      lappend globalEdgeIdList $globalEdgeIdCount
      incr globalEdgeIdCount
      incr group_index
    }
  }
  #puts "Early return from stub in  read_store_hdf5_edges_pop "
  # pre-sort two lists.  One by Source Node Id...

  #...and the other by target node Id.  Fileset will still be needed for matching.
  #set globalEdgeDataListSortedTarget [lsort -integer -index 1 $globalEdgeDataList]
 
}
proc ::neuro::cmd_create_rep_compart_moment_selection_ranged {full_selection_string t_index style colorscale_name the_material range_min range_max } {
  variable compartHash
  variable node
  variable display_virtuals_at_creation

  variable nrepList   
  variable nrepCount
 
  set molec [mol new]
  set shown true

  set combined_printable_selection_string "node_comparts ($full_selection_string)"
  set searchAppend " && ( !(model_type == virtual) )"
  if $display_virtuals_at_creation { 
    set full_selection_string_virt_check  $full_selection_string
  } else {
    set full_selection_string_virt_check [append combined $full_selection_string $searchAppend] 
  }
  puts "Search starting up display_virtuals_at_creation= $display_virtuals_at_creation full_selection_string_virt_check= $full_selection_string_virt_check    " 
  
  set myGlobalNodeIdList [parse_full_selection_string $full_selection_string_virt_check node] 
  if {$myGlobalNodeIdList == -1} {
    puts "ERROR: parsing problem in selection text"
    return -1
  }
  puts "length of myGlobalNodeIdList is [llength $myGlobalNodeIdList]"
   
  set t_index_max 0
  #search pops in selection for largest t_index_max
  foreach e $myGlobalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if { ! [catch {set ti_max_pop $compartHash($pop,t_index_max)  }]} {
      if {$ti_max_pop > $t_index_max} {
        set t_index_max $ti_max_pop
      }
    }
  }
  #XX get t_index_match during load
  if {$t_index < 0} {showError "t_index_beg must be >= 0"; return -1}

  set newNrepid $nrepCount
  set displayed_virtuals_at_creation True
   #for now, force True for all compartments - compartments consider all nodes loaded
  set stride 1
  set num_neurons  [llength $myGlobalNodeIdList]
  lappend nrepList [list $newNrepid $shown $molec $style $colorscale_name $the_material $combined_printable_selection_string $stride $num_neurons $displayed_virtuals_at_creation $t_index $range_min $range_max]
    # compatible with initial positions for node and edge nrepList entries.  Added $t_index $range_min $range_max to end.  
    # consider: show num compartments in the num_neurons field and/or add field
    # XX This nrerp storage format needs to be redone, with different fields for each type of rep.
  incr nrepCount
  

  puts "about to show compartments t_index= $t_index   t_index_max= $t_index_max"
  #style should be line, sphere, spheretube
  display update off
  
  show_compart_moment_nodelist_ranged  $myGlobalNodeIdList $style $colorscale_name $the_material $t_index $range_min $range_max $molec 

  display update on

  display resetview 
  return $newNrepid
}

proc ::neuro::show_compart_moment_nodelist_ranged  {subsetGlobalNodeIdList style colorscale_name the_material t_index range_min range_max the_molid} {

  mol top $the_molid
  draw delete all
  foreach e $subsetGlobalNodeIdList {
    #get pop and local node_id from globalNodeId
    #foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    #set pop $epop 
    #set node_id $enode_id
    puts "about to show t_index= $t_index  global node id e= $e "
    #style should be line, sphere, spheretube
    #show compart should fail gracefully if pop and (local) node_id  not found
    show_compart_ranged $e $style $colorscale_name $the_material $t_index $range_min $range_max $the_molid 
    #puts "done with show_compart_ranged"
  }
}

proc ::neuro::compart_edge_animate_selection_render_ranged {full_selection_string t_index_beg t_index_end t_index_incr style colorscale_name the_material render_method range_min range_max filenamestart filenameend the_molid}  {
  variable compartHash
  variable node
  variable display_virtuals_at_creation
  #set molidTopAtCall [molinfo top]
  #set molidForGraphics [mol new]
  #display resetview

  set searchAppend " && ( !(model_type == virtual) )"
  if $display_virtuals_at_creation { 
    set full_selection_string_virt_check  $full_selection_string
  } else {
    set full_selection_string_virt_check [append combined $full_selection_string $searchAppend] 
  }
  
  set myGlobalNodeIdList [parse_full_selection_string $full_selection_string_virt_check node] 
  if {$myGlobalNodeIdList == -1} {
    return -1
  }
  puts "length of myGlobalNodeIdList is [llength $myGlobalNodeIdList]"
   
  set t_index_max 0
  #search pops in selection for largest t_index_max
  foreach e $myGlobalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if { ! [catch {set ti_max_pop $compartHash($epop,t_index_max)  }]} {
      if {$ti_max_pop > $t_index_max} {
        set t_index_max $ti_max_pop
      }
    }
  }
  #XX get t_index_match during load
  puts "t_index_beg= $t_index_beg  t_index_end= $t_index_end t_index_incr= $t_index_incr  t_index_max= $t_index_max"

  if {$t_index_beg < 0} {showError "t_index_beg must be >= 0"; return -1}
  if {$t_index_end < 0} {showError "t_index_end must be >= 0"; return -1}
  if {$t_index_beg  > $t_index_max} {showError "t_index_beg must be <= $t_index_max"; return -1}
  if {$t_index_end  > $t_index_max} {showError "t_index_end must be <= $t_index_max"; return -1}
  if {$t_index_max  == 0} {showError "No compartment time data found for selection \"$full_selection_string\""; return -1}


  #note theFrame  is not the t_index, but output animation frame
  set theFrame 0

  for {set t_index $t_index_beg}  {$t_index <= $t_index_end} {set t_index [expr $t_index + $t_index_incr]} {
    # XX temp placeholder for testing:
    puts "about to show t_index= $t_index   t_index_end= $t_index_end"
    draw delete all
    #style should be line, sphere, spheretube
    display update off
    show_compart_moment_nodelist_ranged $myGlobalNodeIdList $style $colorscale_name $the_material $t_index $range_min $range_max $the_molid

    #foreach e $myGlobalNodeIdList {
    #  #get pop and local node_id from globalNodeId
    #  foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    #  set pop $epop 
    #  set node_id $enode_id
    #  puts "about to show t_index= $t_index t_index_end= $t_index_end  t_index_incr= $t_index_incr  pop= $pop node_id= $node_id "
    #  #style should be line, sphere, spheretube
    #  #show compart should fail gracefully if pop and (local) node_id  not found
    # show_compart_ranged $pop $node_id $style $colorscale_name $the_material $t_index $range_min $range_max $the_molid 
    # puts "done with show_compart_ranged"
    #}

    display update on
    set fname "$filenamestart.[format %05d $theFrame]$filenameend"
    #render TachyonLOptiXInternal $fname  
    #render TachyonInternal $fname  
    puts "about to render $fname"
    render $render_method $fname  
    incr theFrame
  }
}

proc ::neuro::compart_animate_selection_render_ranged {full_selection_string t_index_beg t_index_end t_index_incr style colorscale_name the_material render_method range_min range_max filenamestart filenameend the_molid}  {
  variable compartHash
  variable node
  variable display_virtuals_at_creation
  #set molidTopAtCall [molinfo top]
  #set molidForGraphics [mol new]
  #display resetview

  set searchAppend " && ( !(model_type == virtual) )"
  if $display_virtuals_at_creation { 
    set full_selection_string_virt_check  $full_selection_string
  } else {
    set full_selection_string_virt_check [append combined $full_selection_string $searchAppend] 
  }
  
  set myGlobalNodeIdList [parse_full_selection_string $full_selection_string_virt_check node] 
  if {$myGlobalNodeIdList == -1} {
    return -1
  }
  puts "length of myGlobalNodeIdList is [llength $myGlobalNodeIdList]"
   
  set t_index_max 0
  #search pops in selection for largest t_index_max
  foreach e $myGlobalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    if { ! [catch {set ti_max_pop $compartHash($epop,t_index_max)  }]} {
      if {$ti_max_pop > $t_index_max} {
        set t_index_max $ti_max_pop
      }
    }
  }
  puts "t_index_beg= $t_index_beg  t_index_end= $t_index_end t_index_incr= $t_index_incr  t_index_max= $t_index_max"

  if {$t_index_max  == 0} {showError "No compartment time data found for selection \"$full_selection_string\""; return -1}
  if {$t_index_beg < 0} {showError "t_index_beg must be >= 0"; return -1}
  if {$t_index_end < 0} {showError "t_index_end must be >= 0"; return -1}
  if {$t_index_beg  > $t_index_max} {showError "t_index_beg must be <= $t_index_max"; return -1}
  if {$t_index_end  > $t_index_max} {showError "t_index_end must be <= $t_index_max"; return -1}


  #note theFrame  is not the t_index, but output animation frame
  set theFrame 0

  for {set t_index $t_index_beg}  {$t_index <= $t_index_end} {set t_index [expr $t_index + $t_index_incr]} {
    # XX temp placeholder for testing:
    puts "about to show t_index= $t_index   t_index_end= $t_index_end"
    draw delete all
    #style should be line, sphere, spheretube
    display update off
    show_compart_moment_nodelist_ranged $myGlobalNodeIdList $style $colorscale_name $the_material $t_index $range_min $range_max $the_molid

    #foreach e $myGlobalNodeIdList {
    #  #get pop and local node_id from globalNodeId
    #  foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    #  set pop $epop 
    #  set node_id $enode_id
    #  puts "about to show t_index= $t_index t_index_end= $t_index_end  t_index_incr= $t_index_incr  pop= $pop node_id= $node_id "
    #  #style should be line, sphere, spheretube
    #  #show compart should fail gracefully if pop and (local) node_id  not found
    # show_compart_ranged $pop $node_id $style $colorscale_name $the_material $t_index $range_min $range_max $the_molid 
    # puts "done with show_compart_ranged"
    #}

    display update on
    set fname "$filenamestart.[format %05d $theFrame]$filenameend"
    #render TachyonLOptiXInternal $fname  
    #render TachyonInternal $fname  
    puts "about to render $fname"
    render $render_method $fname  
    incr theFrame
  }
}

proc ::neuro::compart_animate_render_ranged {pop t_index_beg t_index_end t_index_incr style colorscale_name the_material render_method range_min range_max filenamestart filenameend the_molid}  {
  variable compartHash
  #XX get t_index_match during load
  set t_index_max 999999
  if {$t_index_beg < 0} {errString "t_index_beg must be >= 0"}
  if {$t_index_end  > $t_index_max} {errString "t_ind_end must be <= $t_index_max"}

  set theFrame 0

  for {set t_index $t_index_beg}  {$t_index <= $t_index_end} {set t_index [expr $t_index + $t_index_incr]} {
    #XXX loop over input set of nodes.  Get each node_id from global node_ids.
    # XX temp placeholder for testing:
    set node_id 0
    puts "about to show t_index= $t_index"
    #style should be line, sphere, spheretube
    #only showing one node of compartments
    draw delete all
    show_compart_ranged $pop $node_id $style $colorscale_name $the_material $t_index $range_min $range_max $the_molid 
    set fname "$filenamestart.[format %05d $theFrame]$filenameend"
    #render TachyonLOptiXInternal $fname  
    #render TachyonInternal $fname  
    render $render_method $fname  
    incr theFrame
  }
}


proc ::neuro::compart_animate_selection_render {full_selection_string t_index_beg t_index_end t_index_incr style colorscale_name the_material render_method filenamestart filenameend the_molid}  {
  variable compartHash
  variable display_virtuals_at_creation

  #XX get t_index_match during load
  set t_index_max 9999
  if {$t_index_beg < 0} {errString "t_index_beg must be >= 0"}
  if {$t_index_end  > $t_index_max} {errString "t_ind_end must be <= $t_index_max"}
  set searchAppend " && ( !(model_type == virtual) )"
  if $display_virtuals_at_creation { 
    set full_selection_string_virt_check  $full_selection_string
  } else {
    set full_selection_string_virt_check [append combined $full_selection_string $searchAppend] 
  }
  
  set myGlobalNodeIdList [parse_full_selection_string $full_selection_string_virt_check node] 
  if {$myGlobalNodeIdList == -1} {
    return -1
  }
  puts "length of myGlobalNodeIdList is [llength $myGlobalNodeIdList]"


  set theFrame 0
  for {set t_index $t_index_beg}  {$t_index <= $t_index_end} {set t_index [expr $t_index + $t_index_incr]} {
    #XXX loop over input set of nodes.  Get each node_id from global node_ids.
    # XX temp placeholder for testing:
    foreach e $myGlobalNodeIdList {
        #get pop and local node_id from globalNodeId
      foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
      set pop $epop 
      set node_id $enode_id
      puts "about to show t_index= $t_index"
      #style should be line, sphere, spheretube
      #show compart should fail gracefully if pop and (local) node_id  not found
      show_compart $pop $node_id $style $colorscale_name $the_material $t_index $the_molid 
    }
    set fname "$filenamestart.[format %05d $theFrame]$filenameend"
    #render TachyonLOptiXInternal $fname  
    #render TachyonInternal $fname  
    render $render_method $fname  
    incr theFrame
  }
}

proc ::neuro::compart_animate_render_ranged {pop t_index_beg t_index_end t_index_incr style colorscale_name the_material render_method range_min range_max filenamestart filenameend the_molid}  {
  variable compartHash
  #XX get t_index_match during load
  set t_index_max 9999
  if {$t_index_beg < 0} {errString "t_index_beg must be >= 0"}
  if {$t_index_end  > $t_index_max} {errString "t_ind_end must be <= $t_index_max"}

  set theFrame 0

  for {set t_index $t_index_beg}  {$t_index <= $t_index_end} {set t_index [expr $t_index + $t_index_incr]} {
    #XXX loop over input set of nodes.  Get each node_id from global node_ids.
    # XX temp placeholder for testing:
    set node_id 0
    puts "about to show t_index= $t_index"
    #style should be line, sphere, spheretube
    show_compart_ranged $pop $node_id $style $colorscale_name $the_material $t_index $range_min $range_max $the_molid 
    set fname "$filenamestart.[format %05d $theFrame]$filenameend"
    #render TachyonLOptiXInternal $fname  
    #render TachyonInternal $fname  
    render $render_method $fname  
    incr theFrame
  }
}


#proc ::neuro::compart_animate {pop t_index_beg t_index_end t_index_incr colorscale_name}  {
#  set the_molid [mol new]
#  variable compartHash
#  set t_index_max 10000
#  if {$t_index < 0} {errString "t_index must be >= 0"}
#  if {$t_index > $t_index_max} {errString "t_ind_end must be <= $t_index_max}"
#
#  for {set t_index 0}  {$t_index < $t_index_max} {set t_index [expr $t_index + $incr_size]} {
#    #XXX loop over set of nodes.  Get node_id from global node_ids.
#    set node_id 0
#    show_compart $pop $node_id $colorscale_name $t_index $the_molid 
#  }
#}

proc ::neuro::show_compart_ranged_source_targets {globalNodeId subsetGlobalNodeIdList style colorscale_name the_material t_index range_min range_max the_molid } {
    

   color scale method $colorscale_name

   #show swc segments active and involved edge source targets
  variable node
  variable compartHash
  variable colorscale_index_offset

   #set edge appearance1
  set sph_radius 5
  set sph_resolution 6
  set cyl_radius 2
  set cyl_resolution 5

  mol top $the_molid 
  draw material $the_material
  puts "show_compart_ranged_source_targets:  t_index= $t_index"
  #set val_min $compartHash($pop,data,val_min)
  #set val_max $compartHash($pop,data,val_max)
  #set colorMethod 0
  # should identify cases of no compartments
  foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($globalNodeId) {}
  set pop $epop 
  set node_id $enode_id
  if {! [info exists  compartHash($pop,swc_ids_beg) ]} {
    showMessage "no compartment data for pop= $pop node_id= $node_id"
    return -1
  } 
  set num_segments [llength $compartHash($pop,swc_ids_beg)]
  set node_index [lsearch $compartHash($pop,node_ids) $node_id ]
  for {set i 0} {$i < $num_segments} {incr i} {
    set swc_beg [lindex $compartHash($pop,swc_ids_beg) $i]
    set swc_end [lindex $compartHash($pop,swc_ids_end) $i]
    set d $compartHash($pop,data,$t_index,$i)
    set d_scaled_1024  [expr int (1023 *( ($range_min) / ($range_max - $range_min)) )]
    if {$d_scaled_1024 < 0} {set d_scaled_1024 0}
    if {$d_scaled_1024 > 1023} {set d_scaled_1024 1023 }
    #now draw neuron 0
    #proto_show_node_swc_range node_id swc_beg swc_end val colorMethod   
    #puts "swc_beg= $swc_beg  swc_end= $swc_end  d= $d colorMethod= $colorMethod"
    #override test color cycle with BlueToRed 
    #note that colorful per-segment change should be restored,  Send segment index? 
    set colorMethod $colorscale_name
    proto_show_node_swc_range $node_id $swc_beg $swc_end $range_min $range_max $d $style $colorMethod   
    # now show synapses (edges, or just source targets) for this segment set swcList ""
    for {set s $swc_beg} {$s <= $swc_end} {incr s} {
      lappend swcList $s
    }
    puts "length swcList= [llength $swcList]"

    set source_target_edge_lists [swc_to_edges_source_target $globalNodeId $swcList] 
    #now display the source target list
    foreach {source_edge_list target_edge_list} $source_target_edge_lists {}
    ## wasteful repeaated lsort here just for debugging
    set source_edge_list [lsort -unique $source_edge_list]
    set target_edge_list [lsort -unique $target_edge_list]
    puts "segment i= $i   globalNodeId= $globalNodeId  pop= $pop   node_id= $node_id  swc_beg= $swc_beg  swc_end= $swc_end  source_edge_list= $source_edge_list   target_edge_list= $target_edge_list"
    puts "now to draw edges with current value d= $d colorMethod= $colorMethod"
    set edge_style simple_edge_swc
    #set orange for testing 
    set edgeColorMethod [expr $colorscale_index_offset + $d_scaled_1024] 
    #XX need scalable color function
    proto_show_edges_from_list $target_edge_list $edge_style $edgeColorMethod  $sph_radius $sph_resolution $cyl_radius $cyl_resolution
    set edge_style target_sphere_swc
    proto_show_edges_from_list $target_edge_list $edge_style $edgeColorMethod  $sph_radius $sph_resolution $cyl_radius $cyl_resolution

    }

}

proc ::neuro::show_compart_ranged {globalNodeId style colorscale_name the_material t_index range_min range_max the_molid } {
  variable compartHash
  variable node
  mol top $the_molid 
  draw material $the_material
  puts "show_compart_ranged:  t_index= $t_index"
  #set val_min $compartHash($pop,data,val_min)
  #set val_max $compartHash($pop,data,val_max)
  #set colorMethod 0
  # should identify cases of no compartments


  foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($globalNodeId) {}
  set pop $epop 
  set node_id $enode_id
  if {! [info exists compartHash($pop,swc_ids_beg) ]} {
    showMessage "no compartment data for pop= $pop node_id $node_id"
    return -1
  } 
  set num_segments [llength $compartHash($pop,swc_ids_beg)]
  #use node_id and index_pointer to determine which segments to display
  # find match index for node_id 
  set node_index [lsearch $compartHash($pop,node_ids) $node_id ]
  if {$node_index == -1} {
    showMessage "pop= $pop node= $node_id has no compartment info."
    return -1
  }
  set segment_start [lindex $compartHash($pop,index_pointer) $node_index ]

  #substract 1 to get segment_finish since this next number is start element of next segment. match.  The dinal 
  set segment_finish [expr [lindex $compartHash($pop,index_pointer) [expr $node_index +1] ] -1 ]
  puts "node_id= $node_id  node_index= $node_index  segment_start= $segment_start   segment_finish= $segment_finish"

  for {set i $segment_start} {$i <= $segment_finish} {incr i} {
    set swc_beg [lindex $compartHash($pop,swc_ids_beg) $i]
    set swc_end [lindex $compartHash($pop,swc_ids_end) $i]
    set d $compartHash($pop,data,$t_index,$i)
    #now draw neuron 0
    #proto_show_node_swc_range nodeId swc_beg swc_end val colorMethod   
    #puts "swc_beg= $swc_beg  swc_end= $swc_end  d= $d colorMethod= $colorMethod"
    #override test color cycle with BlueToRed 
    #note that colorful per-segment change should be restored,  Send segment index? 
    set colorMethod $colorscale_name
    proto_show_node_swc_range $globalNodeId $swc_beg $swc_end $range_min $range_max $d $style $colorMethod   
  }

}

proc ::neuro::show_compart {pop nodeId style colorscale_name the_material t_index the_molid} {
  variable compartHash
  mol top $the_molid 
  display update off
  draw delete all
  draw material $the_material
  puts "show_compart:  t_index= $t_index"
  set val_min $compartHash($pop,data,val_min)
  set val_max $compartHash($pop,data,val_max)
  #set colorMethod 0
  set num_segments [llength $compartHash($pop,swc_ids_beg)]
  for {set i 0} {$i < $num_segments} {incr i} {
    set swc_beg [lindex $compartHash($pop,swc_ids_beg) $i]
    set swc_end [lindex $compartHash($pop,swc_ids_end) $i]
    set d $compartHash($pop,data,$t_index,$i)
    #now draw neuron 0
    #proto_show_node_swc_range nodeId swc_beg swc_end val colorMethod   
    #puts "swc_beg= $swc_beg  swc_end= $swc_end  d= $d colorMethod= $colorMethod"
    #override test color cycle with BlueToRed 
    #note that colorful per-segment change should be restored,  Send segment index? 
    set colorMethod $colorscale_name
    proto_show_node_swc_range $nodeId $swc_beg $swc_end $val_min $val_max $d $style $colorMethod   
  }
  display update

  display update on
}

proc ::neuro::read_store_hdf5_compart_pop {compart_filename pop} {
  variable compartHash
  variable file_piece_size 
  variable file_2d_piece_size 
  #read in data for a single population within an hdf5 compartment file
  #read in any dataset attributesw

  puts "Now to read in pop= >$pop< from compart_filename= $compart_filename"

  set avail_datasets [hdf5_list_datasets $compart_filename]

  set data_path "/report/${pop}/data"
  set element_ids_path "/report/${pop}/mapping/element_ids"
  set element_pos_path "/report/${pop}/mapping/element_pos"
  set index_pointer_path "/report/${pop}/mapping/index_pointer"
  set node_ids_path "/report/${pop}/mapping/node_ids"
  set swc_ids_beg_path "/report/${pop}/mapping/swc_ids_beg"
  set swc_ids_end_path "/report/${pop}/mapping/swc_ids_end"
  set time_path "/report/${pop}/mapping/time"
  set var_name_attrib_path "/report/${pop}/data"

  #read in 2D data from data  

  #time-trace data is TxS array of T (timesteps) x S compartment/segments 
  # T x S =  length ("mapping/time") x length("mapping/element_ids") 
  # check if needs specialized tuning value instead of $file_2d_piece_size since many lines needed. 
   
  set time_data_array [hdf5_piecewise_2d_dataset $compart_filename "/report/${pop}/data" $file_2d_piece_size ]
  puts "elem 3 of time_data_array:  [lindex $time_data_array 3]"
  # XX should validate that received correct array size
  puts "start store of time_data_array"
  set val_min 0
  set val_max 0
  set t 0
  foreach elem $time_data_array {
    set s 0
    foreach e $elem {
      if {$e < $val_min} {set val_min $e}
      if {$e > $val_max} {set val_max $e}
      set compartHash($pop,data,$t,$s) $e
      #puts "just set compartHash($pop,data,$t,$s) to $compartHash($pop,data,$t,$s)"
      incr s
    }
    if {($t % 500) == 0} {
      #puts "t= $t   compartHash($pop,data,$t,5)= $compartHash($pop,data,$t,5)"
      puts "t= $t"
    }
    incr t 
  } 
  set compartHash($pop,t_index_max) [expr $t - 1]
  set compartHash($pop,data,val_min) $val_min 
  set compartHash($pop,data,val_max) $val_max 
  puts "end store of time_data_array, compartHash($pop,data,val_min)= $compartHash($pop,data,val_min)  compartHash($pop,data,val_max)= $compartHash($pop,data,val_max)"
  foreach fieldname {element_ids element_pos index_pointer node_ids swc_ids_beg swc_ids_end time} pathname {element_ids_path element_pos_path index_pointer_path node_ids_path swc_ids_beg_path swc_ids_end_path time_path} {
    set the_path [set $pathname]
    puts "fieldname= $fieldname the_path= $the_path"
    if {[lsearch -exact $avail_datasets $the_path]==-1} {
        showError "ERROR: required hdf5 dataset $the_path was not found"
        return
    }
  if {$the_path != ""} {
    # XXX do other tests and zero-fill if need be.
      puts "about to hdf5_piecewise_dataset $the_path $file_piece_size and store in compartHash($pop,$fieldname)]"

      set compartHash($pop,$fieldname) [hdf5_piecewise_dataset $compart_filename $the_path $file_piece_size]
    } else {
        showError "ERROR: required hdf5 dataset $the_path not found"
    }
     
  }
  # get variable name for 2D dataset.  Common example "v", for voltage.
  set compartHash($pop,var_name) [hdf5_simple_attribute $compart_filename $var_name_attrib_path "variable"]
  puts "length compartHash($pop,element_ids) is [llength $compartHash($pop,element_ids)]"
  puts "compartHash($pop,time) is: $compartHash($pop,time)"
  puts "compartHash($pop,t_index_max) is: $compartHash($pop,t_index_max)"
  puts "compartHash($pop,var_name) is: $compartHash($pop,var_name)" 
}

proc ::neuro::read_store_hdf5_spike_pop {spike_filename pop} {
  variable spikeHash
  variable file_piece_size 
  #read in data for a single population within an hdf5 spike file
  #read in any dataset attributes

  puts "Now to read in pop= >$pop< from spike_filename= $spike_filename"

  set avail_datasets [hdf5_list_datasets $spike_filename]

  set timestamps_path "/spikes/${pop}/timestamps"
  set node_ids_path "/spikes/${pop}/node_ids"
  
  # XX not yet taking the optional indices/ directory for fast enumeration
  # Read in these 5 fields, which must be present for each population ...
  #   This data is provided for all the edges in the population, not found within the group edge datasets within the population
  foreach vec {timestampsv node_idsv} pathname {timestamps_path node_ids_path} {
    set the_path [set $pathname]
    puts "vec= $vec the_path= $the_path"
    if {[lsearch -exact $avail_datasets $the_path]==-1} {
        showError "ERROR: required hdf5 dataset $the_path was not found"
        return
    }
  if {$the_path != ""} {
    # XXX do other tests and zero-fill if need be.
      puts "about to hdf5_piecewise_dataset $spike_filename $the_path $file_piece_size]"

      set $vec [hdf5_piecewise_dataset $spike_filename $the_path $file_piece_size]
    } else {
        showError "ERROR: required hdf5 dataset $the_path not found"
    }
    #get attributes
     
    set spikeHash(units,$pop) [hdf5_simple_attribute $spike_filename $timestamps_path "units"]
    set spikeHash(sorting,$pop) [hdf5_simple_attribute $spike_filename "/spikes/${pop}" "sorting"])
  }
  #assign vectors to list
  set spikeList ""
  foreach enode_id $node_idsv etimestamp $timestampsv {
    lappend spikeList [list $enode_id $etimestamp]
  } 
  set spikeHash(spikeList,$pop) $spikeList
  puts "spikeHash(-1) is >$spikeHash(-1)<"
  puts "spikeHash(units,$pop) is $spikeHash(units,$pop) "
  puts "spikeHash(sorting,$pop) is $spikeHash(sorting,$pop) "
  puts "length spikeHash(spikeList,$pop) is [llength $spikeHash(spikeList,$pop)]"
  puts "spikeHash(units,$pop) is $spikeHash(units,$pop)"
}

proc ::neuro::read_store_hdf5_nwb_time_series {spike_filename pop} {
  variable spikeHash
  variable file_piece_size 
  #read in data for a single population within an hdf5 spike file
  #read in any dataset attributes

  puts "Now to read in pop= >$pop< from spike_filename= $spike_filename"

  set avail_datasets [hdf5_list_datasets $spike_filename]
  puts $avail_datasets
  set timestamps_path "/spikes/${pop}/timestamps"
  set node_ids_path "/spikes/${pop}/node_ids"
  
  # XX not yet taking the optional indices/ directory for fast enumeration
  # Read in these 5 fields, which must be present for each population ...
  #   This data is provided for all the edges in the population, not found within the group edge datasets within the population
  foreach vec {timestampsv node_idsv} pathname {timestamps_path node_ids_path} {
    set the_path [set $pathname]
    puts "vec= $vec the_path= $the_path"
    if {[lsearch -exact $avail_datasets $the_path]==-1} {
        showError "ERROR: required hdf5 dataset $the_path was not found"
        return
    }
  if {$the_path != ""} {
    # XXX do other tests and zero-fill if need be.
      puts "about to hdf5_piecewise_dataset $spike_filename $the_path $file_piece_size]"

      set $vec [hdf5_piecewise_dataset $spike_filename $the_path $file_piece_size]
    } else {
        showError "ERROR: required hdf5 dataset $the_path not found"
    }
    #get attributes
    
    # find units 
    #set spikeHash(units,$pop) [hdf5_simple_attribute $spike_filename $timestamps_path "units"]
    
    #set spikeHash(sorting,$pop) [hdf5_simple_attribute $spike_filename "/spikes/${pop}" "sorting"])
  }
  #assign vectors to list
  set spikeList ""
  foreach enode_id $node_idsv etimestamp $timestampsv {
    lappend spikeList [list $enode_id $etimestamp]
  } 
  set spikeHash(spikeList,$pop) $spikeList
  puts "spikeHash(-1) is >$spikeHash(-1)<"
  puts "spikeHash(units,$pop) is $spikeHash(units,$pop) "
  puts "spikeHash(sorting,$pop) is $spikeHash(sorting,$pop) "
  puts "length spikeHash(spikeList,$pop) is [llength $spikeHash(spikeList,$pop)]"
  puts "spikeHash(units,$pop) is $spikeHash(units,$pop)"
}

proc ::neuro::hdf5_list_sonata_compart_pops {filename} {

  # h5dump output into array
  # heuristic to find populations and groups in an hdf5 node file
  # produce:  {popname_a  popname_b popname_c }
  # first find directories inside nodes/
  # group      /
  # group      /report
  # group      /report/a (a is population)
  # group      /report/b (b is population)


  # XX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to: exec h5dump -n $filename"
  set result [exec h5dump -n $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set pop_list ""
  foreach line $file_lines {
    if {$linenum > 1} {

      #puts "linenum: $linenum follows:"
      #puts $line
      # match popname_a in  "group      /report/popname_a" but no longet, thts is not in "group      /report/popname_a/data" or "group    /report/popname_a/mapping/element_ids" or similar"
      if {[regexp {^\s*group\s+\/report\/([^\s\/]+)\s*$}  $line  thematch submatch1]} {
        lappend pop_list $submatch1
        puts "linenum= $linenum  added >$submatch1< to pop_list, length of pop_list = [llength $pop_list]" 
      }
    }
    incr linenum
  }
  return $pop_list
}

proc ::neuro::hdf5_list_sonata_spike_pops {filename} {

  # h5dump output into array
  # heuristic to find populations and groups in an hdf5 node file
  # produce:  {popname_a  popname_b popname_c }
  # first find directories inside nodes/
  # group      /
  # group      /spikes
  # group      /spikes/a (a is population)
  # group      /spikes/b (b is population)


  # XX hacky 'exec h5dump' must be replaced with better startup method
  puts "about to: exec h5dump -n $filename"
  set result [exec h5dump -n $filename]
  set file_lines [split $result "\n"]
  #puts "Result for $filename: $result" 
  #puts "file_lines length: [llength $file_lines]" 
  set linenum 0
  set pop_list ""
  foreach line $file_lines {
    if {$linenum > 1} {

      #puts "linenum: $linenum follows:"
      #puts $line
      # match popname_a in  "group      /spikes/popname_a" but not in "group      /spikes/popname_a/timestamps"
      if {[regexp {^\s*group\s+\/spikes\/([^\s\/]+)\s*$}  $line  thematch submatch1]} {
        lappend pop_list $submatch1
        puts "linenum= $linenum  added >$submatch1< to pop_list, length of pop_list = [llength $pop_list]" 
      }
    }
    incr linenum
  }
  return $pop_list
}

proc ::neuro::load_hdf5_spike_file {spike_filename} {
  # get populations contained in an hdf5 spike file, then read data for each population
  variable spikeHash
  set pop_list [hdf5_list_sonata_spike_pops $spike_filename]
  foreach pop_name $pop_list {
     read_store_hdf5_spike_pop $spike_filename $pop_name 
     puts "In load_hdf5_spike_file: length spikeHash(spikeList,$pop_name) is [llength $spikeHash(spikeList,$pop_name)]"
  }
 
}

proc ::neuro::load_hdf5_compart_file {compart_filename} {
  # get populations contained in an hdf5 compartment file, then read data for each population
  variable compartHash
  set pop_list [hdf5_list_sonata_compart_pops $compart_filename]
  foreach pop_name $pop_list {
     read_store_hdf5_compart_pop $compart_filename $pop_name 
     puts "In load_hdf5_compart_file: length compartHash($pop_name,index_pointer) is [llength $compartHash($pop_name,index_pointer)]"

  }
 
}

proc ::neuro::read_store_hdf5_nodes_pop {mainfilename fileset_num pop group_list y_rot_only} {
  # read in data for a single population within an hdf5 nodes file.  The group_list for that population is provided.  
  variable node
  variable morphoHash 
  variable globalNodeIdCount
  variable globalNodeIdList
  variable typeAttribList
  variable node_attrib_dictHash
  set unskipped_group_list ""
  set avail_datasets [hdf5_list_datasets $mainfilename]

  #first, read in 4 population-wide fields for the whole pop

  set id_path "/nodes/${pop}/node_id"
  set type_path "/nodes/${pop}/node_type_id"
  set group_id_path "/nodes/${pop}/node_group_id"
  set group_index_path "/nodes/${pop}/node_group_index"
  
  # Read in these 4 fields, which must be present for each population ...
  # XXX Read in and store locally for local lookups by node_group_id and node_group_index
  # That is, for each pop, we store for all nodes node_id node_type_id node_group_index node_group_id , which we will soon search by  node_id node_type_id .  We later locally  look up node_type_id in this table, keyed by (node_group_id and node_group_index)  For example search a pop-wide  list made of elements {node_id node_type_id node_group_index node_group_id }, for node_group_id = 2, node_group_index =11 , and get node_type_id and node_id from these.  We store node_id, but it is only of importance for users doing technical checks / building systems..  
  # each _path is an HDF5 path
  
  foreach vec {idv typev group_idv group_indexv} pathname {id_path type_path group_id_path group_index_path} {
    set the_path [set $pathname]
    puts "vec= $vec the_path= $the_path "
    if {[lsearch -exact $avail_datasets $the_path]==-1} {
      showError "ERROR: required hdf5 dataset $the_path was not found"
      return
    }
    if {$the_path != ""} {
      # XXX do other tests and zero-fill if need be.
      puts "about to hdf5_simple_dataset $mainfilename $the_path"
      set $vec [hdf5_simple_dataset $mainfilename $the_path]
    } else {
        showError "ERROR: required hdf5 dataset $the_path not found"
    } 
  }
  # now assign to a lookup list of popNodes, all the nodes in this population
  set popNodes ""
  foreach eid $idv etype $typev egroup_id $group_idv egroup_index $group_indexv {
    lappend popNodes [list $eid $etype $egroup_id $egroup_index]
  }
  puts "about to loop over group_list" 
  foreach node_group $group_list { 
    # second, read in the group specific fields 
    # puts "starting node_group $node_group"
    # find the number of nodes in this group
    set ns_attrib_list [hdf5_list_group_ns_attribs $mainfilename $pop $node_group]
    set groupNodes [ lsearch -inline -all -index 2 $popNodes $node_group]
    set sortedGroupNodes [lsort -integer -increasing -index 3  $groupNodes]
    #puts "groupNodes is $groupNodes.\n  sortedGroupNodes is $sortedGroupNodes"  
    set theVecLength [llength $groupNodes] 
    puts "just produced sortedGroupNodes.  theVecLength=$theVecLength   length of sortedGroupNodes= [llength $sortedGroupNodes]" 
    set check [lindex $sortedGroupNodes 0]
    puts "the 0th element of sortedGroupNodes is $check" 
    set x_path "/nodes/${pop}/$node_group/x"
    set y_path "/nodes/${pop}/$node_group/y"
    set z_path "/nodes/${pop}/$node_group/z"
    set yaxis_path "/nodes/${pop}/$node_group/rotation_angle_yaxis"
    #XX later, assign x,y,zaxis path together so clearer about assumed per-node paths, and the writing of default values if not present 
    # here, we no longer skip, we just set group_has_cartesian to False  if all of X, Y, Z are missing 
    if {([lsearch -exact $avail_datasets $x_path]==-1) && ([lsearch -exact $avail_datasets $y_path]==-1) && ([lsearch -exact $avail_datasets $z_path]==-1)} {
     showError "No x,y, or z coordinates found for group nodes/${pop}/$node_group. Setting cartesian to False for this group."
     set group_has_cartesian False
    } else {
     set group_has_cartesian True
    }
    # XX This skipping is an artifact from early version, when groups of nodes without Cartesian coordinates would simply be skipped.  Now, no node groups are skipped, so checks for skipping should be removed.  Insteaad, checks in other, appropriate places (display, geometry search time, some queries) check for cartesian=True for a node.
    #  For reading in edges, can't skip any nodes
    lappend unskipped_group_list $node_group 
    if {$group_has_cartesian} {
      if {$y_rot_only} {
        set xaxis_path ""
        set zaxis_path ""
      } else {
        set xaxis_path "/nodes/${pop}/$node_group/rotation_angle_xaxis"
        set zaxis_path "/nodes/${pop}/$node_group/rotation_angle_zaxis"
      }
    } else {
      set x_path ""; set y_path ""; set z_path ""
      set xaxis_path ""; set yaxis_path ""; set zaxis_path ""
    } 
    #XX We above found theVecLength we expect for these vecs from size of this group.
    foreach vec {xv yv zv xrotv yrotv zrotv } pathname {x_path y_path z_path xaxis_path yaxis_path zaxis_path } {
      set $vec ""
      if {$group_has_cartesian} {
        #Do zero-filling for various cases of group_has_cartesian=True.
        set the_path [set $pathname]
        puts "vec= $vec the_path= $the_path  (group id)=node_group= $node_group"
        #note group_index is the position in this list, the index as stored in hdf5 dataset, counting from 0
        #below, when we set node_group_index for each node, we make use of this fact
        if {[lsearch -exact $avail_datasets $the_path]==-1} {
          puts "WARNING: could not find dataset $the_path"
          set the_path ""
        }
        if {$the_path != ""} {
          # XXX do other tests and zero-fill if need be.
          puts "about to hdf5_simple_dataset $mainfilename $the_path"
          # set the referenced var, example: when $vec=xv, set xv [...]
          set $vec [hdf5_simple_dataset $mainfilename $the_path]
          puts "pop=$pop node_group=$node_group  just set $vec with length [llength [expr $$vec]]"
        } else {
          # populate with zeroes if corresponding hdf5 path not preset
          puts "about to zero fill for $the_path vec= $vec"
          for {set i 0} {$i<$theVecLength} {incr i} {
            lappend $vec 0
          }
          puts "set $vec to 0 vector with length [llength [set $vec]]"
        } 
      } else {
        #For group_has_cartesian=False, simple: x,y,z,xrot,yrot,zrot are all set to NULL  
        for {set i 0} {$i<$theVecLength} {incr i} {
          #lappend $vec NULL
          # XXX note this  hack, placing all non-cartesian to 0,0,0
          lappend $vec 0 
        }
        puts "set $vec to 0 vector (should have been NULL vector)  with length [llength [set $vec]]"
      }
    } 
   
   
     
    set group_index 0
    set group_start_GNID_count $globalNodeIdCount
    foreach ex $xv ey $yv ez $zv exrot $xrotv eyrot $yrotv  ezrot $zrotv curNode $sortedGroupNodes {
      # we assume list of nodes in group is correct length
      # XX check length of sortedGroupNodes
      ##XX FIX with zero filling so can handle absent rots
      # find type and node_id based on group index)
      # popNodes are stored as {$id $type $group_id $group_index}
      ##set matchedNodeList [lsearch -inline -all -index 3 $groupNodes $group_index]
      ##set matches [llength $matchedNodeList]
      foreach {node_id type check_group_id check_group_index} $curNode {}
      #if {$group_index%5000==0 || ($node_id==9276 && $pop=="lgn") || ($node_id==9299 && $pop=="lgn")} {
           #puts "matchedNode: node_id= $node_id type= $type check_group_id= $check_group_id check_group_index= $check_group_index  from search node_group= $node_group group_index= $group_index" 
      #}
      # store all values in the node
       
      set node($globalNodeIdCount) [list $ex $ey $ez $exrot $eyrot $ezrot $type $fileset_num $pop $node_id $node_group $group_index True]
      # Note that cartesian is forced True.  See above hack sending non-cartesian to 0 .
      # for now, globalNodeIdList should be simply a 0-counting list with element n having value n. Carryover from when nodeId was arbitrary.  The globalNodeIdList of globalNodeId's, and sub-lists,  is what is used for selections  
      lappend globalNodeIdList $globalNodeIdCount
      #assign dict entries for $node_attrib_dictHash


      incr globalNodeIdCount
      incr group_index
    }
    # now read in non-standard attribs for this group
    foreach attrib $ns_attrib_list {
      # add to typeAttribList if not already present
      if {[lsearch -exact $typeAttribList($fileset_num) $attrib] == -1 } {
        lappend typeAttribList($fileset_num) $attrib
      }
      puts "Attrib Check: attrib= $attrib added to typeAttribList($fileset_num)= $typeAttribList($fileset_num)"
      #read in the attrib data vector for this group
      set the_path "/nodes/${pop}/$node_group/$attrib" 
      set v [hdf5_simple_dataset $mainfilename $the_path]
      #do checks on vec length
      puts "attrib check: theVecLength= $theVecLength length(vec)= [llength $vec] atttrib= $attrib node_group= $node_group"
      set i 0
      foreach e $v {
        #if {[expr $i % 50 == 0]} {
        #  puts "Starting attrib check: i= $i e=$e"
        #}
        set cur_GNID [expr $group_start_GNID_count + $i]
        #puts "cur_GNID= $cur_GNID"
        dict set node_attrib_dictHash($cur_GNID) $attrib $e
        # the dict command deals create a new dict if needed / add key 
        if {[expr $cur_GNID % 500 == 0]} {
          puts "attrib= $attrib i= $i e= $e cur_GNID= $cur_GNID  dict value: [dict get $node_attrib_dictHash($cur_GNID) $attrib]"
        }
        #puts "Attrib check done"
        incr i 
      }
    }
  }
  puts "Exiting read_store_hdf5_nodes.  Length globalNodeIdList= [llength $globalNodeIdList]"
  #Now show the nodes
   #multiple node coordinates by node_scale so same scale as swc
  return $unskipped_group_list   
}




proc ::neuro::read_sonata_circuit_json {user_working_dir config_file_path {reading_edges False}} {
  variable num_filesets
  variable fileset_pop_unskipped_group_list
  variable num_edge_filesets
  variable fileset_pop_group_list
  variable edge_fileset_pop_group_list
  #XX params need absolute paths - repair or error if not? 
  #read SONATA circuit file
  #get this filename from topmost config file
  #set user_working_dir [file normalize $user_working_dir]
  #set config_file_path [file normalize $config_file_path] 
  set config_file_dir  [file dirname $config_file_path]
  set CONFIGFILE [open $config_file_path r]
  set file_contents [read $CONFIGFILE]
  close $CONFIGFILE 
  #puts "Just read in this file:"
  #puts $file_contents
  #puts "File ends."
  #XX add error checking
  set pre_manifest [dict create]
  dict set pre_manifest "\$workingdir" $user_working_dir
  dict set pre_manifest "\$configdir" $config_file_dir
  dict set pre_manifest "\$configname" $config_file_path
  # outputname could be set in runbionet.py -- but this seems unfair, should not have to parse python. See PassThroughOptionParser(). Note that runbionet.py ends with run(config_file, **usr_vars)
 # need list of all possivle variables
  dict set pre_manifest "\$use_recurrent" True
  dict set pre_manifest "\$use_lgn" True
  dict set pre_manifest "\$use_dr" False
  dict set pre_manifest "\$lgn_file" DEFAULT_LGN
  dict set pre_manifest "\$bkg_file" DEFAULT_BKG
  dict set pre_manifest "\$overwrite" False
  dict set pre_manifest "\$output_name" output

  set file_conf [::json::json2dict  $file_contents ] 
  set file_manifest [dict get $file_conf manifest]
  # Perform variable substition for the manifest only, using the $myvar and ${myvar} additon to json that SONATA supports
  puts "THE FILE MANIFEST: $file_manifest "
  set sonata_manifest [build_manifest $file_manifest $pre_manifest]
  # Process the raw file a second time, now using the manifest to replace $myvar and ${myvar} variables
  set replaced_file_contents ""
  set fileLines [split $file_contents "\n"]
  foreach raw_line $fileLines {
    puts "fileLine: $raw_line"
    set replaced_line [find_variables $raw_line $sonata_manifest]
    puts "replacedLine: $replaced_line"
    append replaced_file_contents $replaced_line
    append replaced_file_contents "\n"
  }
  puts "Replaced file START"
  puts $replaced_file_contents
  puts "Replaced file END"
  #Now process these processed lines
  set replaced_conf  [::json::json2dict  $replaced_file_contents ]


      
  #dict set file_conf manifest $sonata_manifest
  #recursive_insert $file_conf $sonata_manifest
  if {[dict exists $replaced_conf components morphologies_dir] } {
    set the_morphologies_dir [absolute_dir [dict get $replaced_conf components morphologies_dir] $config_file_dir] 
  } else {
    neuro::showMessage "Warning: a morphologies directory was not defined" 
    set the_morphologies_dir NULL
  } 
  puts "the_morphologies_dir= $the_morphologies_dir"
  # XX Note: he_base_dir and the_network_dir NETWORK_DIR  may not matter directly -- and can be overriden -- after  variable substituion
  if { [catch {set the_base_dir [dict get $sonata_manifest {$BASE_DIR}]}] } {
   set the_base_dir $user_working_dir
  }
  # XX Catch errors here.  Will fail if manifest typos / omissions in config file.
  # however, NETWORK_DIR my be optional - user could hard code or use different variables

  set the_network_dir [absolute_dir [dict get $sonata_manifest {$NETWORK_DIR}] $config_file_dir]

  # End of manifest and diectory setup here.
  # Get the list of dicts: { {nodes_file_A, node_types_file_A}, {nodes_file_B, node_types_file_B}}
  # XX clear typeList(num_filesets) and typeHash
  # XXX , or one for each file set, or:
  #   one typeLisst, each entry 2D hash (1,100001)  (unique-types-file,type)?

  
  #first, read in the nodes 
  set dict_list [dict get $replaced_conf networks nodes]
  puts "dict_list is $dict_list"
  set fileset_pop_unskipped_group_list ""
  foreach e $dict_list {
    #puts "\n\ndict_list e is $e" 
    set the_nodes_file [absolute_filename [dict get $e nodes_file] $config_file_dir]
    set the_node_types_file [absolute_filename [dict get $e node_types_file] $config_file_dir ]
    #puts "  the_nodes_file= $the_nodes_file\n   the_node_types_file= $the_node_types_file"
    #now normalize the file names so no "."
    set fileset_num $num_filesets
    set pop_unskippedgroup_list [load_hdf5_node_file_pair $fileset_num $the_nodes_file  $the_node_types_file  $the_morphologies_dir ]
    lappend fileset_pop_unskipped_group_list [list $num_filesets $pop_unskippedgroup_list]

    incr num_filesets
  }

  if {$reading_edges} {
    #now read in the edges
    # X current vars for this look like above but with edge_ preprended or substituted.
    # X later, change the analagous  var names immed. above so have node_ in them, (nodes were once only thing read in, but for example, edge_dict_list is just as important as dict_list, the version for nodes)
    set edge_dict_list [dict get $replaced_conf networks edges]
    puts "edge_dict_list is $edge_dict_list"
    set edge_fileset_pop_group_list ""
    #no group will get skipped
    foreach e $edge_dict_list {
      #puts "\n\nedge_dict_list e is $e" 
      set the_edges_file [absolute_filename [dict get $e edges_file] $config_file_dir]
      set the_edge_types_file [absolute_filename [dict get $e edge_types_file] $config_file_dir ]
      #puts "  the_edgess_file= $the_edges_file\n   the_edge_types_file= $the_edge_types_file"
      #now normalize the file names so no "."
      set edge_pop_group_list [load_hdf5_edge_file_pair $num_edge_filesets $the_edges_file  $the_edge_types_file]  
      lappend edge_fileset_pop_group_list [list $num_edge_filesets $edge_pop_group_list]

      incr num_edge_filesets
    }
    puts "Done reading nodes and edges." 
  } else {
    puts "Done reading nodes. (Reading edges is turned off.)" 
  }
}  


proc ::neuro::find_variables {json_str manifest} {
  #  (Following SONATA python version)
  # Replaces variables (i.e. $VAR, ${VAR}) with their values from the manifest.
  #
  #    :param json_str: a json string that may contain none, one or multiple variable
  #    :param manifest: dictionary of variable lookup values
  #    :return: json_str with resolved variables. Won't resolve variables that don't exist in manifest.
 

  set slashprefix "\\"
  set dollarprefix "$"
  foreach var [ regexp -inline -all {\$\{?[\w]+\}?} $json_str] {
     set var_found $var
     #puts "var_found = >$var<"
     if { [regexp {^\$\{}  $var] &&  [regexp {\}$} $var] } {
      # replace ${VAR} with $VAR
       set var $dollarprefix[string range $var_found 2 end-1]
       #puts "bracketed found: var_found= >$var_found< var = >$var<"
     }
     if {[dict exists $manifest $var]} {
       #puts "will sub in: [dict get $manifest $var]"
       set escaped_var_found $slashprefix$var_found
       set json_str [regsub $escaped_var_found $json_str [dict get $manifest $var] ]
     }
    }
    
    #puts "End of find_variables.  json_str= $json_str"
    return $json_str

}

  
proc ::neuro::list_subtract {listA listB} {
  #return elements of listA that are not in listB
  set listRes [list]
  foreach e $listA {
    if {$e ni $listB} {
      lappend listRes $e
    }
  }
  return $listRes
}
    
proc ::neuro::build_manifest {manifest_in special_variables} {
  #  (Following SONATA python version)
  # equivalent for test to manifest = conf["manifest"]
  set manifest $manifest_in

  set resolved_manifest $special_variables

  set resolved_keys [list]
  set  unresolved_keys  [dict keys $manifest]

  while {[llength $unresolved_keys] > 0} {
    puts "starting loop, [llength $unresolved_keys] unresolved keys"
    foreach key $unresolved_keys {
     # Find all variables in manifest and see if they can be replaced by the value in resolved_manifest
     set value [ find_variables [dict get $manifest $key] $resolved_manifest]
     # If value no longer has variables, and key-value pair to resolved_manifest and remove from unresolved-keys
     if { [ regexp {\$} $value ] == 0} {
       dict set resolved_manifest $key $value
       lappend resolved_keys $key
       puts "resolved_keys = $resolved_keys"
     }

     }
     #     # remove resolved key-value pairs from set, and make sure at every iteration unresolved_keys shrinks to prevent
     #     # infinite loops
     set n_unresolved [llength $unresolved_keys]
     set unresolved_keys [list_subtract $unresolved_keys $resolved_keys] 
     if {$n_unresolved == [llength $unresolved_keys]} {
       error "Error: Unable to resolve manifest variables:  $unresolved_keys"
     } 
  }
  puts "Now to return resolved manifest..."
  return $resolved_manifest
}    

proc ::neuro::test_manifest {} {
  set sample_manifest [dict create]
  dict set sample_manifest a horse 
  dict set sample_manifest b cat
  dict set sample_manifest c {this/$configdir/thefile.txt}
  dict set sample_manifest d {this/${configname}.extra}

  set pre_manifest [dict create]
  dict set pre_manifest "\$workingdir" MYWORKINGDIR 
  dict set pre_manifest "\$configdir" MYCONFIGDIR 
  dict set pre_manifest "\$configname" MYCONFIGNAME
  build_manifest $sample_manifest $pre_manifest
}

proc ::neuro::is_dict {value} {
#Tcl is inherently typeless (except for assoc. arrays) until variable is used, this proc is only identifying a string which couldd be used as an even-numbered list.  
    return [expr {[string is list $value] && ([llength $value]&1) == 0}]
}

proc ::neuro::is_list {value} {
#Tcl is inherently typeless until variable is used, this proc is only identifying a string which couldd be used as an even-numbered list.  
    return [expr {[string is list $value]} 
}

proc ::neuro::absolute_dir {dir default_dir} {
  if {[file pathtype $dir] == "absolute"} {
    return [file normalize $dir]
  } else {
    return [file normalize [file join $default_dir $dir]]
  }
}

 proc ::neuro::absolute_filename {filename default_dir} {
   set the_dir [file dirname $filename]
   set the_shortname [file tail $filename] 
   set the_abs_dir [absolute_dir $the_dir $default_dir]
   return [file normalize [file join $the_abs_dir $the_shortname]]
}


proc ::neuro::swc_to_edges_source_target {globalNodeId swcList} {
   #accepts list of descriptions of swcs in a given globalNodeId,  and produces two lists of edges which contain the swc as a source and which contain the swc as a target.
   #for current edge file format only afferent swcs, so can produce only target matches
  variable globalEdgeIdList
  variable edge_pop_hash
  variable edge
  variable node 
   
  puts "starting swc_to_edges_source_target length swcList= [llength $swcList]"

  foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($globalNodeId) {}
  set pop $epop 
  set node_id $enode_id

  set source_node_edge_list ""
  set target_node_edge_list "" 
  foreach swc_id $swcList {
    #puts "now for swc_id= $swc_id"
    foreach e $globalEdgeIdList {
      foreach {etype esource_node_id etarget_node_id eedge_group_id egroup_index eedge_fileset_num epop epos_x epos_y epos_z eaff_swc_id eaff_swc_pos eaff_section_id eaff_section_pos}  $edge($e) {}
      set edge_source_node_pop $edge_pop_hash(source_node_population,$eedge_fileset_num,$epop)
      set edge_target_node_pop $edge_pop_hash(target_node_population,$eedge_fileset_num,$epop)
      #puts "swc_id= $swc_id   eaff_swc_id= $eaff_swc_id"
      if { ( $edge_target_node_pop eq $pop ) && ($etarget_node_id eq $node_id) && ($eaff_swc_id eq $swc_id) } {
            puts "target/aff: pop= $pop  node_id=$node_id swc_id= $swc_id "
            lappend target_node_edge_list $e
      }
      # file format means there is no efferent, no need to match.
      if { ( $edge_source_node_pop eq $pop ) && ($esource_node_id eq $node_id) } {
            # these targets will always be shown at soma, since no eff (target) swc in edge file format
            #puts "source/eff: pop= $pop  node_id=$node_id swc_id (ignored)= $swc_id "
            lappend source_node_edge_list $e
            #will likely ignore this list, since it should just provide same edges overall as target search.  Could enable to be used for a consistency check, perhaps with searches.
      } 
    }
  }

  return [list $source_node_edge_list $target_node_edge_list]
}

proc ::neuro::edges_source_nodes_target_nodes {sourceGlobalNodeIdList targetGlobalNodeIdList} {
  variable globalEdgeIdList
  variable edge_pop_hash
  variable edge
  variable node
  variable globalEdgeDataList
  variable globalEdgeDataListSortedSource
  variable globalEdgeDataListSortedTarget

  # translate source and target globalNode Id's into information we can check against edges (namely, population and source/target (local) node_id)
  set sourceNodes ""
  foreach e $sourceGlobalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    lappend sourceNodes [list $epop $enode_id ]
  }
  set targetNodes ""
  foreach e $targetGlobalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($e) {}
    puts "target node($e) epop= $epop  enode_id= $enode_id"
    lappend targetNodes [list $epop $enode_id ]
  }
  puts "Length: [llength $sourceNodes] sourceNodes"
  puts "Length: [llength $targetNodes] targetNodes"
  set source_node_edges ""
  # Search edges to see which have sourceNodes in range, generate a dataList of these edges (dataList format same as edge format, but has globalEdgeId appended, so a list is usable when sorted).   Then search these edges for pop matches, and make a list of matching global edge id's.  
  foreach n $sourceNodes {
    foreach {searchnode_pop searchnode_node_id} $n  {}
      #first, we match only for the source node Id (lsearch -sorted option includes acting like -exact option )
    set node_id_match_data_list_indices [lsearch -integer -all -index 1  $globalEdgeDataList $searchnode_node_id]
    #puts "for node_id $searchnode_node_id, length of node_id_match_data_list_indices is [llength $node_id_match_data_list_indices]"
    #second, we search among this node_id_match_data_list for also making pop match 
    foreach node_match_index $node_id_match_data_list_indices {
      # note dataList style, has appended globalEdgeId
      #puts "from node_id_match_data_list   node_match_index= $node_match_index"
      foreach {etype esource_node_id etarget_node_id eedge_group_id egroup_index eedge_fileset_num epop epos_x epos_y epos_z eaff_swc_id eaff_swc_pos eaff_section_id eaff_section_pos}  $edge($node_match_index) {}
      set edge_source_node_pop $edge_pop_hash(source_node_population,$eedge_fileset_num,$epop)
      if { ($edge_source_node_pop == $searchnode_pop) && ($esource_node_id == $searchnode_node_id) } {
        lappend source_node_edges $node_match_index
      }
    }
    #puts "did a source pop match round, searchnode_node_id= $searchnode_node_id  source node $n, llength source_node_edges is [llength $source_node_edges]"
  }


  # previous slower method for matching source and pop:
  #foreach e $globalEdgeIdList {
  #  foreach {etype esource_node_id etarget_node_id eedge_group_id egroup_index eedge_fileset_num epop epos_x epos_y epos_z}  $edge($e) {}
  #  # XX catch error from next line
  #  set edge_source_node_pop $edge_pop_hash(source_node_population,$eedge_fileset_num,$epop)
  #  foreach n $sourceNodes {
  #    foreach {searchnode_pop searchnode_node_id} $n  {
  #      #puts "edge test: searchnode_pop= searchnode_pop edge_source_node_pop= $edge_source_node_pop\n  searchnode_node_id= $searchnode_node_id esource_node_id= $esource_node_id"
  #      if { ($edge_source_node_pop == $searchnode_pop) && ($esource_node_id == $searchnode_node_id) } {
  #        lappend source_node_edges $e
  #      }
  #    }
  #  }
  #}
  puts "search partially complete, matches to only source_node_edge= [llength $source_node_edges]" 
  # search this subset of edges which has sourceNode in order to see which of these edges also have targetNodes
  set source_and_target_node_edges ""
  foreach e $source_node_edges {
    foreach {etype esource_node_id etarget_node_id eedge_group_id egroup_index eedge_fileset_num epop epos_x epos_y epos_z eaff_swc_id eaff_swc_pos eaff_section_id eaff_section_pos}  $edge($e) {}
    set edge_target_node_pop $edge_pop_hash(target_node_population,$eedge_fileset_num,$epop)
    foreach n $targetNodes {
      foreach {searchnode_pop searchnode_node_id} $n  {
        if { ($edge_target_node_pop == $searchnode_pop) && ($etarget_node_id == $searchnode_node_id) } {
          # add to the list of edges that reach both source and target
          lappend source_and_target_node_edges $e
        }
      }
    }
  }

  puts "search complete. source_and_target_node_edges is [llength $source_and_target_node_edges]"
  return $source_and_target_node_edges
}

proc ::neuro::proto_show_edges_from_list {subsetEdgeIdList style colorMethod sph_radius sph_resolution cyl_radius cyl_resolution} {
  # Display the edges
  # colorMethod is "Type" or an integer.  
  #    ... which colors by type if "Type", is constant assigned color if integer.
  # multiple node coordinates by node_scale so same scale as swc
 
  variable edge
  variable edge_pop_hash
  variable node
  variable globalNodeIdList
  variable morphoHash
  variable typeHash
  # set sph_radius 5 
  # set sph_resolution 6
  # set cyl_radius 0.1
  # set cyl_resolution 6
  puts "starting proto_show_edges.  colorMethod is $colorMethod"
  set n 0
  puts "about to display [llength $subsetEdgeIdList] edges"
  set edgeRenderList ""
  foreach theEdgeId $subsetEdgeIdList {
    #puts "Now to display an edge.   theId= $theId edge($theId)= >$edge($theId)<"

    foreach {etype esource_node_id etarget_node_id eedge_group_id egroup_index eedge_fileset_num epop epos_x epos_y epos_z eaff_swc_id eaff_swc_pos eaff_section_id eaff_section_pos} $edge($theEdgeId) {}
    set source_globalNodeId -1
    set target_globalNodeId -1
    set source_pop $edge_pop_hash(source_node_population,$eedge_fileset_num,$epop)
    set target_pop $edge_pop_hash(target_node_population,$eedge_fileset_num,$epop)
    #puts "source edgepop is $epop, node source_pop= $source_pop"
    #puts "target edgepop is $epop, node target_pop= $target_pop"
    #puts "Need to match for source: esource_node_id= $esource_node_id  source_pop= $source_pop  edge__fileset= $eedge_fileset_num" 
    #puts "Need to match for target: etarget_node_id= $etarget_node_id  target_pop= $target_pop  edge__fileset= $eedge_fileset_num" 
    set source_ex NULL
    set source_ey NULL
    set source_ez NULL
    set source_exrot NULL
    set source_eyrot NULL
    set source_ezrot NULL
    set target_ex NULL
    set target_ey NULL
    set target_ez NULL
    set target_exrot NULL
    set target_eyrot NULL
    set target_ezrot NULL
    #puts "etype= $etype esource_node_id= $esource_node_id etarget_node_id= $etarget_node_id eedge_group_id= $eedge_group_id egroup_index= $egroup_index eedge_fileset= $eedge_fileset_num epop= $epop epos_x =$epos_x epos_y =$epos_y epos_z= $epos_z"
    #foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    #puts "list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian"

    if {$colorMethod=="Type"} {
      set theColor [expr $etype % 32 ] 
      #set black color to gray, since black is most common background
      if {$theColor == 16} {set theColor 2}
      #draw color $c
      #puts "set color to $c" 
    } else {
      set theColor $colorMethod
    }
    #puts "color =$c"
    #puts "etype= $etype esource_node_id= $esource_node_id etarget_node_id= $etarget_node_id eedge_group_id= $eedge_group_id egroup_index= $egroup_index eedge_fileset= $eedge_fileset_num epop= $epop epos_x =$epos_x epos_y =$epos_y epos_z= $epos_z"
    #proto_show_morph_moved_soma_only $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot 3
    #find coordinates and other info aboout affectetd nodes

    #puts "edge pop is $epop, source_pop= $source_pop"
    foreach theId $globalNodeIdList {
      set source_ex NULL
      set source_ey NULL
      set source_ez NULL
      set source_exrot NULL
      set source_eyrot NULL
      set source_ezrot NULL
     
      foreach {tx ty tz txrot tyrot tzrot ttype tfileset_num tpop tnode_id tgroup_id tgroup_index tcartesian}  $node($theId) {}
      #puts "node($theId) = $node($theId)"
      #puts "testing node= >$tnode_id< tgroup_id= >$tgroup_id< pop=$tpop fileset= $tfileset_num"
 
      if {($tpop==$source_pop) && ($tnode_id==$esource_node_id) } {

      #puts "found source match: theId= $theId tpop= >$tpop<  tnode_id= $tnode_id tx= eedge_fileset_num= $eedge_fileset_num$ tx= $tx ty= $ty tz= $tz"
      #puts "found source:  pop: $tpop  target tests: line: tx= $tx  ty= $ty  tz= $tz  txrot= $txrot  tyrot= $tyrot  tzrot= $tzrot  ttype= $ttype  tfileset_num= $tfileset_num  tpop= $tpop  tnode_id= $tnode_id  tgroup_id= $tgroup_id  tgroup_index= $tgroup_index tcartesian= $tcartesian"
      #puts "testing node= >$tnode_id< tgroup_id= >$tgroup_id< pop=$epop fileset= $tfileset_num"

        set source_ex $tx 
        set source_ey $ty 
        set source_ez $tz 
        set source_exrot $txrot 
        set source_eyrot $tyrot 
        set source_ezrot $tzrot 
        set source_globalNodeId $theId
        break
      }
    }

    foreach theId $globalNodeIdList {
      set target_ex NULL
      set target_ey NULL
      set target_ez NULL
      set target_exrot NULL
      set target_eyrot NULL
      set target_ezrot NULL
      foreach {tx ty tz txrot tyrot tzrot ttype tfileset_num tpop tnode_id tgroup_id tgroup_index tcartesian}  $node($theId) {} 

      #puts "target pop: $tpop  target tests: line: tx= $tx  ty= $ty  tz= $tz  txrot= $txrot  tyrot= $tyrot  tzrot= $tzrot  ttype= $ttype  tfileset_num= $tfileset_num  tpop= $tpop  tnode_id= $tnode_id  tgroup_id= $tgroup_id  tgroup_index= $tgroup_index tcartesian= $tcartesian"
      #puts "node($theId) = $node($theId)"
      #puts "testing node= >$tnode_id< etarget_node_id= >$etarget_node_id< eedge_fileset_num= $eedge_fileset_num fileset= $tfileset_num tgroup_id= >$tgroup_id< pop=$epop"

      if { ($tpop==$target_pop) && ($tnode_id==$etarget_node_id) } {
        #puts "found target match: theId= $theId tpop= >$tpop<  tnode_id= $tnode_id tx= $tx ey= $ty ez= $tz"
        #puts "found target:  pop: $tpop  target tests: line: tx= $tx  ty= $ty  tz= $tz  txrot= $txrot  tyrot= $tyrot  tzrot= $tzrot  ttype= $ttype  tfileset_num= $tfileset_num  tpop= $tpop  tnode_id= $tnode_id  tgroup_id= $tgroup_id  tgroup_index= $tgroup_index tcartesian= $tcartesian"
        set target_ex $tx 
        set target_ey $ty 
        set target_ez $tz 
        set target_exrot $txrot 
        set target_eyrot $tyrot 
        set target_ezrot $tzrot 
        set target_globalNodeId $theId
        break;
      }
    }
    # XX add morph source target posistions later.  for now, not even pos_x from the ege from is preent
    # XX later set actual count of source/target duplicates-- maybe this is just run for drawing every time and removed (because might want dynamic edges-from-source count, edges-to-target count, and edge duplicate count)
    set count -1
    lappend edgeRenderList [list $theEdgeId $count $theColor $source_globalNodeId $source_ex $source_ey $source_ez $source_exrot $source_eyrot $source_ezrot $target_globalNodeId $target_ex $target_ey $target_ez $target_exrot $target_eyrot $target_ezrot $eaff_swc_id $eaff_swc_pos $eaff_section_id $eaff_section_pos ]
 
    incr n
    #end of checking edge for match
  }
  
  #now proceed through edgeRenderList and draw edges
  puts "now to display edgeRenderList"
  foreach edge_e  $edgeRenderList {
     foreach {theEdgeId count theColor source_globalNodeId source_ex source_ey source_ez source_exrot source_eyrot source_ezrot target_globalNodeId target_ex target_ey target_ez etarget_exrot target_eyrot target_ezrot eaff_swc_id eaff_swc_pos eaff_section_id eaff_section_pos} $edge_e {}
     # XX later, consolidate these into lists for easier use
     # note that the eaff* are about targets, but are properties of the edge
     #foreach {source_ex source_ey source_ez} $source_pos {}
     #foreach {target_ex target_ey target_ez} $target_pos {}
     #foreach {source_morph_x source_morph_y source_morph_z} $source_morph_pos {}
     #foreach {target_morph_x target_morph_y target_morph_z} $target_morph_pos {}
     draw color $theColor
    #puts "Both source and target match. Now to  draw line from $source_ex $source_ey $source_ez to $target_ex $target_ey $target_ez source_globalNodeId= $source_globalNodeId  target_globalNodeId= $target_globalNodeId"
    if {($source_ex!="NULL") && ($target_ex!="NULL")} {
       #puts "Found both source and target match. Now draw line from $source_ex $source_ey $source_ez to $target_ex $target_ey $target_ez source_globalNodeId= $source_globalNodeId  target_globalNodeId= $target_globalNodeId"
      switch -regexp $style {
        ^simple_edge$   {
                        draw cylinder [list $source_ex $source_ey $source_ez]  [ list $target_ex $target_ey $target_ez] radius $cyl_radius resolution $cyl_resolution 
        } 
       
        ^count_thickness_edge$ {
          #may need normalization paramaters
          puts "WARNING: STUB.  NOT IMPLEMENTED YET"
        }

        ^source_soma$   { draw sphere [list $source_ex $source_ey $source_ez] radius $sph_radius resolution $sph_resolution 
        }

        ^target_soma$   { draw sphere [list $target_ex $target_ey $target_ez] radius $sph_radius resolution $sph_resolution 
        }

        ^simple_edge_swc$|^source_sphere_swc$|^target_sphere_swc$|^source_target_sphere_swc$ {
          # find fileset of target (afferent) neuron
          #    each point is: #    {n type x y z radius parent} 
          #XX maybe better to do node info lookup here, vs making huge vector for edge list
          foreach {s_ex s_ey s_ez s_exrot s_eyrot s_ezrot s_etype s_efileset_num s_epop s_enode_id s_egroup_id s_egroup_index s_ecartesian}  $node($source_globalNodeId) {}
          foreach {t_ex t_ey t_ez t_exrot t_eyrot t_ezrot t_etype t_efileset_num t_epop t_enode_id t_egroup_id t_egroup_index t_ecartesian}  $node($target_globalNodeId) {}
          set target_pointList $morphoHash($t_efileset_num,$t_etype)
          #find match in target_pointList for $eaff_swc_id   
          puts "t_efileset_num= $t_efileset_num  t_etype= $t_etype"
          puts "theEdgeId= $theEdgeId target_globalNodeId= $target_globalNodeId t_etype= $t_etype  eaff_swc_id is $eaff_swc_id, llength target_pointList= [llength $target_pointList]"
          set morph_point_num [lsearch -exact -index 0 $target_pointList $eaff_swc_id]
          puts "morph_point_num= $morph_point_num"
          if {$morph_point_num == -1} {
            #draw nothing
            puts "Warning: no swc morphology point found to draw"
          } else {
              set morph_point [lindex $target_pointList $morph_point_num]
              foreach {mp_n mp_type mp_x mp_y mp_z mp_radius mp_parent} $morph_point {}
              set morph_point_parent_num [lsearch -exact -index 0 $target_pointList $mp_parent]
              if {$morph_point_parent_num == -1 } {
                puts "Warning: morph point parent not found, using morph_point_num in place of morph_point_parent_num"
                set morph_point_parent_num $morph_point_num
              }
              set morph_point_parent [lindex $target_pointList $morph_point_parent_num]
              foreach {mp_par_n mp_par_type mp_par_x mp_par_y mp_par_z mp_par_radius mp_par_parent} $morph_point_parent {}
              puts "morph_point_num= $morph_point_num  morph_point_parent_num= $morph_point_parent_num mp_x= $mp_x $mp_y= $mp_y mp_z= $mp_z mp_par_x= $mp_par_x $mp_par_y= $mp_par_y mp_par_z= $mp_par_z" 
               
              set type_zrot $typeHash(rot_zaxis,$t_efileset_num,$t_etype)
              set m [transmult  [transoffset [list $t_ex $t_ey $t_ez]] [transaxis x $t_exrot rad ] [transaxis y $t_eyrot rad] [transaxis z $t_ezrot rad] [transaxis z [expr $type_zrot] rad]]
              set v [list $mp_x $mp_y $mp_z]
              set v_par [list $mp_par_x $mp_par_y $mp_par_z]
               #move the points
              set vm [coordtrans $m $v]
              set vm_par [coordtrans $m $v]
              puts "vm= $vm  vm_par= $vm_par"
              set v_target_pos [vecadd $vm_par [vecscale $eaff_swc_pos  [vecsub $vm $vm_par]]]
              puts "vm= $vm  vm_par= $vm_par vpos= $v_target_pos"

              switch $style {

                simple_edge_swc {
                  draw cylinder [list $s_ex $s_ey $s_ez]  $v_target_pos radius $cyl_radius resolution $cyl_resolution 
                }
                source_sphere_swc {
                  draw sphere [list $s_ex $s_ey $s_ez]  radius $sph_radius resolution $sph_resolution 
                }
                target_sphere_swc {
                  draw sphere $v_target_pos radius $sph_radius resolution $sph_resolution 
                }
                source_target_sphere_swc {
                  draw sphere [list $s_ex $s_ey $s_ez]  radius $sph_radius resolution $sph_resolution 
                  draw sphere $v_target_pos radius $sph_radius resolution $sph_resolution 
                }
                default {
                  puts "Warning: swc edge style $style not matched"
                }
            } 
          }
        } 


        ^source_morphology   { 
          puts "WARNING: STUB.  NOT IMPLEMENTED YET"
        }

        ^target_morphology   { 
          puts "WARNING: STUB.  NOT IMPLEMENTED YET"
        }
        ^source_target_soma$ { draw sphere [list $target_ex $target_ey $target_ez] radius $sph_radius resolution $sph_resolution 
                             draw sphere [list $target_ex $target_ey $target_ez] radius $sph_radius resolution $sph_resolution 
        }
        ^source_morph_sphere { 
          puts "WARNING: STUB.  NOT IMPLEMENTED YET"
        }

        ^target_morph_sphere {
          puts "WARNING: STUB.  NOT IMPLEMENTED YET"
        }
        ^source_target_morph_sphere {
          puts "WARNING: STUB.  NOT IMPLEMENTED YET"
        }
        ^simple_edge_morph { 
          puts "WARNING: STUB.  NOT IMPLEMENTED YET"
        } 
        default {
                  showError "style $style not recognized for connections (edges).  Style should be one of: simple_edge, source_soma, target_soma, source_target_soma, source_morph_sphere, target_morph_sphere, source_target_morph_sphere"
                  return -1
        }
      }
    } else {
    puts "WARNING: match not found for source and target  source_globalNodeId= $source_globalNodeId  target_globalNodeId= $target_globalNodeId"
    }
  } 
}

proc ::neuro::stack_pop {theStack} {
  upvar 1 $theStack stack
  set res [lindex $stack end] 
  set stack [lreplace $stack end end]
  return $res
}

proc ::neuro::stack_top_obj {theStack} {
  # just have a look at top object (which would be stack  popped)
  upvar 1 $theStack stack
  set res [lindex $stack end] 
  return $res
}

proc ::neuro::sq_push {theStack item} {
  # same for stacks and queues
  upvar 1 $theStack stack
  lappend stack $item 
  return $stack
}

proc ::neuro::queue_pop {theQueue} {
    upvar 1 $theQueue queue
    set res [lindex $queue 0]
    set queue [lreplace $queue 0 0]
    return $res
} 

proc ::neuro::queue_rear_obj {theQueue} {
    #just have a look at rear object of queue (most recently added) 
    upvar 1 $theQueue queue
    set res [lindex $queue end]
    return $res
}
proc ::neuro::queue_front_obj {theQueue} {
    #just have a look at front object (which would be queue popped) 
    upvar 1 $theQueue queue
    set res [lindex $queue 0]
    return $res
}
proc ::neuro::tokenize_sel_string {selString} {
# proceed left to right through selection string.  Any text betwen (, ), and, or, not is selection text, to be passed for individual parsing.  

  set remainString $selString
  set tokenList ""
  while {$remainString != ""} {
    #remove left-most operator, parenthesis, or selection string
    #removes one or two items 
    set theMatch ""; set subMatch1 ""; set subMatch2 ""; set subMatch3 ""; set subMatch4 ""
    #puts "remainString= >$remainString<"

    set regex_result [regexp  [subst -nocommands -nobackslashes {^(\s*)(&&|!|\|\||\(|\)|[^!&\|\(|\)]+)}]  $remainString theMatch subMatch1 subMatch2 subMatch3 subMatch4]
    #puts "regex_result= $regex_result; theMatch= >$theMatch<  subMatch1= >$subMatch1<  subMatch2= >$subMatch2<  subMatch3= >$subMatch3< subMatch4= >$subMatch4<"

    if {($regex_result==0) && ([string length $remainString] > 0)}  {
        puts "Error: malformed selection string: $selString"
        return
    }

    set remainString  [ string range $remainString [string length $theMatch] end ]
    #ignore pure whitespace, this should be needed only for trailing spaces
    if { ! [regexp [subst -nocommands -nobackslashes {^(\s*)$}] $subMatch2]} { 
      lappend tokenList $subMatch2
    }
  }
  foreach e $tokenList {puts "token:>$e<"}
  return $tokenList
}


proc ::neuro::test_list_largeint {size} {
    set mylist ""
    for {set i 0} {$i < $size} {incr i} {
      lappend mylist  [expr int (rand() * 1000000)]
    }
    return $mylist
}

proc ::neuro::test_list_int {size} {
    set mylist ""
    for {set i 0} {$i < $size} {incr i} {
      lappend mylist  [expr int (rand() * 1000)]
    }
    return $mylist
}


proc ::neuro::shunting_yard {select_string} {
  # transform select string into RPN expression of tokens
  # following Dijkstra's "shunting yard" algorithm 
  set opStack ""
  set outputQueue ""
  foreach token [tokenize_sel_string $select_string] {
    #send token to output if not a logical sign or parenthesis
    if {![regexp  [subst -nocommands -nobackslashes {^(\s*)(&&|!|\|\||\(|\))}] $token]} {
      puts "add directly to output: $token"
      sq_push outputQueue $token 
    } elseif {$token eq "("} {
      puts "push parenthesis to op stack"
      sq_push opStack $token
    } elseif {$token eq ")"} {
      puts "popping op stack until left parenthesis"
      while {[stack_top_obj opStack] ne "("} {
        sq_push outputQueue [stack_pop opStack]
        puts "popped [queue_rear_obj outputQueue] to output queue"
      }   
      #discard the left paren, not needed in RPN
      set discardVar [stack_pop opStack]
      puts "found parenthesis, discarded >$discardVar<"
    } else {
      puts "adding operator: $token"
      # currently, with only logic and paren, all precedence is the same, all associativity is the same
      while {[llength $opStack]} {
        set op2 [stack_top_obj opStack]
        if { $op2 ne "("  } {
           #precedence and left/right associativity checks would go here
          puts "..popping operator $op2 to output queue"
          #Since we already know we are about to pop $o2 off the stack, clearer to assign it
          sq_push outputQueue $op2    
          #but we do need to pop $op2 off the stack anyway...
          set discardVar [stack_pop opStack]
        } else {
          break
        } 
      }   
      sq_push opStack $token
    }
    puts "  outputQueue: >$outputQueue<\n  opStack: >$opStack<"
  }
  puts "Now to transfer tokens from stack to output"
  # note {*} tto keep lreverse output as single items, vs. bracketed list
  lappend outputQueue {*}[lreverse $opStack]
  puts "Now to return outputQueue= >$outputQueue<"
  return $outputQueue
}

proc ::neuro::list_invert {listA obj_type} {
  variable globalNodeIdList
  variable globalEdgeIdList

  if {$obj_type eq "edge"} {
    set theObjectList $globalEdgeIdList
  } else {
    set theObjectList $globalNodeIdList
  }
  #invert the list 
  set invert ""
  foreach e $theObjectList {
    if {!($e in $listA)} {
      lappend invert $e 
    }
  }
  return $invert
}


proc ::neuro::list_union {listA listB} {
  return [lsort -unique [lappend listA {*}$listB]]

}
proc ::neuro::list_intersection {listA listB} {
  set intersect ""
  foreach e  $listA {
      if {$e in $listB} {
          lappend intersect $e
      }
  }   
  return $intersect
}

proc ::neuro::parse_full_selection_string {full_selection_string {obj_type node } } {
  
  variable globalNodeIdList
  variable globalEdgeIdList 
  #obj_type edge or node, so that list_negate knows which globals to work with 
  # later, tease out edges or nodes
  #first, transform the selection string into Reverse Polish Notiation (RPN) form   
  set rpn_input_queue [shunting_yard $full_selection_string]
  set rpn_stack ""
  puts "Now to process RPN input queue.  rpn_input_queue is $rpn_input_queue"
  while {[llength $rpn_input_queue]} {
    set e [queue_pop rpn_input_queue] 
    puts "e is >$e<"
    #puts "length of rpn_stack is [llength $rpn_stack]"
    switch -- $e {
      &&  { puts "The && symbol was found. e= >$e<"
            set a [stack_pop rpn_stack]
            set b [stack_pop rpn_stack]
            sq_push rpn_stack [list_intersection $a $b]
          }
      ||  { puts "The || symbol was found. e= >$e<"
            set a [stack_pop rpn_stack]
            set b [stack_pop rpn_stack]
            sq_push rpn_stack [list_union $a $b]
          }
      !   { puts "The ! symbol was found. e= >$e<"
            set a [stack_pop rpn_stack]
            sq_push rpn_stack [list_invert $a $obj_type] 
          }
      (   { puts "ERROR: Search string has unbalanced parenthses."
            return -2
          }
      default { puts "Default:  e= >$e<"
                if {$e eq "-1"} {
                  puts  "Parser error found.  Selection return code: $e";
                 return
                }
                #process as push onto stack, when ops pop off, they will be ready for processing
                if {$obj_type eq "node"} {
                  set result [parse_selection_string $e $globalNodeIdList]
                }  else {
                  set result rpn_stack [parse_selection_string $e $globalEdgeIdList]  
                }
                if {$result == -1} {
                  puts "ERROR: Error found during selection for >$e<. Result error code $result"  
                  return
                } else {
                  sq_push rpn_stack [parse_selection_string $e $globalNodeIdList]
                }
          }
    }
  }
  set outlist [lindex $rpn_stack 0]
  puts "Done with rpn_input_queue. length of rpn_stack is [llength $rpn_stack]. length of outlist is [llength $outlist] " 
  #don't print rpn_stack, in case it is huge list
  return $outlist
}


proc ::neuro::check_symbol_switch {e} {
switch -- $e {
      && { puts "The && symbol was found. e= >$e<"
      }
      || { puts "The || symbol was found. e= >$e<"
      }
      !  { puts "The ! symbol was found. e= >$e<"
      } 
      (  { puts "ERROR: Search string has unbalanced parenthses."
      }
      default {puts "Default:  e= >$e<"
      } 
  }
}

proc ::neuro::cmd_mod_rep_node_fullsel {repIndex style colorMethod material full_selection_string {stride 1} {v1_special_skip False}} {
  # XX special stride parameter is temporary for testing - stride will be a part of proper selection language with boolean and nested-parenthesis  selections
  variable nrepList   
  variable nrepCount
  # number of created nreps. At initVars, set to 0.  Also is the index of the next nrep to be created, so first nrep created has index 0.
  variable display_virtuals_at_creation 
  variable globalNodeIdList
  puts "attempt to modify rep $repIndex: $style $colorMethod $material >$full_selection_string< $stride $v1_special_skip"
  # use nrep for "neuro represenation" so not confused with internal VMD reps.
  # Note that for this implementation, there is one nrep  per molecule.
  #
  set molec [lindex $nrepList $repIndex 2]
  mol top $molec
  graphics $molec delete all

  set oldNrepid [lindex $nrepList $repIndex 0]

  set shown true
  
  # here, draw needed neurons 
  # make selection

  if {$v1_special_skip} {
     #XX hack for showing v1 
     set displayableGlobalNodeIdList [stride_list_skip_special 1 $globalNodeIdList]
  } else {
    set displayableGlobalNodeIdList $globalNodeIdList 
  }

  # Note that parse_selection_string and all the procs it calls take in a list of globalNodeId and output a list of globalNodeId. This could be used for nested / complex selections. 
  set searchAppend " && ( !(model_type == virtual) )"
  set displayed_virtuals_at_creation [lindex $nrepList $repIndex 9]
  if $displayed_virtuals_at_creation { 
    set full_selection_string_virt_check  $full_selection_string
  } else {
    set full_selection_string_virt_check [append combined $full_selection_string $searchAppend] 
  }
  
  #do stride after selection matching
  set myNodeIdList [stride_list $stride [parse_full_selection_string $full_selection_string_virt_check node] ]
  if {$myNodeIdList == -1} {
    return -1
  }
  puts "length of myNodeIdList is [llength $myNodeIdList]"
  #proto_show_nodes_from_list [stride_list 4000 $::skipBadNodeIdList]
  #do cases for styles
  set num_neurons [llength $myNodeIdList]
  set nrepList [lreplace $nrepList $repIndex $repIndex [list $oldNrepid $shown $molec $style $colorMethod $material $full_selection_string $stride $num_neurons $displayed_virtuals_at_creation]]

  switch $style {
    soma {proto_show_nodes_from_list_soma_only $myNodeIdList $colorMethod}
    morphology_draft {proto_show_nodes_from_list $myNodeIdList $colorMethod}
    morphology {proto_show_nodes_from_list_morpho_spheretube $myNodeIdList $colorMethod}
    morphology_line {proto_show_nodes_from_list_morpho_line $myNodeIdList $colorMethod}
    default {showError "style $style not recognized"
        return -1
    } 
  }
  # XX still must add colors and representations
 
  # XX track limits and fit selection in view instead of hardcoded scaling
  #display resetview; display projection Orthographic

  # call existiing procs 
    
  return $oldNrepid
}

proc ::neuro::choose_colorscale_index {scaled_value} {
  #take in value from 0 to 1023, return indexed color number
  variable colorscale_index_offset
  return [expr $scaled_value + $colorscale_index_offset]
}

proc ::neuro::set_indexed_colorscale {$colorscale} {
  variable colorscale_index_offset

  switch $colorscale {
    WhiteToBlack {
    set colorscale(0,$i,r) [expr $i / 255.0]
    set colorscale(0,$i,g) [expr $i / 255.0]
    set colorscale(0,$i,b) [expr $i / 255.0]
 
  }
    BlackToWhite {
    }
    BlueToRed {
    }
    RedToBlue {
    }
    default  showError "unknown color scale"
  }
  return $color_index
}


proc ::neuro::simple_spin {render_method filename_start filename_end framecount } {
  #depends on ::v1_mov_frame for multiple calls of this or other procs from command line
  # For first in a series of frames:
  #     set ::v1_mov_frame 0 
  set inc [expr 360.0/$framecount] 
  for {set f 0} {$f < $framecount} {incr f} {
    set fname "$filename_start.[format %05d $::v1_mov_frame].$filename_end"
    rotate y by $inc
    puts "f= $f; just rotated y by $inc  fname= $fname"
    render $render_method $fname  
    incr ::v1_mov_frame
  }   

}

proc ::neuro::build_node_list {p_list_num mol_id node_material render_method filename_start filename_end framecount} {
  #depends on :: namespace having p_NodeIdList(1) and  p_color(1) for layer 1, similar for layer 2 -7
  #depends on ::v1_mov_frame for multiple calls from command line
  mol top $mol_id
  draw material $node_material
  set colorMethod $::p_color($p_list_num)

  set tot_cells [llength $::p_NodeIdList($p_list_num)]
  for {set f 0} {$f < $framecount} {incr f} {
    draw delete all
    set frac [expr (1.0 + $f ) / ($framecount)]
    set cells_shown [expr int($frac *  $tot_cells)]
    set cell_list [lrange $::p_NodeIdList($p_list_num) 0 [expr $cells_shown -1]]
    set fname "$filename_start.[format %05d $::v1_mov_frame].$filename_end"
    puts "p_list_num= $p_list_num mol_id= $mol_id length cell_list= [llength $cell_list] tot_cells = $tot_cells  f= $f frac= $frac fname= $fname ::v1_mov_frame= $::v1_mov_frame"
    proto_show_nodes_from_list $cell_list $colorMethod
    render $render_method $fname  
    incr ::v1_mov_frame
  }   

} 

proc ::neuro::query_non_standard_node_attribs {} {
  # collect list of unique non-standard node attributes accros file sets
  variable num_filesets
  variable typeAttribList
  set ll ""
  for {set i 0} {$i < $num_filesets} {incr i} {
     foreach e $typeAttribList($i) {
        if { [lsearch -exact $ll $e] == -1} {
          lappend ll $e
        }
    }
  }
  return $ll
}   

proc ::neuro::query_non_standard_node_attribs_by_fileset {} {
  # collect list of unique non-standard node attributes accros file sets
  variable num_filesets
  variable typeAttribList
  set combo_list "" 
  for {set i 0} {$i < $num_filesets} {incr i} {
     lappend combo_list $typeAttribList($i) 
  }
  return $combo_list
}
  


proc ::neuro::query_node_list_attrib_values {attrib_list theGlobalNodeIdList} {
  variable node
  variable typeAttribList
  variable typeHash 
  variable standard_node_attribs_queryable
  variable node_attrib_dictHash
  set non_std_attribs [cmd_query non_standard_node_attribs]
  # add several (not all) of the standard queries
  set all_attribs_queryable [list  {*}$non_std_attribs {*}$standard_node_attribs_queryable] 
  foreach a $attrib_list {
      if {[lsearch -exact $all_attribs_queryable $a] == -1} {
        showError "Node attribute $a not available for value query"
        return -1
      }
  }     
  set combo_list ""
  # check which in attrib_list are in typeAttribList
  foreach theId $theGlobalNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
     set ll ""
     foreach a $attrib_list {
        if {[lsearch $non_std_attribs $a] == -1} {
          switch $a {
            x {  set val $ex} 
            y {  set val $ey} 
            z {  set val $ez} 
            xrot {  set val $exrot} 
            yrot {  set val $eyrot} 
            zrot {  set val $ezrot} 
            type {set val $etype} 
            fileset {set val $efileset_num}
            population {set val $epop}
            node {set val $enode_id}
            node_id {set val $enode_id}
            group {set val $egroup_id}
            model_type {set val $typeHash(model_type,$efileset_num,$etype)}
            cartesian {set val $ecartesian}
            group {set val $egroup_id}

            default {showError "Attribute $a not found for global node ID $theId."; return -1}   
          }
        } else {
          # check if in attrib list for this fileset
          #could be either per-type or per-node (typeAttribList does not discriminate)
          if {[lsearch $typeAttribList($efileset_num) $a] == -1} {
            #case when not at all set per-node or per-type
            set val {} 
          } else {
            #XX Here, for testing, VND_NULL indicates an error
            set val {}
            if {[info exists typeHash($a,$efileset_num,$etype)]} {
              set val $typeHash($a,$efileset_num,$etype)    
            } 
            # over-ride 
            if {[info exists node_attrib_dictHash($theId)] && [dict exists $node_attrib_dictHash($theId) $a]} {
              set val [dict get  $node_attrib_dictHash($theId) $a]
            }
            #error "attrib= $a  theId= $theId, val= $val etype= $etype   pausing"
          }
        }
        lappend ll $val
     } 
     lappend combo_list $ll
  }
  return $combo_list
}


proc ::neuro::read_draw_coord_pair_file {the_filename} {
  #read in each line as a pair of spheres and radii, with a single color for the whole line;
  #draw a spheretube (single segment) for each line
  # x_1 y_1 z_1 r_1 x_2 y_2 z_2 r_2 color

  set the_file [open $the_filename r]
      # XXX change so works for something that is not last line in file
      while { [gets $the_file myline] >=0} {
        set vec [split $myline]
        foreach  {x_1 y_1 z_1 r_1 x_2 y_2 z_2 r_2 seg_color parent_is_soma child_is_soma} $vec {}
        #puts "x_1=$x_1 y_1=$y_1 z_1=$z_1 r_1=$r_1 x_2=$x_2 y_2=$y_2 z_2=$z_2 r_2=$r_2 seg_color=$seg_color"
        draw color $seg_color  
        draw spheretube [list [list $x_1 $y_1 $z_1] [list $x_2 $y_2 $z_2]] radii [list $r_1 $r_2] drawtubes 1
      }
  close $the_file
}

proc ::neuro::sort_uniq_mixed_list {theList} {
  # takes in a list of mixed reals and non-reals
  # outputs one list of: sorted numbers, then sorted non-numbers
  # nan is sorted as a non-number 
  set real_list [list]
  set char_list [list]
  foreach e $theList {
    if {[string is double -strict $e] && ![string equal -nocase "nan" $e]} {
      lappend real_list $e
    } else {
      lappend char_list $e
    }    
  }
  set real_list_sorted [lsort -unique -real $real_list] 
  set char_list_sorted [lsort -unique -ascii $char_list] 
  return [lappend real_list_sorted {*}$char_list_sorted]
}


proc ::neuro::query_morpho_details_no_coords {subsetNodeIdList} {
  # For n defined nodes, return a list of n lists, each element containing: globalNodeId, x, y, z , x_rot, y_rot, z_rot (w/ special correction), length_of_the_pointList  
  variable node
  variable typeHash
  set n 0
  set ll ""
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    set type_zrot 0
    #special corrective used for v1 z axis
    catch {set type_zrot $typeHash(rot_zaxis,$efileset_num,$etype)}
    puts "theId= $theId list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian, type_zrot= $type_zrot"

       #if {$ecartesian} 
        #only report if this node has Cartesian coordinates for soma
      
    set pointList [proto_retrieve_morphology $efileset_num $etype ]

    # note ($ezrot + $type_zrot)  
    set morph_details [list $theId [list $ex $ey $ez] [list $exrot $eyrot [expr $ezrot + $type_zrot] ] [llength $pointList] ]
    lappend ll $morph_details
    incr n
  }
  return $ll
}

proc ::neuro::query_morpho_details_original_pos {subsetNodeIdList} {
  # For n defined nodes, return a list of n lists, each element containing: globalNodeId, x, y, z , x_rot, y_rot, z_rot (w/ special correction), pointList (original position)
  variable node
  variable typeHash
  set n 0
  set ll ""
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    
    set type_zrot 0
    #special corrective used for v1 z axis
    catch {set type_zrot $typeHash(rot_zaxis,$efileset_num,$etype)}
    puts "theId= $theId list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian, type_zrot= $type_zrot"

       #if {$ecartesian} 
        #only report if this node has Cartesian coordinates for soma
      
    set isolated_pointList [proto_calc_morph_original_pos_isolated_points  $etype $efileset_num ]

    # note ($ezrot + $type_zrot)  
    set morph_details [list $theId [list $ex $ey $ez] [list $exrot $eyrot [expr $ezrot + $type_zrot] ] $isolated_pointList ]
    lappend ll $morph_details
    incr n
  }
  return $ll
}
proc ::neuro::query_morpho_details_moved {subsetNodeIdList} {
  # For n defined nodes, return a list of n lists, each element containing: globalNodeId, x, y, z , x_rot, y_rot, z_rot (w/ special correction), pointList (moved (translated, rotated)
  variable node
  variable typeHash
  set n 0
  set ll ""
  foreach theId $subsetNodeIdList {
    foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $node($theId) {}
    
    set type_zrot 0
    #special corrective used for v1 z axis
    catch {set type_zrot $typeHash(rot_zaxis,$efileset_num,$etype)}
    puts "theId= $theId list elem: $n  line: ex= $ex  ey= $ey  ez= $ez  exrot= $exrot  eyrot= $eyrot  ezrot= $ezrot  etype= $etype  efileset_num= $efileset_num  epop= $epop  enode_id= $enode_id  egroup_id= $egroup_id  egroup_index= $egroup_index ecartesian= $ecartesian, type_zrot= $type_zrot"

       #if {$ecartesian} 
        #only report if this node has Cartesian coordinates for soma
      

    # note ($ezrot + $type_zrot) 
    # XX Note ezrot alone sent, the type_zrot addition is done within proto_calc_morph_moved_isolated_points 
    set isolated_pointList [proto_calc_morph_moved_isolated_points $etype $efileset_num $ex $ey $ez $exrot $eyrot $ezrot ]
    puts "morph_moved: llength isolated_pointList is [llength $isolated_pointList]"
    # note ($ezrot + $type_zrot)  
    # XX note the addition for type_zrot. Reporting what happens in proto_calc_morph_moved_isolated_points.  When switch zrot handling from addition to override-able, change this  
    set morph_details [list $theId [list $ex $ey $ez] [list $exrot $eyrot [expr $ezrot + $type_zrot] ] $isolated_pointList ]
    lappend ll $morph_details
    incr n
  }
  return $ll
}
