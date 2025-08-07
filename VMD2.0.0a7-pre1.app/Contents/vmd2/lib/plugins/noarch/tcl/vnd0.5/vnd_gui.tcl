##
## VND -- Visual Neuronal Dynamics graphical interface
##
## $Id: vnd_gui.tcl,v 1.29 2024/05/29 14:21:13 jasonks2 Exp $
##
##
## Home Page
## ---------
##   http://www.ks.uiuc.edu/Research/vnd/
##
##

package require Tk
package require tablelist


package provide vnd 0.5

source [file join $env(VNDPLUGINDIR) vnd_read.tcl]
source [file join $env(VNDPLUGINDIR) orient.tcl]

namespace eval ::NeuronVND:: {

    proc initialize {} {

        ::neuro::initVars

        global env
        variable modellist 0
        variable modelselected ""
        variable repselected 0
        variable selRep ""
        variable styleRep ""
        variable materialRep Opaque
        variable colorRep Type
        variable colorID ""
        variable numberRep
        variable showRep true
        variable sphereScale 3
        variable sphereRes 5
        variable proxyantialias ""
        variable proxydepthcueing ""
        variable proxyfps ""
        variable proxylight0 on 
        variable proxylight1 off 
        variable proxylight2 off 
        variable proxylight3 off
        # variables for render
        variable renderMethod snapshot
        variable renderImgFile "vmdscene"
        variable renderMovFile "untitled.mp4" 
        variable renderVideoProc "ffmpeg"
        variable renderWorkDir "/usr/tmp" 
        variable renderMovDuration 10
        variable renderMovTimeFrom 1
        variable renderMovTimeTo 10
        variable movieAbort 0
        variable movieProgressVar 0
        # other
        variable objList ""
        variable objIndex ""
        variable colorObj white
        variable historyCalls ""
        variable mouseMode rotate
        variable objMouse 0
        # variables for object management
        variable movex 10
        variable movey 10
        variable movez 10
        variable aggoffset {0 0 0}
        variable rotarx 10
        variable rotary 10
        variable rotarz 10
        variable aggrot [transidentity]
        # testing toplevel
        variable topGui ".neuron"
        variable bindTop 0
        # auxiliary variable for example rep checkbutton
        variable exampleRep 0
        variable exampleRepID -1
        # variable to use in connectivity GUI
        variable listOfRepsForConnect ""
        variable edgesStyle "simple_edge"
        variable edgesColor Type
        variable edgesMaterial Opaque
        variable edgesScale 4  ;# for the spheres of the edges rep
        variable edgesScale2 1.0 ;# for the actual edges
        variable selSource ""
        variable selTarget ""
        # hack variable to fix issues with edge reps
        variable nrepListNotEdges
        # variables to use in activity GUI
        variable listOfPopsForSpikes ""
        variable spikePop1 ""
        variable spikePop2 ""
        variable spikeSel1 ""
        variable spikeSel2 ""
        variable spikeStart 1
        variable spikeEnd 1 
        catch {variable spikeTime 1}
        variable spikeWindowSize 1
        variable spikeTimeStride 1
        variable spikeWaitTime 20
        variable spikeMyNodeIdList1 ""
        variable spikeMyNodeIdList2 ""
        variable spikeColor1 white
        variable spikeMaterial1 Opaque
        variable spikeStyle1 soma
        variable spikeScale1 4
        variable spikeRes1 6
        variable spikeColor2 white
        variable spikeMaterial2 Opaque
        variable spikeStyle2 soma
        variable spikeScale2 4
        variable spikeRes2 6
        variable spikeMolidForGraphics1 ""
        variable spikeMolidForGraphics2 ""
        variable spikeAbort ""
        variable spikeAnimationType Once
        variable spikePlothandle ""
        # variables for compartment data GUI
        variable compartPop ""
        variable compartSel "all"
        variable compartStart 1
        variable compartEnd 3000 
        catch {variable compartTime 1}
        variable compartWindowSize 1
        variable compartTimeStride 1
        variable compartWaitTime 20
        variable compartMyNodeIdList ""
        variable compartColor BlueToRed
        variable compartMaterial Opaque
        variable compartStyle spheretube
        variable compartAbort ""
        variable compartAnimationType Once
        variable compartRepId ""
        variable compartMolId ""
        variable compartRangeMin "-82.16"
        variable compartRangeMax "-60.00"
        # symbols
        variable downPoint \u25BC
        variable rightPoint \u25B6
        # status / progress bar
        variable statusLabel "Ready"
        variable statusPbarVal 0
        # update hot keys
        user add key r {mouse mode rotate; set ::NeuronVND::mouseMode rotate}
        user add key t {mouse mode translate; set ::NeuronVND::mouseMode translate}
        user add key s {mouse mode scale; set ::NeuronVND::mouseMode scale}
        #########################
        # prototype to work with multiple models
        variable listmodels
        set listmodels(-1) ""
        set listmodels(0,name) ""
        variable indexmodel 0
        #attributes_browser
        variable indexmodel 0
        variable output_list
        variable noutput_list
        variable nonstandard_list
        variable combined


        #variables for alignment tool
        variable princ_moved_mol -1
        variable princ_axes "" 
        variable princ_axes_scale -1
        variable princ_axes_com ""
	variable princ_axes_spherelist ""
        variable xin ""
        variable yin ""
        variable zin ""

            #alignment tool
        variable aligned_on
        variable axis_on
        variable tool_state
        variable alignment_mol
        variable principal_axis_mol
        variable alignment_axis_mol
        variable box_mol
        variable x_array
        variable y_array
        variable z_array
        variable size_array
        variable unaligned_old
        variable aligned_new
        #----
        variable alignment_population
        variable alignment_populationID
        #--- gui
        variable w
        #--- for new query
        variable output 
        variable output_header

        #this will be a list
        variable globalNodeID
        variable nsize  


    }
    initialize
}


proc ::NeuronVND::resizeGUI {w} {
  # taken from fftk
  update idletasks
  regexp {([0-9]+)x[0-9]+[\+\-]+[0-9]+[\+\-]+[0-9]+} [wm geometry $w] all dimW
  set dimH [winfo reqheight $w]
  #set dimH [expr {$dimH + 10}]
  set dimW [winfo reqwidth $w]
  #set dimW [expr {$dimW + 5}]
  wm geometry $w [format "%ix%i" $dimW $dimH]
  update idletasks

}

proc ::NeuronVND::neuronRep { } {
    variable repselected
    variable selRep
    variable styleRep
    variable materialRep
    variable colorRep
    variable colorID
    variable sphereScale
    variable sphereRes

    set w .neuron.fp.systems.rep
    #wm title $w "Representations"
    #wm resizable $w 1 1
    #set width 288 ;# in pixels
    #set height 160 ;# in pixels
    #wm geometry $w ${width}x${height}+797+747   
    grid columnconfigure $w 0 -weight 1

    grid [labelframe $w.main -text "Representations" -labelanchor n] -row 0 -column 0 -sticky news
    grid columnconfigure $w.main 0 -weight 1
    #grid [ttk::combobox $w.main.modelsel.inp -width 37 -background white -values $::NeuronVND::modellist -state readonly -justify left -textvariable ::NeuronVND::modelselected] -row 0 -column 1 -sticky ew -padx 1
    #bind $w.main.modelsel.inp <<ComboboxSelected>> {set text [%W get]; %W selection clear}

    grid [frame $w.main.rep] -row 1 -column 0 -sticky news -padx 2 -pady 2
    grid [button $w.main.rep.add -text "Create Rep" -command {::NeuronVND::createRepArgs}] -row 0 -column 0 -sticky n;#ews
    grid [button $w.main.rep.show -text "Show / Hide" -command {::NeuronVND::showHideRep}] -row 0 -column 1 -sticky n;#ews
    grid [button $w.main.rep.del -text "Delete Rep" -command {::NeuronVND::delRep}] -row 0 -column 2 -sticky n;#e
    #grid columnconfigure $w.main.rep 2 -weight 1

    grid [frame $w.main.table] -row 2 -column 0 -sticky news -padx 4 -pady 2
    grid columnconfigure $w.main.table 0 -weight 1
    grid [tablelist::tablelist $w.main.table.tb -columns {
        0 "Style" 
        0 "Color"
        0 "Neurons"
        0 "Selection"
        } \
        -yscrollcommand [list $w.main.table.scr1 set] \
        -stretch all -background white -stretch 2 -height 6 -width 100 -exportselection false]
    
    ##Scroll_BAr V
    grid [scrollbar $w.main.table.scr1 -orient vertical -command [list $w.main.table.tb yview]] -row 0 -column 1  -sticky ens

    $w.main.table.tb columnconfigure 0 -width 10
    #$w.main.table.tb columnconfigure 2 -width 15
    #$w.main.table.tb columnconfigure 0 -width 0 -editable true -editwindow ttk::checkbutton

    bind $w.main.table.tb <<TablelistSelect>>  {
      set ::NeuronVND::repselected [%W curselection]  
      ::NeuronVND::updateRepMenu
    }

    grid [labelframe $w.main.sel -text "Selected Neurons" -labelanchor n -borderwidth 0] -row 3 -column 0 -sticky news -padx 0 -pady 2
    grid [entry $w.main.sel.entry -textvariable ::NeuronVND::selRep -width 100] -row 0 -column 0 -sticky news -padx 0
    bind $w.main.sel.entry <Return> {
      ::NeuronVND::editRep sel
      return
    }

    grid [frame $w.main.def] -row 4 -column 0 -sticky news -padx 1 -pady 1
    
    grid [ttk::notebook $w.main.def.nb -style new.TNotebook -width 640] -row 0 -column 0 -sticky nsew -pady 2 -padx 1
    frame $w.main.def.nb.page1
    frame $w.main.def.nb.page2

    $w.main.def.nb add $w.main.def.nb.page1 -text "Drawing" -padding 2 -sticky news
    $w.main.def.nb add $w.main.def.nb.page2 -text "Keywords" -padding 2 -sticky news

    grid [label $w.main.def.nb.page1.colorlbl -text "Coloring Method" -anchor c] -row 0 -column 0
    grid [ttk::combobox $w.main.def.nb.page1.colorcb -width 15 -values {"Type" "Color"} -textvariable ::NeuronVND::colorRep -state readonly] -row 1 -column 0
    # button option for color not being used
    button $w.main.def.nb.page1.colorid -background white -width 1 -command {
      set auxcolor [tk_chooseColor -initialcolor $::NeuronVND::colorID -title "Choose color"]
      if {$auxcolor != ""} {
          set ::NeuronVND::colorID $auxcolor
          .neuron.fp.systems.rep.main.def.nb.page1.colorid configure -background $auxcolor}
    }

    grid [label $w.main.def.nb.page1.coloridlb -width 9] -row 1 -column 1 -sticky news
    ttk::combobox $w.main.def.nb.page1.coloridcb -width 7 -values [colorinfo colors] -textvariable ::NeuronVND::colorID -state readonly

    bind $w.main.def.nb.page1.colorcb <<ComboboxSelected>> {
        set text [%W get]
        switch $text {
            "Color" {
                grid .neuron.fp.systems.rep.main.def.nb.page1.coloridcb -row 1 -column 1 -sticky news
            }
            "default" {
                grid remove .neuron.fp.systems.rep.main.def.nb.page1.coloridcb
                set ::NeuronVND::colorID Type
                ::NeuronVND::editRep color
            }
        }
        #::NeuronVND::editRep color
        %W selection clear
    }

    bind $w.main.def.nb.page1.coloridcb <<ComboboxSelected>> {
        set text [%W get]
        ::NeuronVND::editRep color
        %W selection clear
    }    
    
    
    grid [label $w.main.def.nb.page1.matlbl -text "Material" -width 10 -anchor c] -row 0 -column 3
    set materiallist {"Opaque" "Transparent" "BrushedMetal" "Diffuse" "Ghost" "Glass1" "Glass2" "Glass3" "Glossy" "HardPlastic" "MetallicPastel" "Steel" \
        "Translucent" "Edgy" "EdgyShiny" "EdgyGlass" "Goodsell" "AOShiny" "AOChalky" "AOEdgy" "BlownGlass" "GlassBubble" "RTChrome"}
    grid [ttk::combobox $w.main.def.nb.page1.matcb -width 15 -values $materiallist -textvariable ::NeuronVND::materialRep -state readonly] -row 1 -column 3
    bind $w.main.def.nb.page1.matcb <<ComboboxSelected>> {
        set text [%W get]
        ::NeuronVND::editRep material
        %W selection clear
    }

    grid [label $w.main.def.nb.page1.stylbl -text "Style"] -row 2 -column 0
    grid [ttk::combobox $w.main.def.nb.page1.stycb -width 15 -values {"soma" "morphology" "morphology_draft" "morphology_line"} -textvariable ::NeuronVND::styleRep -state readonly] -row 3 -column 0
    bind $w.main.def.nb.page1.stycb <<ComboboxSelected>> {
        set text [%W get]
        switch $text {
            "soma" {
                #.neuron.fp.systems.rep.main.arg.en1 configure -state normal
                #.neuron.fp.systems.rep.main.arg.en2 configure -state normal
            }
            "morphology" {
                #.neuron.fp.systems.rep.main.arg.en1 configure -state disabled
                #.neuron.fp.systems.rep.main.arg.en2 configure -state disabled
            }
        }
        ::NeuronVND::editRep style
        %W selection clear
    }
    #Set tables up page2 of notebook
    grid [labelframe $w.main.def.nb.page2.kw -text "Attributes" -labelanchor n] -row 0 -column 0 -sticky news
    grid [tablelist::tablelist $w.main.def.nb.page2.kw.kwtable1 -columns {
	0 ""
         } \
        -yscrollcommand [list $w.main.def.nb.page2.kw.kwscr1 set] \
        -stretch all -stretch all -height 7 -width 22 -exportselection false]
    grid [scrollbar $w.main.def.nb.page2.kw.kwscr1 -orient vertical -command [list $w.main.def.nb.page2.kw.kwtable1 yview]] -row 0 -column 1 -sticky ens
     
    #Values
    grid [labelframe $w.main.def.nb.page2.values -text "Values" -labelanchor n] -row 0 -column 1 -sticky news
    grid [tablelist::tablelist $w.main.def.nb.page2.values.vtable1 -columns {
	0 ""
	} \
        -yscrollcommand [list $w.main.def.nb.page2.values.vscr1 set] \
        -stretch all -stretch all -height 7 -width 22 -exportselection false]
    grid [scrollbar $w.main.def.nb.page2.values.vscr1 -orient vertical -command [list $w.main.def.nb.page2.values.vtable1 yview]] -row 0 -column 1  -sticky ens   
    
    #Min/Max
    grid [labelframe $w.main.def.nb.page2.min_max -text "Min/Max" -labelanchor n] -row 0 -column 4 -sticky news
    grid [tablelist::tablelist $w.main.def.nb.page2.min_max.min_max_table -columns {
	            0 ""
	                } \
                    -stretch all -stretch all -height 7 -width 12 -exportselection false]
    grid [frame $w.main.arg] -row 5 -column 0 -sticky e -padx 2 -pady 2

    #grid [label $w.main.arg.lb1 -text "Sphere Scale" -anchor e] -row 0 -column 0 -sticky news
    #grid [spinbox $w.main.arg.en1 -width 3 -increment 1 -from 1 -to 10 -textvariable ::NeuronVND::sphereScale -background white -command {::NeuronVND::editRep sphere}]  -row 0 -column 1 -padx 2 -sticky w
    #grid [entry $w.main.arg.en1 -text "5" -width 5] -row 0 -column 1 -sticky news
    #grid [label $w.main.arg.lb2 -text "Sphere Resolution"] -row 1 -column 0 -sticky news
    #grid [spinbox $w.main.arg.en2 -width 3 -increment 5 -from 5 -to 30 -textvariable ::NeuronVND::sphereRes -background white -command {::NeuronVND::editRep sphere}]  -row 1 -column 1 -padx 2 -sticky w

    #NeuronVND::resizeGUI $w

}

proc ::NeuronVND::createPages { orientation } {
    variable listmodels
    set w .neuron
    if {[winfo exists .neuron.fp]} { destroy .neuron.fp }
    ttk::style configure new.TNotebook -tabposition $orientation
    ttk::style configure new.TNotebook.Tab -width 12
    ttk::style configure new.TNotebook.Tab -anchor center
    #font create customfont2 -size 100 -weight bold
    ttk::style configure New.TNotebook.Tab -font customfont2
    grid [ttk::notebook $w.fp -style new.TNotebook -width 420] -row 1 -column 0 -sticky nsew -pady 2 -padx 2
    grid columnconfigure $w.fp 0 -weight 1
    grid rowconfigure $w.fp 0 -weight 1

    frame $w.fp.systems
    #frame $w.fp.systems.rep
    frame $w.fp.navigation

    set fontarg "helvetica 20 bold"

    if {$orientation == "wn"} {
        set text1 "\nMain\n"
        set text2 "\nGraphics\n"
        set text3 "\nNavigation\n"
        set width 350
        set height 300
    } else {
        set text1 "Main"
        set text2 "Graphics"
        set text3 "Navigation"
        set width 650
        set height 385
    }

    $w.fp add $w.fp.systems -text $text1 -padding 2 -sticky news
    #$w.fp add $w.fp.systems.rep -text $text2 -padding 2 -sticky news
    $w.fp add $w.fp.navigation -text $text3 -padding 2 -sticky news

    grid [labelframe $w.fp.systems.main -text "Systems" -labelanchor n] -row 0 -column 0 -sticky news
    grid [tablelist::tablelist $w.fp.systems.main.tb -columns {
        0 "ID" 
        0 "T"
        0 "D"
        0 "Name"
        0 "Neurons"
        } \
        -yscrollcommand [list $w.fp.systems.main.scr1 set] \
        -stretch all -background white -stretch all -height 4 -width 40 -exportselection false]  

    ##Scroll_BAr V
    grid [scrollbar $w.fp.systems.main.scr1 -orient vertical -command [list $w.fp.systems.main.tb yview]] -row 0 -column 1  -sticky ens

    #$w.main.tb insert end [list "0" "T" "D" "V1" [::neuro::cmd_query num_neurons] ""]

    #$w.main.tb insert end [list "0" "T" "D" "event30K" "30.000" "100"]
    #$w.main.tb insert end [list "1" "" "D" "test500K" "500.000" "0"]

    # Testing add dropside menu
    # First add thin vertical button to increase window with
    grid [label $w.fp.systems.sidebutton1 -text "<" -width 1] -row 0 -rowspan 2 -column 1 -sticky ens
    label $w.fp.systems.sidebutton2 -text ">" -width 1

    # set mouse click bindings to expand/contract window
    bind $w.fp.systems.sidebutton1 <Button-1> {
        grid remove .neuron.fp.systems.sidebutton1
        grid .neuron.fp.systems.sidebutton2 -row 0 -rowspan 2 -column 1 -sticky ens
        # resize to hide representations
        wm geometry .neuron 322x385
    }

    bind $w.fp.systems.sidebutton2 <Button-1> {
        grid remove .neuron.fp.systems.sidebutton2
        grid .neuron.fp.systems.sidebutton1
        # resize to show representations
        wm geometry .neuron 650x385
    }

    # frame for representations
    grid [frame $w.fp.systems.rep] -row 0 -rowspan 2 -column 2 -sticky news
    grid columnconfigure $w.fp.systems 2 -weight 1

    # Add info frame
    grid [labelframe $w.fp.systems.info -text "Information" -labelanchor n] -row 1 -column 0 -sticky news
    set rowid 0
    grid [label $w.fp.systems.info.header1 -text "Tree view"] -row $rowid -column 1 -sticky news -padx 1
    #grid [label $w.fp.systems.info.header2 -text "Query"] -row $rowid -column 2 -sticky news -padx 1
    incr rowid
if {0} {
    grid [tablelist::tablelist $w.fp.systems.info.tb2 -columns {
        0 "Results" 
        } \
        -yscrollcommand [list $w.fp.systems.info.scr2 set] \
        -stretch all -background white -stretch all -height 9 -width 12 -showlabels 0] -row $rowid -column 2 -padx 1

    ##Scroll_BAr V
    grid [scrollbar $w.fp.systems.info.scr2 -orient vertical -command [list $w.fp.systems.info.tb2 yview]] -row $rowid -column 3  -sticky ens -padx 1
}  

    # Testing treeview
    grid [ttk::treeview $w.fp.systems.info.tv -show tree -height 6 -yscrollcommand [list $w.fp.systems.info.scr1 set]] -row $rowid -column 1 -padx 1
    ##Scroll_BAr V
    grid [scrollbar $w.fp.systems.info.scr1 -orient vertical -command [list $w.fp.systems.info.tv yview]] -row $rowid -column 0  -sticky wens -padx 1

    set tv $w.fp.systems.info.tv
    #$tv heading #0 -text "Model"
    $tv column #0 -width 200

    incr rowid
    grid [button $w.fp.systems.info.button1 -text "Create Rep" -command {
        if {[.neuron.fp.systems.info.tv selection] != ""} {::NeuronVND::createExampleRep [.neuron.fp.systems.info.tv selection]}
    }] -row $rowid -column 1 -sticky w

    # double click action
    bind $w.fp.systems.info.tv <Double-1> {
        set sel [.neuron.fp.systems.info.tv selection]
        .neuron.fp.systems.rep.main.sel.entry insert "insert" "$sel "
    }

    # auto rep creation replaced by button
    if {0} {  
    bind $w.fp.systems.info.tv <<TreeviewSelect>> {
        set sel [.neuron.fp.systems.info.tv selection]
        if {$::NeuronVND::exampleRep} {
            ::NeuronVND::createExampleRep $sel
        }
    }
    }

    #$tv configure -columns "results"
    #$tv heading results -text "Results"
    #$tv column results -width 125

    if {$listmodels(0,name) != ""} {
    .neuron.fp.systems.main.tb insert end [list "0" "T" "D" $listmodels(0,name) $listmodels(0,neurons)]
    }

    grid [frame $w.fp.navigation.main] -row 0 -column 0 -sticky news
       
    grid [labelframe $w.fp.navigation.main.mmode -text "Mouse Mode" -labelanchor n -width 20] -row 0 -column 0 -sticky news
    grid [radiobutton $w.fp.navigation.main.mmode.rot -text "Rotate (R)" -variable ::NeuronVND::mouseMode -value rotate -command {mouse mode rotate}] -row 0 -column 0 -sticky nws
    grid [radiobutton $w.fp.navigation.main.mmode.trans -text "Translate (T)" -variable ::NeuronVND::mouseMode -value translate -command {mouse mode translate}] -row 1 -column 0 -sticky nws
    grid [radiobutton $w.fp.navigation.main.mmode.scale -text "Scale (S)" -variable ::NeuronVND::mouseMode -value scale -command {mouse mode scale}] -row 2 -column 0 -sticky nws

    grid [labelframe $w.fp.navigation.main.obj -text "Object Management" -labelanchor n] -row 0 -column 1 -sticky nes
    grid [label $w.fp.navigation.main.obj.sel -text "Select:"] -row 0 -column 0 -sticky news
    grid [ttk::combobox $w.fp.navigation.main.obj.cb -width 30 -values "" -textvariable ::NeuronVND::objIndex -state readonly] -row 0 -column 1 -columnspan 4
    bind $w.fp.navigation.main.obj.cb <<ComboboxSelected>> {
        set ::NeuronVND::objIndex [%W get]
        mol top [lindex $::NeuronVND::objIndex 0]
        %W selection clear
    }
    grid [radiobutton $w.fp.navigation.main.obj.move -text "Use Mouse Mode to arrange object" -variable ::NeuronVND::objMouse -value 1 -command {
        # need to fix all except for objid
        foreach m [molinfo list] {mol fix $m}
        mol free [lindex $::NeuronVND::objList 0 0]
    }] -row 1 -column 0 -sticky nws -columnspan 5
    grid [radiobutton $w.fp.navigation.main.obj.move2 -text "Use buttons to arrange object" -variable ::NeuronVND::objMouse -value 0 -command {
        foreach m [molinfo list] {mol free $m}    
    }] -row 2 -column 0 -columnspan 5 -sticky nws
    grid [label $w.fp.navigation.main.obj.movex -text "Translate in X:"] -row 3 -column 0 -sticky news
    grid [button $w.fp.navigation.main.obj.movex1 -text "-" -command {::NeuronVND::moveGraphs x neg}] -row 3 -column 1 -sticky news
    #grid [button $w.fp.navigation.main.obj.movex2 -text "-" -command {::NeuronVND::moveGraphs x -100}] -row 3 -column 2 -sticky news
    grid [spinbox $w.fp.navigation.main.obj.movex2 -width 3 -increment 10 -from 10 -to 1000 -textvariable ::NeuronVND::movex -background white]  -row 3 -column 2 -sticky news
    grid [button $w.fp.navigation.main.obj.movex3 -text "+" -command {::NeuronVND::moveGraphs x pos}] -row 3 -column 3 -sticky news
    #grid [button $w.fp.navigation.main.obj.movex4 -text "+++" -command {::NeuronVND::moveGraphs x 500}] -row 3 -column 4 -sticky news
    grid [label $w.fp.navigation.main.obj.movey -text "Translate in Y:"] -row 4 -column 0 -sticky news
    grid [button $w.fp.navigation.main.obj.movey1 -text "-" -command {::NeuronVND::moveGraphs y neg}] -row 4 -column 1 -sticky news
    #grid [button $w.fp.navigation.main.obj.movey2 -text "-" -command {::NeuronVND::moveGraphs y -100}] -row 4 -column 2 -sticky news
    grid [spinbox $w.fp.navigation.main.obj.movey2 -width 3 -increment 10 -from 10 -to 1000 -textvariable ::NeuronVND::movey -background white]  -row 4 -column 2 -sticky news
    grid [button $w.fp.navigation.main.obj.movey3 -text "+" -command {::NeuronVND::moveGraphs y pos}] -row 4 -column 3 -sticky news
    #grid [button $w.fp.navigation.main.obj.movey4 -text "+++" -command {::NeuronVND::moveGraphs y 500}] -row 4 -column 4 -sticky news
    grid [label $w.fp.navigation.main.obj.movez -text "Translate in Z:"] -row 5 -column 0 -sticky news
    grid [button $w.fp.navigation.main.obj.movez1 -text "-" -command {::NeuronVND::moveGraphs z neg}] -row 5 -column 1 -sticky news
    #grid [button $w.fp.navigation.main.obj.movez2 -text "-" -command {::NeuronVND::moveGraphs z -100}] -row 5 -column 2 -sticky news
    grid [spinbox $w.fp.navigation.main.obj.movez2 -width 3 -increment 10 -from 10 -to 1000 -textvariable ::NeuronVND::movez -background white]  -row 5 -column 2 -sticky news
    grid [button $w.fp.navigation.main.obj.movez3 -text "+" -command {::NeuronVND::moveGraphs z pos}] -row 5 -column 3 -sticky news
    #grid [button $w.fp.navigation.main.obj.movez4 -text "+++" -command {::NeuronVND::moveGraphs z 500}] -row 5 -column 4 -sticky news
    
    grid [ttk::separator $w.fp.navigation.main.obj.sep1] -row 6 -column 0 -sticky news -columnspan 5 -pady 2 -padx 2
    set row 7
    grid [label $w.fp.navigation.main.obj.rotx -text "Rotate around X:"] -row $row -column 0 -sticky news
    grid [button $w.fp.navigation.main.obj.rotx1 -text "-" -command {::NeuronVND::rotGraphs x neg}] -row $row -column 1 -sticky news
    #grid [button $w.fp.navigation.main.obj.rotx2 -text "-" -command {::NeuronVND::rotGraphs x -15}] -row $row -column 2 -sticky news
    grid [spinbox $w.fp.navigation.main.obj.rotx2 -width 3 -increment 5 -from 5 -to 180 -textvariable ::NeuronVND::rotarx -background white]  -row $row -column 2 -sticky news
    grid [button $w.fp.navigation.main.obj.rotx3 -text "+" -command {::NeuronVND::rotGraphs x pos}] -row $row -column 3 -sticky news
    #grid [button $w.fp.navigation.main.obj.rotx4 -text "+++" -command {::NeuronVND::rotGraphs x 45}] -row $row -column 4 -sticky news
    incr row
    grid [label $w.fp.navigation.main.obj.roty -text "Rotate around Y:"] -row $row -column 0 -sticky news
    grid [button $w.fp.navigation.main.obj.roty1 -text "-" -command {::NeuronVND::rotGraphs y neg}] -row $row -column 1 -sticky news
    #grid [button $w.fp.navigation.main.obj.roty2 -text "-" -command {::NeuronVND::rotGraphs y -15}] -row $row -column 2 -sticky news
    grid [spinbox $w.fp.navigation.main.obj.roty2 -width 3 -increment 5 -from 5 -to 180 -textvariable ::NeuronVND::rotary -background white]  -row $row -column 2 -sticky news
    grid [button $w.fp.navigation.main.obj.roty3 -text "+" -command {::NeuronVND::rotGraphs y pos}] -row $row -column 3 -sticky news
    #grid [button $w.fp.navigation.main.obj.roty4 -text "+++" -command {::NeuronVND::rotGraphs y 45}] -row $row -column 4 -sticky news
    incr row
    grid [label $w.fp.navigation.main.obj.rotz -text "Rotate around Z:"] -row $row -column 0 -sticky news
    grid [button $w.fp.navigation.main.obj.rotz1 -text "-" -command {::NeuronVND::rotGraphs z neg}] -row $row -column 1 -sticky news
    #grid [button $w.fp.navigation.main.obj.rotz2 -text "-" -command {::NeuronVND::rotGraphs z -15}] -row $row -column 2 -sticky news
    grid [spinbox $w.fp.navigation.main.obj.rotz2 -width 3 -increment 5 -from 5 -to 180 -textvariable ::NeuronVND::rotarz -background white]  -row $row -column 2 -sticky news
    grid [button $w.fp.navigation.main.obj.rotz3 -text "+" -command {::NeuronVND::rotGraphs z pos}] -row $row -column 3 -sticky news
    #grid [button $w.fp.navigation.main.obj.rotz4 -text "+++" -command {::NeuronVND::rotGraphs z 45}] -row $row -column 4 -sticky news
    incr row
    grid [ttk::separator $w.fp.navigation.main.obj.sep2] -row $row -column 0 -sticky news -columnspan 5 -pady 2 -padx 2
    incr row
    grid [label $w.fp.navigation.main.obj.color -text "Color:"] -row $row -column 0 -sticky news 
    grid [ttk::combobox $w.fp.navigation.main.obj.colorcb -width 7 -values [colorinfo colors] -textvariable ::NeuronVND::colorObj -state readonly] -row $row -column 1 -sticky news -columnspan 2

    bind $w.fp.navigation.main.obj.colorcb <<ComboboxSelected>> {
        set ::NeuronVND::colorObj [%W get]
        set objid [lindex $::NeuronVND::objList 0 0]
        if {$objid != ""} {
            graphics $objid replace 0
            graphics $objid color $::NeuronVND::colorObj
        }
        %W selection clear
    }

    ::NeuronVND::neuronRep
    ::NeuronVND::renderPage
    ::NeuronVND::connectGUI
    ::NeuronVND::spikesPage
    ::NeuronVND::compartPage

    wm geometry $w ${width}x${height}

}

proc ::NeuronVND::renderPage { } {
    set w .neuron
    frame $w.fp.render
    $w.fp add $w.fp.render -text "Render" -padding 2 -sticky news

    grid [frame $w.fp.render.main] -row 0 -column 0 -sticky news
    set gr 0
    grid [labelframe $w.fp.render.main.opt -text "General Options" -labelanchor n] -row $gr -column 0 -sticky news -padx 2 -pady 4
    grid [label $w.fp.render.main.opt.reslbl -text "Resolution:"] -row 0 -column 0 -sticky news -padx 1 -pady 4
    set reslist {"SD (480p)" "HD (720p)" "FullHD (1080p)" "QuadHD (1440p)" "2K (1080p)" "4K (2160p)" "8K (4320p)"}
    grid [ttk::combobox $w.fp.render.main.opt.rescb -width 25 -values $reslist -state readonly] -row 0 -column 1 -sticky news -padx 1 -pady 4
    bind $w.fp.render.main.opt.rescb <<ComboboxSelected>> {
        set text [%W get]
        switch $text {
            "SD (480p)" { display resize 640 480 }
            "HD (720p)" { display resize 1280 720 }
            "FullHD (1080p)" { display resize 1920 1080 }
            "QuadHD (1440p)" { display resize 2560 1440 }
            "2K (1080p)" { display resize 2048 1080 }
            "4K (2160p)" { display resize 3840 2160 }
            "8K (4320p)" { display resize 7680 4320 }
        }
        %W selection clear
    }
        
    grid [label $w.fp.render.main.opt.renderlbl -text "Render using:"] -row 1 -column 0 -sticky news -padx 1 -pady 4
    set renderlist [render list]
    grid [ttk::combobox $w.fp.render.main.opt.rendercb -width 25 -values $renderlist -state readonly] -row 1 -column 1 -sticky news -padx 1 -pady 4
    bind $w.fp.render.main.opt.rendercb <<ComboboxSelected>> {
        set text [%W get]
        set ::NeuronVND::renderMethod $text
        %W selection clear
    }
    incr gr
    
    grid [labelframe $w.fp.render.main.img -text "Image Rendering" -labelanchor n] -row $gr -column 0 -sticky news -padx 2 -pady 4
    set gr1 0
    grid [label $w.fp.render.main.img.filelbl -text "Image Name:"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
    grid [entry $w.fp.render.main.img.fileentry -textvariable ::NeuronVND::renderImgFile] -row $gr1 -column 1 -sticky news -padx 1 -pady 2
    incr gr1
    grid [button $w.fp.render.main.img.renderbut -text "Start Rendering" -command {
        render $::NeuronVND::renderMethod $::NeuronVND::renderImgFile [render default $::NeuronVND::renderMethod]
    }] -row $gr -column 0 -columnspan 2 -sticky news -padx 1 -pady 2
    
    incr gr
    grid [labelframe $w.fp.render.main.mov -text "Movie Rendering" -labelanchor n] -row $gr -column 0 -sticky news -padx 2 -pady 4
    set gr1 0
    # set working dir button and label
    grid [button $w.fp.render.main.mov.but -text "Set working directory:" -command {
        set ::NeuronVND::renderWorkDir [tk_chooseDirectory -initialdir "." -title "Choose working directory"]
    }] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
    grid [label $w.fp.render.main.mov.workdirlbl -textvariable ::NeuronVND::renderWorkDir] -row $gr1 -column 1 -sticky news -padx 1 -pady 2

    incr gr1
    # name of movie
    #grid [label $w.fp.render.main.mov.filelbl -text "Movie Name:"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
    #grid [entry $w.fp.render.main.mov.fileentry -textvariable ::NeuronVND::renderMovFile] -row $gr1 -column 1 -sticky news -padx 1 -pady 2
    incr gr1
    # video processor (e.g. ffmpeg)
    grid [label $w.fp.render.main.mov.proclbl -text "Video Processor:"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
    grid [entry $w.fp.render.main.mov.procentry -textvariable ::NeuronVND::renderVideoProc] -row $gr1 -column 1 -sticky news -padx 1 -pady 2
    incr gr1
    # move duration in seconds
    grid [label $w.fp.render.main.mov.durlbl -text "Movie duration (seconds):"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
    grid [entry $w.fp.render.main.mov.durentry -textvariable ::NeuronVND::renderMovDuration] -row $gr1 -column 1 -sticky news -padx 1 -pady 2
    incr gr1
    # delete image files option
    grid [checkbutton $w.fp.render.main.mov.delimg -text "Delete image files" -variable ::NeuronVND::renderDelImgBool] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
 
}

proc ::NeuronVND::connectGUI { } {
    variable listOfRepsForConnect
    variable repselected

    set w .neuron
    frame $w.fp.connect
    $w.fp add $w.fp.connect -text "Connectivity" -padding 2 -sticky news

    grid [frame $w.fp.connect.main] -row 0 -column 0 -sticky news
    set gr 0
    set aframe $w.fp.connect.main
    grid [label $aframe.title -text "Display connections (edges) between selection of neurons"] -row $gr
    incr gr
    grid [labelframe $aframe.lbl1 -text "Source" -labelanchor n ] -row $gr -column 0 -sticky news  -padx 1 -pady 2
    grid [label $aframe.lbl1.sel -text "Select existing selection:"] -row 0 -column 0 -sticky news
    grid [ttk::combobox $aframe.lbl1.cb -width 60 -values $listOfRepsForConnect -state readonly] -row 0 -column 1 -columnspan 4
    grid [label $aframe.lbl1.sel2 -text "or type selection:"] -row 1 -column 0 -sticky news
    grid [entry $aframe.lbl1.entry -textvariable ::NeuronVND::selSource -width 60] -row 1 -column 1 -columnspan 4 -sticky news
    incr gr
    grid [labelframe $aframe.lbl2 -text "Target" -labelanchor n] -row $gr -column 0 -sticky news -padx 1 -pady 2
    grid [label $aframe.lbl2.sel -text "Select existing selection:"] -row 0 -column 0 -sticky news
    grid [ttk::combobox $aframe.lbl2.cb -width 60 -values $listOfRepsForConnect -state readonly] -row 0 -column 1 -columnspan 4
    grid [label $aframe.lbl2.sel2 -text "or type selection:"] -row 1 -column 0 -sticky news
    grid [entry $aframe.lbl2.entry -textvariable ::NeuronVND::selTarget -width 60] -row 1 -column 1 -columnspan 4 -sticky news

    incr gr

    grid [labelframe $aframe.lbl3 -text "Representation configuration" -labelanchor n ] -row $gr -column 0 -sticky news  -padx 1 -pady 2
    grid [frame $aframe.lbl3.def] -row 0 -column 0 -sticky news -padx 1 -pady 2
    grid [label $aframe.lbl3.def.colorlbl -text "Color:" -anchor e -width 10] -row 0 -column 0
    set colorvalues "Type"
    foreach c [colorinfo colors] {lappend colorvalues $c}
    grid [ttk::combobox $aframe.lbl3.def.coloridcb -width 15 -values $colorvalues -textvariable ::NeuronVND::edgesColor -state readonly] -row 0 -column 1
        
    grid [label $aframe.lbl3.def.matlbl -text "Material:" -width 10 -anchor e] -row 0 -column 2
    set materiallist {"Opaque" "Transparent" "BrushedMetal" "Diffuse" "Ghost" "Glass1" "Glass2" "Glass3" "Glossy" "HardPlastic" "MetallicPastel" "Steel" \
        "Translucent" "Edgy" "EdgyShiny" "EdgyGlass" "Goodsell" "AOShiny" "AOChalky" "AOEdgy" "BlownGlass" "GlassBubble" "RTChrome"}
    grid [ttk::combobox $aframe.lbl3.def.matcb -width 15 -values $materiallist -textvariable ::NeuronVND::edgesMaterial -state readonly] -row 0 -column 3
   
    set edgestyles {simple_edge source_soma target_soma source_target_soma simple_edge_swc source_sphere_swc target_sphere_swc source_target_sphere_swc }
    # source_morphology target_morphology source_morph_sphere target_morph_sphere source_target_morph_sphere simple_edge_morph
    grid [label $aframe.lbl3.def.stylbl -text "Style:" -width 10 -anchor e] -row 1 -column 0
    grid [ttk::combobox $aframe.lbl3.def.stycb -width 15 -values $edgestyles -textvariable ::NeuronVND::edgesStyle -state readonly] -row 1 -column 1
    
    grid [label $aframe.lbl3.def.scalelbl -text "Sphere Scale" -anchor e -width 15] -row 0 -column 4 -sticky news
    grid [spinbox $aframe.lbl3.def.scalespin -width 3 -increment 1 -from 1 -to 10 -textvariable ::NeuronVND::edgesScale -background white]  -row 0 -column 5 -padx 2 -sticky w
    #grid [entry $w.main.arg.en1 -text "5" -width 5] -row 0 -column 1 -sticky news
    grid [label $aframe.lbl3.def.scale2lbl -text "Edges Scale" -anchor e -width 15] -row 1 -column 4 -sticky news
    grid [spinbox $aframe.lbl3.def.scale2spin -width 3 -increment 1 -from 1 -to 10 -textvariable ::NeuronVND::edgesScale2 -background white]  -row 1 -column 5 -padx 2 -sticky w

    incr gr

    grid [frame $aframe.but] -row $gr -column 0 -padx 1 -pady 2
    #grid [ttk::combobox $aframe.but.cb -width 20 -values $edgestyles -textvariable ::NeuronVND::edgesStyle -state readonly] -row 0 -column 0
    #bind $aframe.but.cb <<ComboboxSelected>> {
    #    set text [%W get]
    #    %W selection clear
    #}
    grid [button $aframe.but.create -text "Create connection rep" -command {
        # call the cmd and bypass createRepArgs for now
        set repselected [.neuron.fp.systems.rep.main.table.tb index end]

        if { $::NeuronVND::selSource != "" } {
            # using entry
            set auxSelSource $::NeuronVND::selSource
        } else {
            # using combobox
            set auxSelSource [.neuron.fp.connect.main.lbl1.cb get]
        }

        if { $::NeuronVND::selTarget != "" } {
            # using entry
            set auxSelTarget $::NeuronVND::selTarget
        } else {
            # using combobox
            set auxSelTarget [.neuron.fp.connect.main.lbl2.cb get]
        }

        set repid [::neuro::cmd_create_rep_source_target_edges_fullsel $::NeuronVND::edgesStyle \
            $::NeuronVND::edgesColor $::NeuronVND::edgesMaterial $::NeuronVND::edgesScale 12 $::NeuronVND::edgesScale2 6 $auxSelSource $auxSelTarget]


        # but insert this rep into the table
        set styleRep [lindex $::neuro::nrepList end 3]
        set colorID [lindex $::neuro::nrepList end 4]
        set selRep [lindex $::neuro::nrepList end 6]
        set rowid [.neuron.fp.systems.rep.main.table.tb insert $repselected [list $styleRep $colorID $selRep]]
        # set table curselection and repselected
        .neuron.fp.systems.rep.main.table.tb selection clear 0 end
        .neuron.fp.systems.rep.main.table.tb selection set $rowid
        set repselected [.neuron.fp.systems.rep.main.table.tb curselection]

        # update GUI elements for rep
        ::NeuronVND::updateRepMenu

        # hack resetview to show something
        mol top [lindex [molinfo list] end]
        display resetview

    }] -row 0 -column 1
    #grid [button $aframe.but.show -text "Show/Hide connection rep" -command {}] -row 0 -column 2
    #grid [button $aframe.but.del -text "Delete connection rep" -command {}] -row 0 -column 3
    if {0} {
    incr gr
    grid [frame $aframe.edgeslist] -row $gr -column 0
    grid [tablelist::tablelist $aframe.edgeslist.tb -columns {
        0 "Style" 
        0 "Source"
        0 "Target"
        } \
        -yscrollcommand [list $aframe.edgeslist.scr1 set] \
        -stretch all -background white -stretch 2 -height 6 -width 100 -exportselection false]
    
    ##Scroll_BAr V
    grid [scrollbar $aframe.edgeslist.scr1 -orient vertical -command [list $aframe.edgeslist.tb yview]] -row 0 -column 1  -sticky ens

    $aframe.edgeslist.tb columnconfigure 0 -width 10
    }
}

proc ::NeuronVND::spikesPage { } {
    variable listOfRepsForConnect
    variable listOfPopsForSpikes
    variable downPoint
    variable rightPoint
    set w .neuron
    frame $w.fp.spikes
    $w.fp add $w.fp.spikes -text "Activity" -padding 2 -sticky news

    grid [frame $w.fp.spikes.main] -row 0 -column 0 -sticky news
    set gr 0
    set aframe $w.fp.spikes.main
    grid [label $aframe.title -text "Display animation of neuron activity"] -row $gr
    incr gr
    grid [labelframe $aframe.lbl1 -text "Selection of neurons 1 (required)" -labelanchor nw ] -row $gr -column 0 -sticky news  -padx 1 -pady 2
    grid [label $aframe.lbl1.pop -text "Select population:"] -row 0 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $aframe.lbl1.cbpop -width 60 -values $listOfPopsForSpikes -state readonly -textvariable ::NeuronVND::spikePop1] -row 0 -column 1 -columnspan 4 -padx 1 -pady 2
    grid [label $aframe.lbl1.sel -text "Select existing selection:"] -row 1 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $aframe.lbl1.cb -width 60 -values $listOfRepsForConnect -state readonly -textvariable ::NeuronVND::spikeSel1] -row 1 -column 1 -columnspan 4 -padx 1 -pady 2
    
    grid [frame $aframe.lbl1.def] -row 2 -column 0 -columnspan 2 -sticky news -padx 1 -pady 3
    grid [label $aframe.lbl1.def.colorlbl -text "Color:" -anchor e -width 10] -row 0 -column 0
    grid [ttk::combobox $aframe.lbl1.def.coloridcb -width 12 -values [colorinfo colors] -textvariable ::NeuronVND::spikeColor1 -state readonly] -row 0 -column 1
        
    grid [label $aframe.lbl1.def.matlbl -text "Material:" -width 10 -anchor e] -row 0 -column 2
    set materiallist {"Opaque" "Transparent" "BrushedMetal" "Diffuse" "Ghost" "Glass1" "Glass2" "Glass3" "Glossy" "HardPlastic" "MetallicPastel" "Steel" \
        "Translucent" "Edgy" "EdgyShiny" "EdgyGlass" "Goodsell" "AOShiny" "AOChalky" "AOEdgy" "BlownGlass" "GlassBubble" "RTChrome"}
    grid [ttk::combobox $aframe.lbl1.def.matcb -width 12 -values $materiallist -textvariable ::NeuronVND::spikeMaterial1 -state readonly] -row 0 -column 3
   
    grid [label $aframe.lbl1.def.stylbl -text "Style:" -width 10 -anchor e] -row 1 -column 0
    grid [ttk::combobox $aframe.lbl1.def.stycb -width 12 -values {"soma" "morphology_draft" "morphology"} -textvariable ::NeuronVND::spikeStyle1 -state readonly] -row 1 -column 1
    
    grid [label $aframe.lbl1.def.scalelbl -text "Sphere Scale:" -anchor e] -row 0 -column 4 -sticky news
    grid [spinbox $aframe.lbl1.def.scalespin -width 3 -increment 1 -from 1 -to 10 -textvariable ::NeuronVND::spikeScale1 -background white]  -row 0 -column 5 -padx 1 -sticky w
    grid [label $aframe.lbl1.def.reslbl -text "Sphere Resolution:" -anchor e -width 20] -row 1 -column 4 -sticky news
    grid [spinbox $aframe.lbl1.def.resspin -width 3 -increment 5 -from 5 -to 30 -textvariable ::NeuronVND::spikeRes1 -background white]  -row 1 -column 5 -padx 1 -sticky w

    incr gr
    grid [frame $aframe.lbl2frame] -row $gr -column 0 -sticky news -padx 1 -pady 2
    labelframe $aframe.lbl2frame.lbl -text "Selection of neurons 2" -labelanchor nw
    label $aframe.lbl2frame.lblWidget -text "$downPoint Additional selection (optional)" -anchor w
    $aframe.lbl2frame.lbl configure -labelwidget $aframe.lbl2frame.lblWidget
    label $aframe.lbl2frame.lblWidgetPlaceHolder -text "$rightPoint Additional selection (optional)" -anchor w

    # set mouse click bindings to expand/contract Additional selection settings
    bind $aframe.lbl2frame.lblWidget <Button-1> {
        grid remove .neuron.fp.spikes.main.lbl2frame.lbl
        grid .neuron.fp.spikes.main.lbl2frame.lblWidgetPlaceHolder
        ::NeuronVND::resizeGUI .neuron
    }
    bind $aframe.lbl2frame.lblWidgetPlaceHolder <Button-1> {
        grid remove .neuron.fp.spikes.main.lbl2frame.lblWidgetPlaceHolder
        grid .neuron.fp.spikes.main.lbl2frame.lbl
        ::NeuronVND::resizeGUI .neuron
    }

    grid [label $aframe.lbl2frame.lbl.pop -text "Select population:"] -row 0 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $aframe.lbl2frame.lbl.cbpop -width 60 -values $listOfPopsForSpikes -state readonly -textvariable ::NeuronVND::spikePop2] -row 0 -column 1 -columnspan 4 -padx 1 -pady 2
    grid [label $aframe.lbl2frame.lbl.sel -text "Select existing selection:"] -row 1 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $aframe.lbl2frame.lbl.cb -width 60 -values $listOfRepsForConnect -state readonly -textvariable ::NeuronVND::spikeSel2] -row 1 -column 1 -columnspan 4 -padx 1 -pady 2

    grid [frame $aframe.lbl2frame.lbl.def] -row 2 -column 0 -columnspan 2 -sticky news -padx 1 -pady 3
    grid [label $aframe.lbl2frame.lbl.def.colorlbl -text "Color:" -anchor e -width 10] -row 0 -column 0
    grid [ttk::combobox $aframe.lbl2frame.lbl.def.coloridcb -width 12 -values [colorinfo colors] -textvariable ::NeuronVND::spikeColor2 -state readonly] -row 0 -column 1
        
    grid [label $aframe.lbl2frame.lbl.def.matlbl -text "Material:" -width 10 -anchor e] -row 0 -column 2
    grid [ttk::combobox $aframe.lbl2frame.lbl.def.matcb -width 12 -values $materiallist -textvariable ::NeuronVND::spikeMaterial2 -state readonly] -row 0 -column 3
   
    grid [label $aframe.lbl2frame.lbl.def.stylbl -text "Style:" -width 10 -anchor e] -row 1 -column 0
    grid [ttk::combobox $aframe.lbl2frame.lbl.def.stycb -width 12 -values {"soma" "morphology_draft" "morphology"} -textvariable ::NeuronVND::spikeStyle2 -state readonly] -row 1 -column 1
    
    grid [label $aframe.lbl2frame.lbl.def.scalelbl -text "Sphere Scale:" -anchor e] -row 0 -column 4 -sticky news
    grid [spinbox $aframe.lbl2frame.lbl.def.scalespin -width 3 -increment 1 -from 1 -to 10 -textvariable ::NeuronVND::spikeScale2 -background white]  -row 0 -column 5 -padx 1 -sticky w
    grid [label $aframe.lbl2frame.lbl.def.reslbl -text "Sphere Resolution:" -anchor e -width 20] -row 1 -column 4 -sticky news
    grid [spinbox $aframe.lbl2frame.lbl.def.resspin -width 3 -increment 5 -from 5 -to 30 -textvariable ::NeuronVND::spikeRes2 -background white]  -row 1 -column 5 -padx 1 -sticky w

    grid $aframe.lbl2frame.lbl -row 0 -column 0
    grid remove $aframe.lbl2frame.lbl
    grid $aframe.lbl2frame.lblWidgetPlaceHolder -row 0 -column 0

    incr gr
    grid [button $aframe.but -text "Update selection" -command {
        set ::NeuronVND::spikeMyNodeIdList1 [::neuro::stride_list 1 [::neuro::parse_full_selection_string "$::NeuronVND::spikeSel1 && population == $::NeuronVND::spikePop1" node] ]
        set ::NeuronVND::spikeMyNodeIdList2 [::neuro::stride_list 1 [::neuro::parse_full_selection_string "$::NeuronVND::spikeSel2 && population == $::NeuronVND::spikePop2" node] ]
        # create a 'all' 'soma' rep, top to it, then reset view, and remove the rep.
        ::NeuronVND::createRepArgs show false style soma selection {all}
        display resetview
        ::NeuronVND::delRep
        # update spikeEnd checking both populations and using the maximum time
        if {$::NeuronVND::spikePop2 != ""} {
            set ::NeuronVND::spikeEnd [expr ceil([lindex $::neuro::spikeHash(spikeList,$::NeuronVND::spikePop2) end 1])]
        }
        set auxspikeEnd [expr ceil([lindex $::neuro::spikeHash(spikeList,$::NeuronVND::spikePop1) end 1])]
        if {$auxspikeEnd > $::NeuronVND::spikeEnd} {set ::NeuronVND::spikeEnd $auxspikeEnd} ;# update spikeEnd
        .neuron.fp.spikes.main.slider.scale configure -to $NeuronVND::spikeEnd ;# update slider

    }] -row $gr -column 0
    incr gr
    
    grid [frame $aframe.slider] -row $gr -column 0 -sticky news -padx 1 -pady 2

    grid [entry $aframe.slider.entry -textvariable ::NeuronVND::spikeTime -width 5] -row 0 -column 0
    grid [scale $aframe.slider.scale -state normal -orien horizontal -length 520 -variable ::NeuronVND::spikeTime -sliderlength 12 -showvalue 0 -command {}] -row 0 -column 1 -sticky news -columnspan 3
    #grid [label $aframe.slider.steplbl -text "Step" -width 5] -row 1 -column 0 -sticky news
    #grid [entry $aframe.slider.stepentry -textvariable stepval -width 5] -row 1 -column 1 -sticky news
    #grid [label $aframe.slider.speedlbl -text "Speed" -width 5] -row 1 -column 2 -sticky news
    #grid [scale $aframe.slider.speed -from 1 -to 5 -orien horizontal -length 20 -label "" -variable speedvar -sliderlength 10 -command {}] -row 1 -column 3 -sticky news
    
    image create photo playAnimation -format gif -file [file join $::env(VNDPLUGINDIR) "play.gif"]
    image create photo playbackAnimation -format gif -file [file join $::env(VNDPLUGINDIR) "playback.gif"]
    image create photo pauseAnimation -format gif -file [file join $::env(VNDPLUGINDIR) "pause.gif"]

    incr gr
    grid [frame $aframe.control] -row $gr -column 0 -sticky news -padx 1 -pady 2
    set col 0
    grid [button $aframe.control.playback -image playbackAnimation -command { auxplay playback spike}] -row 0 -column $col -padx 1
    incr col
    grid [ttk::combobox $aframe.control.loopbox -width 6 -background white -values {Once Loop Rock} -state readonly -justify left -textvariable ::NeuronVND::spikeAnimationType] -row 0 -column $col -padx 1
    incr col
    grid [label $aframe.control.steplbl -text "step:" -anchor e -width 6] -row 0 -column $col -padx 1
    incr col
    grid [spinbox $aframe.control.stepspin -background white -width 3 -increment 1 -from 1 -to 20 -textvariable ::NeuronVND::spikeTimeStride] -row 0 -column $col
    incr col
    grid [label $aframe.control.speedlbl -text "speed:" -anchor e -width 8] -row 0 -column $col -padx 1
    incr col
    grid [scale $aframe.control.speedscale -orien horizontal -length 70 -variable ::NeuronVND::spikeWaitTime -from 300 -to 10 -showvalue 0 -background white -sliderlength 8] -row 0 -column $col -padx 1
    incr col
    grid [label $aframe.control.windowlbl -text "time window:" -anchor e -width 12] -row 0 -column $col -padx 1
    incr col
    grid [spinbox $aframe.control.windowspin -background white -width 3 -increment 1 -from 1 -to 20 -textvariable ::NeuronVND::spikeWindowSize] -row 0 -column $col
    incr col
    grid [button $aframe.control.butmovie1 -text "make movie" -width 8 -command {
        ::NeuronVND::movieWindow spike
    }] -row 0 -column $col -sticky news -padx 1
    incr col
    grid [button $aframe.control.playforward -image playAnimation -command { auxplay playforward spike}] -row 0 -column $col -padx 1
    grid columnconfigure $aframe.control $col -weight 1

    $aframe.slider.scale configure -from $NeuronVND::spikeStart
    $aframe.slider.scale configure -to $NeuronVND::spikeEnd
    trace add variable ::NeuronVND::spikeTime write {::NeuronVND::animateSpike}
    

}

proc ::NeuronVND::animateSpike {args} {

   ::neuro::show_spike_pop_moment_from_list $::NeuronVND::spikeStyle1 $::NeuronVND::spikeColor1 $::NeuronVND::spikeMaterial1 $::NeuronVND::spikeScale1 $::NeuronVND::spikeRes1 $NeuronVND::spikeTime [expr $NeuronVND::spikeTime + $NeuronVND::spikeWindowSize -1] $NeuronVND::spikePop1 $NeuronVND::spikeMyNodeIdList1 $NeuronVND::spikeWindowSize $::NeuronVND::spikeMolidForGraphics1 
   if {[llength $::NeuronVND::spikeMyNodeIdList2]} { ;# fix for empty optional selection
   ::neuro::show_spike_pop_moment_from_list $::NeuronVND::spikeStyle2 $::NeuronVND::spikeColor2 $::NeuronVND::spikeMaterial2 $::NeuronVND::spikeScale2 $::NeuronVND::spikeRes2 $NeuronVND::spikeTime [expr $NeuronVND::spikeTime + $NeuronVND::spikeWindowSize -1] $NeuronVND::spikePop2 $NeuronVND::spikeMyNodeIdList2 $NeuronVND::spikeWindowSize $::NeuronVND::spikeMolidForGraphics2 
   }
   ::NeuronVND::display_marker $::NeuronVND::spikeTime
}

proc auxplay { mode type} {
    
    if {$type == "spike"} {

        if {$mode == "playback"} {
            set ::NeuronVND::spikeAbort 0
            .neuron.fp.spikes.main.control.playback configure -image pauseAnimation -command {auxplay pauseback spike}
            
            while { $::NeuronVND::spikeTime <= $::NeuronVND::spikeEnd && $::NeuronVND::spikeAbort == 0} {
                display update ui
                incr ::NeuronVND::spikeTime [expr -1 * $::NeuronVND::spikeTimeStride]
                after $::NeuronVND::spikeWaitTime
            }
        } elseif {$mode == "playforward"} {
            set ::NeuronVND::spikeAbort 0
            .neuron.fp.spikes.main.control.playforward configure -image pauseAnimation -command {auxplay pause spike}
            
            while { $::NeuronVND::spikeTime <= $::NeuronVND::spikeEnd && $::NeuronVND::spikeAbort == 0} {
                display update ui
                incr ::NeuronVND::spikeTime $::NeuronVND::spikeTimeStride
                after $::NeuronVND::spikeWaitTime
            }
        } elseif {$mode == "pauseback"} {
            set ::NeuronVND::spikeAbort 1
            .neuron.fp.spikes.main.control.playback configure -image playbackAnimation -command {auxplay playback spike}
        } elseif {$mode == "pause"} {
            set ::NeuronVND::spikeAbort 1
            .neuron.fp.spikes.main.control.playforward configure -image playAnimation -command {auxplay playforward spike}
        }
    } elseif {$type == "compart"} {
        if {$mode == "playback"} {
            set ::NeuronVND::compartAbort 0
            .neuron.fp.compart.main.control.playback configure -image pauseAnimation -command {auxplay pauseback compart}
            
            while { $::NeuronVND::compartTime <= $::NeuronVND::compartEnd && $::NeuronVND::compartAbort == 0} {
                display update ui
                incr ::NeuronVND::compartTime [expr -1 * $::NeuronVND::compartTimeStride]
                after $::NeuronVND::compartWaitTime
            }
        } elseif {$mode == "playforward"} {
            set ::NeuronVND::compartAbort 0
            .neuron.fp.compart.main.control.playforward configure -image pauseAnimation -command {auxplay pause compart}
            
            while { $::NeuronVND::compartTime <= $::NeuronVND::compartEnd && $::NeuronVND::compartAbort == 0} {
                display update ui
                incr ::NeuronVND::compartTime $::NeuronVND::compartTimeStride
                after $::NeuronVND::compartWaitTime
            }
        } elseif {$mode == "pauseback"} {
            set ::NeuronVND::compartAbort 1
            .neuron.fp.compart.main.control.playback configure -image playbackAnimation -command {auxplay playback compart}
        } elseif {$mode == "pause"} {
            set ::NeuronVND::compartAbort 1
            .neuron.fp.compart.main.control.playforward configure -image playAnimation -command {auxplay playforward compart}
        }
    }    
}

proc ::NeuronVND::compartPage { } {
    set w .neuron
    frame $w.fp.compart
    $w.fp add $w.fp.compart -text "Compartments" -padding 2 -sticky news

    grid [frame $w.fp.compart.main] -row 0 -column 0 -sticky news
    set gr 0
    set aframe $w.fp.compart.main
    grid [label $aframe.title -text "Display animation of compartment data"] -row $gr
    incr gr
    grid [labelframe $aframe.lbl1 -text "Selection of neurons" -labelanchor n ] -row $gr -column 0 -sticky news  -padx 1 -pady 2
    grid [label $aframe.lbl1.poplbl -text "Population:"] -row 0 -column 0 -sticky news -padx 1 -pady 2
    grid [entry $aframe.lbl1.popentry -textvariable ::NeuronVND::compartPop -width 60] -row 0 -column 1 -columnspan 4 -sticky news
    grid [label $aframe.lbl1.sel -text "Define selection:"] -row 1 -column 0 -sticky news
    grid [entry $aframe.lbl1.entry -textvariable ::NeuronVND::compartSel -width 60] -row 1 -column 1 -columnspan 4 -sticky news
    grid [button $aframe.lbl1.but -text "Update selection" -command {

        set searchAppend " && ( !(model_type == virtual) )"
        if $::neuro::display_virtuals_at_creation { 
            set full_selection_string_virt_check  $::NeuronVND::compartSel
        } else {
            set full_selection_string_virt_check {}
            append full_selection_string_virt_check $::NeuronVND::compartSel $searchAppend
        }
        puts $full_selection_string_virt_check
        set ::NeuronVND::compartMyNodeIdList [::neuro::parse_full_selection_string $full_selection_string_virt_check node]
        # checks imported from ::neuro::compart_animate_selection_render_ranged
        if {$::NeuronVND::compartMyNodeIdList == -1} {
            return -1
        }
        puts "length of myGlobalNodeIdList is [llength $::NeuronVND::compartMyNodeIdList]"
        
        set t_index_max 0
        #search pops in selection for largest t_index_max
        foreach e $::NeuronVND::compartMyNodeIdList {
            foreach {ex ey ez exrot eyrot ezrot etype efileset_num epop enode_id egroup_id egroup_index ecartesian}  $::neuro::node($e) {}
            if { ! [catch {set ti_max_pop $::neuro::compartHash($epop,t_index_max)  }]} {
                if {$ti_max_pop > $t_index_max} {
                    set t_index_max $ti_max_pop
                }
            }
        }
        #puts "t_index_beg= $t_index_beg  t_index_end= $t_index_end t_index_incr= $t_index_incr  t_index_max= $t_index_max"

        if {$t_index_max  == 0} {::neuro::showError "No compartment time data found for selection \"$::NeuronVND::compartSel\""; return -1}

        # create a 'all' 'soma' rep, top to it, then reset view, and remove the rep.
        if {$::NeuronVND::compartMolId == ""} {
            set ::NeuronVND::compartRepId [::neuro::cmd_create_rep_compart_moment_selection_ranged $full_selection_string_virt_check 1 spheretube BlueToRed Opaque -82.16 -60]
            set ::NeuronVND::compartMolId [lindex $::neuro::nrepList end 2]
            # update rep table

        }
        
        # update min and max data values
        foreach p [::neuro::cmd_query compartment_data_min_max] {
            if {[lsearch $p $::NeuronVND::compartPop] != -1} {
                lassign [lindex $p 1] ::NeuronVND::compartRangeMin ::NeuronVND::compartRangeMax
            }
        }

    }] -row 2 -column 1
    incr gr
    grid [labelframe $aframe.lbl3 -text "Representation configuration" -labelanchor n ] -row $gr -column 0 -sticky news  -padx 1 -pady 2
    grid [frame $aframe.lbl3.def] -row 0 -column 0 -sticky news -padx 1 -pady 2
    grid [label $aframe.lbl3.def.colorlbl -text "Color:" -anchor e -width 10] -row 0 -column 0
    grid [ttk::combobox $aframe.lbl3.def.coloridcb -width 12 -values {"BlueToRed"} -textvariable ::NeuronVND::compartColor -state readonly] -row 0 -column 1
        
    grid [label $aframe.lbl3.def.matlbl -text "Material:" -width 10 -anchor e] -row 0 -column 2
    set materiallist {"Opaque" "Transparent" "BrushedMetal" "Diffuse" "Ghost" "Glass1" "Glass2" "Glass3" "Glossy" "HardPlastic" "MetallicPastel" "Steel" \
        "Translucent" "Edgy" "EdgyShiny" "EdgyGlass" "Goodsell" "AOShiny" "AOChalky" "AOEdgy" "BlownGlass" "GlassBubble" "RTChrome"}
    grid [ttk::combobox $aframe.lbl3.def.matcb -width 12 -values $materiallist -textvariable ::NeuronVND::compartMaterial -state readonly] -row 0 -column 3
   
    grid [label $aframe.lbl3.def.stylbl -text "Style:" -width 10 -anchor e] -row 1 -column 0
    grid [ttk::combobox $aframe.lbl3.def.stycb -width 12 -values {"line" "sphere" "spheretube"} -textvariable ::NeuronVND::compartStyle -state readonly] -row 1 -column 1
    
    grid [label $aframe.lbl3.def.maxlbl -text "Maximum Value:" -anchor e] -row 0 -column 4 -sticky news
    grid [entry $aframe.lbl3.def.maxentry -width 6 -textvariable ::NeuronVND::compartRangeMax -justify right]  -row 0 -column 5 -padx 1 -sticky w
    grid [label $aframe.lbl3.def.minlbl -text "Minimum Value:" -anchor e -width 20] -row 1 -column 4 -sticky news
    grid [entry $aframe.lbl3.def.minentry -width 6 -textvariable ::NeuronVND::compartRangeMin -justify right]  -row 1 -column 5 -padx 1 -sticky w

    incr gr
    grid [frame $aframe.slider] -row $gr -column 0 -sticky news -padx 1 -pady 2

    grid [entry $aframe.slider.entry -textvariable ::NeuronVND::compartTime -width 5] -row 0 -column 0
    grid [scale $aframe.slider.scale -state normal -orien horizontal -length 475 -variable ::NeuronVND::compartTime -sliderlength 12 -showvalue 0 -command {}] -row 0 -column 1 -sticky news -columnspan 3 -pady 2

    image create photo playAnimation -format gif -file [file join $::env(VNDPLUGINDIR) "play.gif"]
    image create photo playbackAnimation -format gif -file [file join $::env(VNDPLUGINDIR) "playback.gif"]
    image create photo pauseAnimation -format gif -file [file join $::env(VNDPLUGINDIR) "pause.gif"]

    incr gr
    grid [frame $aframe.control] -row $gr -column 0 -sticky news -padx 1 -pady 2
    set col 0
    grid [button $aframe.control.playback -image playbackAnimation -command { auxplay playback compart }] -row 0 -column $col -padx 1
    incr col
    grid [ttk::combobox $aframe.control.loopbox -width 6 -background white -values {Once Loop Rock} -state readonly -justify left -textvariable ::NeuronVND::compartAnimationType] -row 0 -column $col -padx 1
    incr col
    grid [label $aframe.control.steplbl -text "step:" -anchor e -width 6] -row 0 -column $col -padx 1
    incr col
    grid [spinbox $aframe.control.stepspin -background white -width 3 -increment 1 -from 1 -to 20 -textvariable ::NeuronVND::compartTimeStride] -row 0 -column $col
    incr col
    grid [label $aframe.control.speedlbl -text "speed:" -anchor e -width 8] -row 0 -column $col -padx 1
    incr col
    grid [scale $aframe.control.speedscale -orien horizontal -length 70 -variable ::NeuronVND::compartWaitTime -from 300 -to 10 -showvalue 0 -background white -sliderlength 8] -row 0 -column $col -padx 1
    incr col
    grid [label $aframe.control.windowlbl -text "time window:" -anchor e -width 12] -row 0 -column $col -padx 1
    incr col
    grid [spinbox $aframe.control.windowspin -background white -width 3 -increment 1 -from 1 -to 20 -textvariable ::NeuronVND::compartWindowSize] -row 0 -column $col
    incr col
    grid [button $aframe.control.butmovie2 -text "make movie" -width 8 -command {
        ::NeuronVND::movieWindow compartment
    }] -row 0 -column $col -sticky news -padx 1
    incr col
    grid [button $aframe.control.playforward -image playAnimation -command { auxplay playforward compart }] -row 0 -column $col -padx 1
    grid columnconfigure $aframe.control $col -weight 1

    $aframe.slider.scale configure -from $NeuronVND::compartStart
    $aframe.slider.scale configure -to $NeuronVND::compartEnd
    trace add variable ::NeuronVND::compartTime write {::NeuronVND::animatecompart}

}

proc ::NeuronVND::animatecompart {args} {

   ::neuro::show_compart_moment_nodelist_ranged $::NeuronVND::compartMyNodeIdList $::NeuronVND::compartStyle $::NeuronVND::compartColor $::NeuronVND::compartMaterial $NeuronVND::compartTime $::NeuronVND::compartRangeMin $::NeuronVND::compartRangeMax $::NeuronVND::compartMolId 

}

proc ::NeuronVND::neuronGui { } {

   variable timeentry
   variable proxyantialias
   variable proxydepthcueing
   variable proxyfps
   variable proxylight0 
   variable proxylight1 
   variable proxylight2 
   variable proxylight3 

   set w [toplevel $::NeuronVND::topGui]
   wm title $w "Visual Neuronal Dynamics"
   wm resizable $w 1 1
   set width 650 ;# in pixels
   set height 385 ;# in pixels 290x200+782+454
   wm geometry $w ${width}x${height}+782+454
   grid columnconfigure $w 0 -weight 1
   grid columnconfigure $w 1 -weight 0
   grid rowconfigure $w 0 -weight 0
   grid rowconfigure $w 1 -weight 1

   wm protocol $::NeuronVND::topGui WM_DELETE_WINDOW ::NeuronVND::exit

   grid [frame $w.menubar -relief raised -bd 2] -row 0 -column 0 -sticky nswe -pady 2 -padx 2
   grid columnconfigure $w.menubar 4 -weight 1
   grid rowconfigure $w.menubar 0 -weight 1

   grid [menubutton $w.menubar.file -text "File" -width 5 -menu $w.menubar.file.menu] -row 0 -column 0 -sticky ew
   #grid [menubutton $w.menubar.system -text "System" -width 8 -menu $w.menubar.system.menu] -row 0 -column 1 -sticky ew
   grid [menubutton $w.menubar.display -text "Display" -width 8 -menu $w.menubar.display.menu] -row 0 -column 2 -sticky ew
   grid [menubutton $w.menubar.analysis -text "Analysis" -width 8 -menu $w.menubar.analysis.menu] -row 0 -column 3 -sticky ew
   grid [menubutton $w.menubar.help -text "Help" -width 5 -menu $w.menubar.help.menu] -row 0 -column 4 -sticky e
      
   # File
   menu $w.menubar.file.menu -tearoff no
   $w.menubar.file.menu add command -label "Open File" -command { 
        set cfgfile [tk_getOpenFile -initialdir "." -title "Choose config file"]
        if {$cfgfile != ""} {
            ::NeuronVND::statusBarChanges loading
            ::NeuronVND::loadFiles $cfgfile
            ::NeuronVND::statusBarChanges ready
            }
   }
   $w.menubar.file.menu add command -label "Open File with Edges" -command { 
        set cfgfile [tk_getOpenFile -initialdir "." -title "Choose config file"]
        if {$cfgfile != ""} {::NeuronVND::loadFiles $cfgfile true true}
   }
   $w.menubar.file.menu add command -label "Add File with Spikes" -command { 
        set cfgfile [tk_getOpenFile -initialdir "." -title "Choose config file"]
        if {$cfgfile != ""} {::NeuronVND::loadSpikes $cfgfile}
   }
   $w.menubar.file.menu add command -label "Add File with Compartment Data" -command { 
        set cfgfile [tk_getOpenFile -initialdir "." -title "Choose config file"]
        if {$cfgfile != ""} {::NeuronVND::loadCompartmentData $cfgfile}
   }
   $w.menubar.file.menu add command -label "Add Object" -command { 
        set file [tk_getOpenFile -initialdir "." -title "Choose object file"]
        if {$file != ""} {::NeuronVND::loadObject $file}
   }
   $w.menubar.file.menu add separator
   $w.menubar.file.menu add command -label "Load Visualization State" -command {::NeuronVND::visState load}
   $w.menubar.file.menu add command -label "Save Visualization State" -command {::NeuronVND::visState save}

   $w.menubar.file.menu add separator
   $w.menubar.file.menu add command -label "Reset VND" -command {::NeuronVND::resetVND}
   $w.menubar.file.menu add separator
   $w.menubar.file.menu add command -label "Quit" -command {::NeuronVND::exit}

   #$w.menubar.file.menu add command -label "Write Input File" -command { }

   # System
   #menu $w.menubar.system.menu -tearoff no
   #$w.menubar.system.menu add command -label "System Information" -command { ::NeuronVND::neuronInfo } -state disabled
   #$w.menubar.system.menu add command -label "Representations" -command { ::NeuronVND::neuronRep }

    # Display
   menu $w.menubar.display.menu -tearoff no
   #menu $w.menubar.display.menu.orient -tearoff no -title "Menu"
   #$w.menubar.display.menu add cascade -label "Menu" -menu $w.menubar.display.menu.orient
   #$w.menubar.display.menu.orient add radiobutton -label "Horizontal" -variable orient -value "nw" -command { ::NeuronVND::createPages nw }
   #$w.menubar.display.menu.orient add radiobutton -label "Vertical" -variable orient -value "wn" -command { ::NeuronVND::createPages wn }
   
   # 300 cell example requires resetview and scale by 0.111;
   
   $w.menubar.display.menu add command -label "Reset View" -command { display resetview }
   $w.menubar.display.menu add command -label "Stop Rotation" -command { rotate stop }
   $w.menubar.display.menu add separator
   $w.menubar.display.menu add radiobutton -label "Perspective" -variable perps -value on -command {display projection Perspective}
   $w.menubar.display.menu add radiobutton -label "Orthographic" -variable perps -value off -command {display projection Orthographic}
   set perps on
   $w.menubar.display.menu add separator   
   $w.menubar.display.menu add checkbutton -label "Antialiasing" -variable ::NeuronVND::proxyantialias -onvalue on -offvalue off -command { 
       switch $::NeuronVND::proxyantialias {
           "on"  { display antialias on }
           "off" { display antialias off }
       }
   }
   $w.menubar.display.menu add checkbutton -label "Depth Cueing" -variable ::NeuronVND::proxydepthcueing -onvalue on -offvalue off -command { 
       switch $::NeuronVND::proxydepthcueing {
           "on"  { display depthcue on }
           "off" { display depthcue off }
       }
   }
   $w.menubar.display.menu add checkbutton -label "FPS Indicator" -variable ::NeuronVND::proxyfps -onvalue on -offvalue off -command { 
       switch $::NeuronVND::proxyfps {
           "on"  { display fps on }
           "off" { display fps off }
       }
   }
   $w.menubar.display.menu add separator   
   $w.menubar.display.menu add checkbutton -label "Light 0" -variable ::NeuronVND::proxylight0 -onvalue on -offvalue off -command { 
       switch $::NeuronVND::proxylight0 {
           "on"  { light 0 on }
           "off" { light 0 off }
       }
   }
   $w.menubar.display.menu add checkbutton -label "Light 1" -variable ::NeuronVND::proxylight1 -onvalue on -offvalue off -command { 
       switch $::NeuronVND::proxylight1 {
           "on"  { light 1 on }
           "off" { light 1 off }
       }
   }
   $w.menubar.display.menu add checkbutton -label "Light 2" -variable ::NeuronVND::proxylight2 -onvalue on -offvalue off -command { 
       switch $::NeuronVND::proxylight2 {
           "on"  { light 2 on }
           "off" { light 2 off }
       }
   }
   $w.menubar.display.menu add checkbutton -label "Light 3" -variable ::NeuronVND::proxylight3 -onvalue on -offvalue off -command { 
       switch $::NeuronVND::proxylight3 {
           "on"  { light 3 on }
           "off" { light 3 off }
       }
   }      
   $w.menubar.display.menu add separator   
   menu $w.menubar.display.menu.axes -tearoff no -title "Axes"
   $w.menubar.display.menu add cascade -label "Axes" -menu $w.menubar.display.menu.axes
   $w.menubar.display.menu.axes add radiobutton -label "Off" -variable axes -value off -command { axes location Off }
   $w.menubar.display.menu.axes add radiobutton -label "Origin" -variable axes -value origin -command { axes location Origin }
   $w.menubar.display.menu.axes add radiobutton -label "Lower Left" -variable axes -value lowerleft -command { axes location LowerLeft }
   $w.menubar.display.menu.axes add radiobutton -label "Lower Right" -variable axes -value lowerright -command { axes location LowerRight }
   $w.menubar.display.menu.axes add radiobutton -label "Upper Left" -variable axes -value upperleft -command { axes location UpperLeft }
   $w.menubar.display.menu.axes add radiobutton -label "Upper Right" -variable axes -value upperright -command { axes location UpperRight }
   
   menu $w.menubar.display.menu.background -tearoff no -title "Background"
   $w.menubar.display.menu add cascade -label "Background" -menu $w.menubar.display.menu.background
   $w.menubar.display.menu.background add radiobutton -label "Solid Color" -variable bgsolid -value on -command { display backgroundgradient off }
   $w.menubar.display.menu.background add radiobutton -label "Gradient" -variable bgsolid -value off -command { display backgroundgradient on }
   $w.menubar.display.menu add separator
   menu $w.menubar.display.menu.rendermode -tearoff no -title "Render Mode"
   $w.menubar.display.menu add cascade -label "Render Mode" -menu $w.menubar.display.menu.rendermode
   $w.menubar.display.menu.rendermode add radiobutton -label "Normal" -variable render -value normal -command { display rendermode Normal }
   $w.menubar.display.menu.rendermode add radiobutton -label "GLSL" -variable render -value glsl -command { display rendermode GLSL }
   $w.menubar.display.menu.rendermode add radiobutton -label "Tachyon RTX RTRT" -variable render -value rtrt -command { display rendermode "Tachyon RTX RTRT" }
   $w.menubar.display.menu.rendermode add radiobutton -label "Acrobat3D" -variable render -value a3D -command { display rendermode Acrobat3D }
   $w.menubar.display.menu add separator
   $w.menubar.display.menu add command -label "Display Settings" -command { menu display off; menu display on }
   $w.menubar.display.menu add command -label "Ruler" -command {::Ruler::ruler_gui}

    # Analysis
   menu $w.menubar.analysis.menu -tearoff no
   #$w.menubar.analysis.menu add command -label "Timeline Analysis" -command { neuronTimeline } -state disabled
   $w.menubar.analysis.menu add command -label "Raster Plot" -command { ::NeuronVND::rasterWindow }
   $w.menubar.analysis.menu add command -label "Alignment Tool" -command { ::NeuronVND::alignmentToolWindow }


   # Help
   menu $w.menubar.help.menu -tearoff no
   $w.menubar.help.menu add command -label "Website, Tutorial and FAQs" \
       -command "vmd_open_url https://www.ks.uiuc.edu/Research/vnd/"
   $w.menubar.help.menu add checkbutton -label "Debug Mode" -variable ::neuro::debugMode -onvalue 1 -offvalue 0 -command { 
       puts "debugMode $::neuro::debugMode"
   }      

    ::NeuronVND::createPages nw

    # create a frame at the bottom of the GUI
    grid [frame .neuron.status] -row 2 -column 0 -sticky news
    # a fix label 'Status'
    grid [ttk::label .neuron.status.lbl1 -text "Status:" -anchor w] -row 0 -column 0 -sticky news
    # a variable label telling the user the status
    grid [ttk::label .neuron.status.lbl2 -textvariable ::NeuronVND::statusLabel -width 10 -anchor c] -row 0 -column 1 -sticky news
    # a progress bar controlled by ...
    grid [ttk::progressbar .neuron.status.pbar -variable ::NeuronVND::statusPbarVal -length 550] -row 0 -column 2 -sticky news 

}

::NeuronVND::neuronGui




proc ::NeuronVND::neuronInfo { } {

   set w [toplevel ".neuron.info"]
   wm title $w "System Information"
   wm resizable $w 1 1
   set width 290 ;# in pixels
   set height 100 ;# in pixels
   wm geometry $w ${width}x${height}

   grid [frame $w.main] -row 0 -column 0 -sticky news

   grid [ttk::frame $w.main.t1] -row 0 -column 0 -sticky nswe -padx 4 -columnspan 8

   grid columnconfigure $w.main.t1 0 -weight 1
   grid rowconfigure $w.main.t1 0 -weight 1


   #grid columnconfigure $w.main 0 -weight 1
   #grid rowconfigure $w.main 0 -weight 1

   #option add *Tablelist.activeStyle       frame
   
   set fro2 $w.main.t1

   option add *Tablelist.movableColumns    no
   option add *Tablelist.labelCommand      tablelist::sortByColumn

       tablelist::tablelist $fro2.tb -columns {\
           0 "Type" center
           0 "Number" center
           0 "Events" center
           0 "Notes" center
       }\
       -yscrollcommand [list $fro2.scr1 set] \
               -showseparators 0 -labelrelief groove  -labelbd 1 -selectforeground black\
               -foreground black -background white -width 45 -height 6 -state normal -selectmode extended -stretch all -stripebackgroun white -exportselection true\
               
   grid $fro2.tb -row 0 -column 0 -sticky news 
   
   ##Scroll_BAr V
   scrollbar $fro2.scr1 -orient vertical -command [list $fro2.tb  yview]
    grid $fro2.scr1 -row 0 -column 1  -sticky ens

    $fro2.tb insert end [list "101" "20.000" "12" "mayority"]
    $fro2.tb insert end [list "102" "7.000" "5" ""]
    $fro2.tb insert end [list "103" "3.000" "1" ""]

}

proc ::NeuronVND::loadObject {f} {
    variable objList
    variable historyCalls
    # current shortcut
    set objid [mol new]
    graphics $objid color white
    mol addfile $f
    mol rename $objid $f
    lappend objList [list $objid $f]
    catch {.neuron.fp.navigation.main.obj.cb configure -values $::NeuronVND::objList}
    lappend ::NeuronVND::historyCalls "::NeuronVND::loadObject $f"
}

proc ::NeuronVND::loadSpikes {f} {
    variable historyCalls
    ::neuro::load_hdf5_spike_file $f
    lappend ::NeuronVND::historyCalls "::NeuronVND::loadSpikes $f"
    set ::NeuronVND::spikeMolidForGraphics1 [mol new]
    set ::NeuronVND::spikeMolidForGraphics2 [mol new]
    set ::NeuronVND::listOfPopsForSpikes [lsort -decreasing -unique [::neuro::cmd_query node_list_attrib_values population [::neuro::parse_full_selection_string all node]]]
    .neuron.fp.spikes.main.lbl1.cbpop configure -values $::NeuronVND::listOfPopsForSpikes
    .neuron.fp.spikes.main.lbl2frame.lbl.cbpop configure -values $::NeuronVND::listOfPopsForSpikes
}

proc ::NeuronVND::loadCompartmentData {f} {
    variable historyCalls
    ::neuro::load_hdf5_compart_file $f
    lappend ::NeuronVND::historyCalls "::NeuronVND::loadCompartmentData $f"
    #set ::NeuronVND::compartRepId [::neuro::cmd_create_rep_compart_moment_selection_ranged "all" 850 spheretube BlueToRed Opaque -82.16 -60]
    #set ::NeuronVND::compartMolId [lindex $::neuro::nrepList $::NeuronVND::compartRepId 2]
}

proc ::NeuronVND::loadAttributeData { } {
    #global vars
    set w .neuron
    variable output_list
    variable noutput_list
    variable nonstandard_list

    #Reading standard values by array and splitting it to a list
    set values(0,attribs) [::neuro::cmd_query standard_node_attribs]
    set split_values [split $values(0,attribs) " "]
    #non-stardard attribs
    set nonstd_values(0,nattribs) [::neuro::cmd_query non_standard_node_attribs]
    set split_nonstd_values [split $nonstd_values(0,nattribs) " "]

    #Populating attributes tablelist by iterating through values
    foreach item $split_values {
        $w.fp.systems.rep.main.def.nb.page2.kw.kwtable1 insert end $item
    }

    foreach nitem $split_nonstd_values {
        $w.fp.systems.rep.main.def.nb.page2.kw.kwtable1 insert end "$nitem"
    }

    puts "CREATING LOCAL CACHE" 
    #Attain raw data output list format {attrib, {values}} and sort for both std and nonstd values
    foreach output $split_values {
        #set itr [list $output [lsort -unique [::neuro::cmd_query node_list_attrib_values $output [::neuro::parse_full_selection_string "all" node]]] ]
        set itr [list $output [::neuro:::sort_uniq_mixed_list  [::neuro::cmd_query node_list_attrib_values $output [::neuro::parse_full_selection_string "all" node]]] ]
        if {$output == "node" || $output == "node_id"} {
            set itr [list $output [lsort -unique -integer [::neuro::cmd_query node_list_attrib_values $output [::neuro::parse_full_selection_string "all" node]]] ]
        }
        lappend output_list $itr
    }
    foreach noutput $split_nonstd_values {
        #set itr_two [list $noutput [lsort -unique [::neuro::cmd_query node_list_attrib_values $noutput [::neuro::parse_full_selection_string "all" node]]] ]
        set itr_two [list $noutput [::neuro:::sort_uniq_mixed_list [::neuro::cmd_query node_list_attrib_values $noutput [::neuro::parse_full_selection_string "all" node]]] ]
        lappend nonstandard_list $itr_two
    }

    #Prepare data before bind event by merging std and non-std attribs in 1 searchable list 
    set ::NeuronVND::combined [list {*}$output_list {*}$nonstandard_list]
    puts "FINISHED LOCAL CACHE"

    #Selection and double click binds
    bind $w.fp.systems.rep.main.def.nb.page2.kw.kwtable1 <<TablelistSelect>> {  
        set w .neuron
        variable output_list
        variable noutput_list
        variable attrib_combo_list
        #set paths for tables
        set tbl $w.fp.systems.rep.main.def.nb.page2.kw.kwtable1
        set vtbl $w.fp.systems.rep.main.def.nb.page2.values.vtable1
        set min_max_tbl $w.fp.systems.rep.main.def.nb.page2.min_max.min_max_table
    
        #clear the tables initially
        $vtbl delete 0 end
        $min_max_tbl delete 0 end
        set selection [$tbl cellcget [$tbl curselection],0 -text]
        puts "Current selection: $selection"

        #copy to local variable
        set attrib_combo_list $::NeuronVND::combined

        #Search for current selection in the merged list
        set search [lsearch -all -inline $attrib_combo_list *$selection*]

        #booleans to check if attribute values can have min/max reduce function
        if {$selection == "x" || $selection == "y" || $selection == "z"} {
            set min [tcl::mathfunc::min {*}[lindex $search 0 1]]
            puts "Minimum: $min"
            $w.fp.systems.rep.main.def.nb.page2.min_max.min_max_table insert end [list "$min"]
            set max [tcl::mathfunc::max {*}[lindex $search 0 1]]
            puts "Maximum: $max"
            $w.fp.systems.rep.main.def.nb.page2.min_max.min_max_table insert end [list "$max"]
        }
        #insert each value for current selection in tablelist and populate vertically
        foreach {element} [lindex $search 0 1] {
            $w.fp.systems.rep.main.def.nb.page2.values.vtable1 insert end $element
        }
    }

    bind [$w.fp.systems.rep.main.def.nb.page2.kw.kwtable1 bodytag] <Double-1> {
        set w .neuron
        set attrib_combo_list $::NeuronVND::combined
        #set paths for tables
        set tbl $w.fp.systems.rep.main.def.nb.page2.kw.kwtable1
        set vtbl $w.fp.systems.rep.main.def.nb.page2.values.vtable1
        set min_max_tbl $w.fp.systems.rep.main.def.nb.page2.min_max.min_max_table
        
        #clear entry
        set empty " "
        .neuron.fp.systems.rep.main.sel.entry insert "insert" $empty

        #Search for current selection in the merged list
        set selection [$tbl cellcget [$tbl curselection],0 -text]
        set search [lsearch -all -inline $attrib_combo_list *$selection*]

        #create the builder string to be concatenated
        set builder "[lindex $search 0 0] "
        .neuron.fp.systems.rep.main.sel.entry insert "insert" $builder

    }
    bind [$w.fp.systems.rep.main.def.nb.page2.values.vtable1 bodytag] <Double-1> {
        set w .neuron
        #set paths for tables
        set tbl $w.fp.systems.rep.main.def.nb.page2.kw.kwtable1
        set vtbl $w.fp.systems.rep.main.def.nb.page2.values.vtable1
        set min_max_tbl $w.fp.systems.rep.main.def.nb.page2.min_max.min_max_table

        set selection [$vtbl cellcget [$vtbl curselection],0 -text]
        .neuron.fp.systems.rep.main.sel.entry insert "insert" "$selection "
    }
    bind [$w.fp.systems.rep.main.def.nb.page2.min_max.min_max_table bodytag] <Double-1> {
        set w .neuron
        #set paths for tables
        set tbl $w.fp.systems.rep.main.def.nb.page2.kw.kwtable1
        set vtbl $w.fp.systems.rep.main.def.nb.page2.values.vtable1
        set min_max_tbl $w.fp.systems.rep.main.def.nb.page2.min_max.min_max_table
        
        #clear the tables initially
        set selection [$min_max_tbl cellcget [$min_max_tbl curselection],0 -text]
        .neuron.fp.systems.rep.main.sel.entry insert "insert" "$selection "
    }
}

proc ::NeuronVND::loadFiles {cfgfile {createrep true} {loadedges false}} {
    variable listmodels
    variable indexmodel
    variable historyCalls
    
    set neuronrep .neuron.fp.systems.rep;#.neuron.rep.

    ####### For the future application 
    # read files
    set success 0
    # if succesful increase indexmodel
    if {$success} {}
    # populate main table required values
    set listmodels($indexmodel,id) 0
    set listmodels($indexmodel,name) ""
    set listmodels($indexmodel,neurons) ""
    ############################################
    
    ::neuro::cmd_load_model_config_file [pwd] $cfgfile $loadedges

    # preliminary naming for the models coming from file .h5
    set listmodels(0,name) [lindex [split [lindex [::neuro::cmd_query filesets] 0 0] /] end]
    set listmodels(0,neurons) [::neuro::cmd_query num_neurons_non_virtual]

    .neuron.fp.systems.main.tb insert end [list "0" "T" "D" $listmodels(0,name) $listmodels(0,neurons)]

    ::NeuronVND::populateTree
    lappend ::NeuronVND::historyCalls "::NeuronVND::loadFiles $cfgfile false $loadedges"
    
    if {[catch {::NeuronVND::loadAttributeData}] } {
        puts "Error with attribute caching"
    }

    # Checking if default rep works
    if {$createrep} {::NeuronVND::createRepArgs}

}

# unified createRep procs
proc ::NeuronVND::createRepArgs {args} {
    variable repselected
    variable styleRep
    variable colorRep
    variable colorID
    #jason's
    variable numberRep
    variable listmodels
    variable selRep
    variable materialRep
    variable showRep
    variable sphereScale
    variable sphereRes
    

    # if given args
    if {[llength $args]} {
        puts "args:$args"

        # new args language
        set auxpos [lsearch $args selection]
        if {$auxpos != -1} {
            puts "selection $auxpos, [lindex $args [expr $auxpos + 1]]"
            set selRep [lindex $args [expr $auxpos + 1]]
        }

        set auxpos [lsearch $args style]
        if {$auxpos != -1} {
            puts "style $auxpos"
            set styleRep [lindex $args [expr $auxpos + 1]]
        }

        set auxpos [lsearch $args material]
        if {$auxpos != -1} {
            set materialRep [lindex $args [expr $auxpos + 1]]
        }

        set auxpos [lsearch $args show]
        if {$auxpos != -1} {
            set showRep [lindex $args [expr $auxpos + 1]]
        }
        
        set auxpos [lsearch $args color]
        if {$auxpos != -1} {
            set content [lindex $args [expr $auxpos + 1]]
            if {$content == "Type"} {
                 set colorRep "Type"
                 set colorID "Type"
            } else {
                 set colorRep "Color"
                 set colorID $content
            }
        }
        set auxpos [lsearch $args num_neurons]
        if {$auxpos != -1} {
            set numberRep [lindex $args [expr $auxpos + 1]]
        }

        puts "selRep $selRep, styleRep $styleRep, materialRep $materialRep, showRep $showRep, colorID $colorID, numberRep $numberRep"
        set repselected [.neuron.fp.systems.rep.main.table.tb index end]

    } elseif {$repselected == "" || $::neuro::nrepList == ""} {    
        # no rep selected, create a default one
        puts "Creating default representation"
        set styleRep soma 
        set colorID Type
        set selRep "all"
        set sphereScale 3
        set sphereRes 5
        set showRep true
        set materialRep Opaque
        set repselected 0
        set numberRep $listmodels(0,neurons)

        # limit crowding in the default preview
        if {[::neuro::cmd_query "num_neurons"] > 10000} {set selRep "stride 5"}
        if {[::neuro::cmd_query "num_neurons"] > 100000} {set selRep "stride 50"}
        if {[::neuro::cmd_query "num_neurons"] > 1000000} {set selRep "stride 500"}

        set repselected [.neuron.fp.systems.rep.main.table.tb index end]
    } else {
        #instead of defining the rep, use the selected to get a copy
        set auxrow [.neuron.fp.systems.rep.main.table.tb get [.neuron.fp.systems.rep.main.table.tb curselection]]
        puts "auxrow: $auxrow"
        if {[llength $auxrow]} {
            lassign $auxrow styleRep colorID numberRep selRep
            set repselected [.neuron.fp.systems.rep.main.table.tb index end]
        }
    }
    
    # main call
    #set repselected [.neuron.fp.systems.rep.main.table.tb index end]
    puts "repselected $repselected, styleRep $styleRep, colorID $colorID, numberRep $numberRep selRep $selRep"
    set repid [::neuro::cmd_create_rep_node_fullsel $styleRep $colorID $materialRep $selRep]
    
    # insert repid details in table
    set rowid [.neuron.fp.systems.rep.main.table.tb insert $repselected [list $styleRep $colorID $numberRep $selRep]]
    # set table curselection and repselected
    .neuron.fp.systems.rep.main.table.tb selection clear 0 end
    .neuron.fp.systems.rep.main.table.tb selection set $rowid
    set repselected [.neuron.fp.systems.rep.main.table.tb curselection]
    # update GUI elements for rep
    ::NeuronVND::updateRepMenu

    # hide rep if status not true
    if {!$showRep} {
       ::neuro::cmd_hide_rep $repid
       .neuron.fp.systems.rep.main.table.tb rowconfigure $rowid -foreground red
       .neuron.fp.systems.rep.main.table.tb rowconfigure $rowid -selectforeground red
    }

}

proc ::NeuronVND::delRep {args} {
    variable repselected

    #set repselected [.neuron.fp.systems.rep.table.tb curselection]
    set repid [lindex $::neuro::nrepList $repselected 0]
    ::neuro::cmd_delete_rep $repid
    .neuron.fp.systems.rep.main.table.tb delete $repselected 
    puts "delRep: selRep=$::NeuronVND::selRep, styleRep=$::NeuronVND::styleRep, colorID=$::NeuronVND::colorID, numberRep=$::NeuronVND::numberRep" 

    .neuron.fp.systems.rep.main.table.tb selection clear 0 end
    #after deletion, select repselected - 1 row in table
    .neuron.fp.systems.rep.main.table.tb selection set [expr $repselected - 1]
    incr repselected -1

}

proc ::NeuronVND::showHideRep {} {
    variable repselected

    #set repselected [.neuron.fp.systems.rep.table.tb curselection]
    set status [.neuron.fp.systems.rep.main.table.tb rowcget $repselected -foreground]
    set repid [lindex $::neuro::nrepList $repselected 0]
    if {$status == "red"} {
        # rep was hidden, show it
        ::neuro::cmd_show_rep $repid
        # update foreground color
        .neuron.fp.systems.rep.main.table.tb rowconfigure $repselected -foreground black
        .neuron.fp.systems.rep.main.table.tb rowconfigure $repselected -selectforeground black
    } else {
        # rep was showing, hide it
        ::neuro::cmd_hide_rep $repid
        # update foreground color
        .neuron.fp.systems.rep.main.table.tb rowconfigure $repselected -foreground red
        .neuron.fp.systems.rep.main.table.tb rowconfigure $repselected -selectforeground red
    }
}

proc ::NeuronVND::updateRepMenu {} {
    variable repselected
    variable styleRep
    variable materialRep
    variable colorRep
    variable colorID
    variable sphereScale
    variable sphereRes
    variable selRep
    variable numberRep

    # get rep details from neuro_read
    set repdetails [lindex $::neuro::nrepList $repselected]
    puts "updateRepMenu: repdetails = $repdetails"
    # make rep top molecule
    mol top [lindex $repdetails 2]
    # idea: when a rep is selected in the table, populate the selection, style and color entry/boxs
    set styleRep [lindex $repdetails 3]
    if {[lindex $repdetails 4] != "Type"} {
        set colorRep "Color"
        set colorID [lindex $repdetails 4]
        grid .neuron.fp.systems.rep.main.def.nb.page1.coloridcb -row 1 -column 1 -sticky news
    } else {
        set colorRep "Type"
        grid remove .neuron.fp.systems.rep.main.def.nb.page1.coloridcb
    }
    set numberRep [lindex $repdetails 8]
    set materialRep [lindex $repdetails 5]
    set selRep [lindex $repdetails 6]
    if {$styleRep == "soma"} {
        set sphereScale [lindex $repdetails 10]
        set sphereRes [lindex $repdetails 11]
    }
    .neuron.fp.systems.rep.main.table.tb selection clear 0 end
    .neuron.fp.systems.rep.main.table.tb selection set $repselected
    puts "updateRepMenu: repselected = $repselected, curselection = [.neuron.fp.systems.rep.main.table.tb curselection]"
    #.neuron.fp.systems.rep.main.sel.entry delete 0 end
    #.neuron.fp.systems.rep.main.sel.entry insert 0 $selRep

    # update variable for connectivity purposes
    variable listOfRepsForConnect
    set listOfRepsForConnect ""
    foreach r [.neuron.fp.systems.rep.main.table.tb get 0 end] {
        lappend listOfRepsForConnect [lindex $r 3]
    }
    .neuron.fp.connect.main.lbl1.cb configure -values $::NeuronVND::listOfRepsForConnect
    .neuron.fp.connect.main.lbl2.cb configure -values $::NeuronVND::listOfRepsForConnect
    # same for activity
    .neuron.fp.spikes.main.lbl1.cb configure -values $::NeuronVND::listOfRepsForConnect
    .neuron.fp.spikes.main.lbl2frame.lbl.cb configure -values $::NeuronVND::listOfRepsForConnect
}

proc ::NeuronVND::editRep {case} {
    variable repselected
    variable styleRep
    variable materialRep
    variable colorRep
    variable colorID
    variable selRep
    variable sphereScale
    variable sphereRes
    variable numberRep

    set t .neuron.fp.systems.rep.main.table.tb

    # testing status progress
    ::NeuronVND::statusBarChanges processing

    # check the selected rep has a different style, get rep details from neuro_read
    set repdetails [lindex $::neuro::nrepList $repselected]
    if {$repdetails == ""} {return}

    # define color to be added to table
    if {$colorRep == "Type"} {set color Type}
    if {$colorRep == "Color"} {set color $colorID}

    switch $case {
        "style" {
            puts "editRep: styleRep = $styleRep"
            if {$styleRep != [lindex $repdetails 3]} {
                ::neuro::cmd_mod_rep_node_fullsel $repselected $styleRep [lindex $repdetails 4] [lindex $repdetails 5] [lindex $repdetails 6]
                .neuron.fp.systems.rep.main.table.tb delete $repselected
                # insert repid details in table
                set rowid [.neuron.fp.systems.rep.main.table.tb insert $repselected [list $styleRep [lindex $repdetails 4] $numberRep [lindex $repdetails 6]]]
                # set table curselection and repselected
                .neuron.fp.systems.rep.main.table.tb selection clear 0 end
                .neuron.fp.systems.rep.main.table.tb selection set $rowid
                set repselected [.neuron.fp.systems.rep.main.table.tb curselection]
                # update GUI elements for rep
                ::NeuronVND::updateRepMenu
            }
        }
        "sel" {
            if {$selRep != [lindex $repdetails 6]} {
                ::neuro::cmd_mod_rep_node_fullsel $repselected [lindex $repdetails 3] [lindex $repdetails 4] [lindex $repdetails 5] $selRep
                .neuron.fp.systems.rep.main.table.tb delete $repselected
                # insert repid details in table
                # now showing a new column, "Neurons"
                set rowid [.neuron.fp.systems.rep.main.table.tb insert $repselected [list [lindex $repdetails 3] [lindex $repdetails 4] $numberRep $selRep]]
                # set table curselection and repselected
                .neuron.fp.systems.rep.main.table.tb selection clear 0 end
                .neuron.fp.systems.rep.main.table.tb selection set $rowid
                set repselected [.neuron.fp.systems.rep.main.table.tb curselection]
                # update GUI elements for rep at every parsed selection, then new data can be accessed from nrepList
                ::NeuronVND::updateRepMenu
                #fetch the most updated variables from the selection
                .neuron.fp.systems.rep.main.table.tb delete $repselected
                set rowid [.neuron.fp.systems.rep.main.table.tb insert $repselected [list [lindex $repdetails 3] [lindex $repdetails 4] $numberRep $selRep]]
                .neuron.fp.systems.rep.main.table.tb selection clear 0 end
                .neuron.fp.systems.rep.main.table.tb selection set $rowid
                set repselected [.neuron.fp.systems.rep.main.table.tb curselection]
            }
        }
        "color" {
            if {$colorID != [lindex $repdetails 4]} {
                ::neuro::cmd_mod_rep_node_fullsel $repselected [lindex $repdetails 3] $colorID [lindex $repdetails 5] [lindex $repdetails 6]
                .neuron.fp.systems.rep.main.table.tb delete $repselected
                # insert repid details in table
                set rowid [.neuron.fp.systems.rep.main.table.tb insert $repselected [list [lindex $repdetails 3] $colorID $numberRep [lindex $repdetails 6]]]
                # set table curselection and repselected
                .neuron.fp.systems.rep.main.table.tb selection clear 0 end
                .neuron.fp.systems.rep.main.table.tb selection set $rowid
                set repselected [.neuron.fp.systems.rep.main.table.tb curselection]
                # update GUI elements for rep
                ::NeuronVND::updateRepMenu
            }
        }
        "material" {
            if {$materialRep != [lindex $repdetails 5]} {
                # update neuro::nrepList
                set ::neuro::nrepList [lreplace $::neuro::nrepList $repselected $repselected [lreplace [lindex $::neuro::nrepList $repselected] 5 5 $materialRep]]
                # changing material through draw command
                # needs to make mol top then call draw material xxxx
                mol top [lindex $repdetails 2]
                draw material $materialRep
            }
        }
        # SPHERE IS NOT WORKING AT THE MOMENT
        "sphere" {
            if {$sphereScale != [lindex $repdetails 10] || $sphereRes != [lindex $repdetails 11]} {
                # create a copy rep with a different style
                ::NeuronVND::createRepArgs
                # delete previous rep
                ::NeuronVND::delRep
            }
        }
    }

    # testing status progress
    ::NeuronVND::statusBarChanges ready
}

proc ::NeuronVND::moveGraphs {dim sign} {
  variable objList
  variable objIndex
  variable movex
  variable movey
  variable movez
  variable aggoffset
  set objid [lindex $objIndex 0]
  if {$objid == ""} {return}
  set numG [llength [graphics $objid list]]
  switch $dim {
    "x" { 
        set val $movex
        if {$sign == "neg"} {set val [expr -1*$val]}
        set offset [list $val 0.0 0.0] 
    }
    "y" { 
        set val $movey
        if {$sign == "neg"} {set val [expr -1*$val]}
        set offset [list 0.0 $val 0.0] 
    }
    "z" { 
        set val $movez
        if {$sign == "neg"} {set val [expr -1*$val]}
        set offset [list 0.0 0.0 $val] 
    }
    "default" {puts "error: dimension must be either x, y or z"}
  }
  # update aggregate offset to save state
  set aggoffset [vecadd $aggoffset $offset]
  display update off
  #this chunk of code was created by jasonks2 as a utility to check different graphics primitives and also translate the geometries
  #new and improved method for searching different geometric primitives drawn in VMD
  for {set i 1} {$i < $numG} {incr i} {
    set prim_type [lindex [graphics $objid info $i] 0]
    switch -glob -- $prim_type {
        "*triangle*" { 
        lassign [graphics $objid info $i] t v1 v2 v3
            # offset v1 v2 v3
        set newv1 [vecadd $v1 $offset]
        set newv2 [vecadd $v2 $offset]
        set newv3 [vecadd $v3 $offset]
        # redraw graphics i
        graphics $objid replace $i
        graphics $objid triangle $newv1 $newv2 $newv3

        } 
         "*cone*" { 
        lassign [graphics $objid info $i] t v1 v2 radius r
        set newv1 [vecadd $v1 $offset]
        set newv2 [vecadd $v2 $offset]
        # redraw graphics i
        graphics $objid replace $i
        graphics $objid $prim_type $newv1 $newv2 $radius $r
        } 
         "*line*" {
        lassign [graphics $objid info $i] t v1 v2 width w
        set newv1 [vecadd $v1 $offset]
        set newv2 [vecadd $v2 $offset]
        # redraw graphics i
        graphics $objid replace $i
        graphics $objid $prim_type $newv1 $newv2 $width $w
        } 
         "*cylinder*" { 
        lassign [graphics $objid info $i] t v1 v2 radius r
        set newv1 [vecadd $v1 $offset]
        set newv2 [vecadd $v2 $offset]
        # redraw graphics i
        graphics $objid replace $i
        graphics $objid $prim_type $newv1 $newv2 $radius $r
        } 
        "*text*" {
        lassign [graphics $objid info $i] t v1 text
        set newv1 [vecadd $v1 $offset]
        # redraw graphics i
        graphics $objid replace $i
        graphics $objid $prim_type $newv1 $text
        }
        default {
        puts "The graphics in this ID selection have a type that is unknown! Please double check graphics type"
        }
        }
  }
  display update on
}

proc ::NeuronVND::rotGraphs {axis sign} {
  variable objList
  variable objIndex
  variable rotarx
  variable rotary
  variable rotarz
  variable aggrot
  variable princ_moved_mol
  variable princ_axes
  variable princ_axes_scale
  variable princ_axes_com
  variable princ_axes_spherelist
  variable xin
  variable yin
  variable zin
  variable draw_go

  set objid [lindex $objIndex 0]
  if {$objid == ""} {return}

  if {$princ_moved_mol == -1} {
    set princ_moved_mol [mol new]
  }
  set numG [llength [graphics $objid list]]
  if {$axis != "x" && $axis != "y" && $axis != "z"} {
    puts "error: axis must be either x, y or z"
    return
  }
  switch $axis {
    "x" { set val $rotarx }
    "y" { set val $rotary }
    "z" { set val $rotarz }
  }
  if {$sign == "neg"} {set val [expr -1*$val]}

  #retrieves vectors of principal axes
  set a1 [lindex $princ_axes 0]
  set a2 [lindex $princ_axes 1]
  set a3 [lindex $princ_axes 2]
  puts "a1 = $a1, a2 = $a2, a3 = $a3"
  #For rotations, move the entire center of mass to the origin and then apply the rotations
  set m_orig_to_com [transoffset $princ_axes_com]
  set m_com_to_orig [transoffset [vecscale -1 $princ_axes_com]]
  #apply the axis rotation incrementally and then apply it to the aggregate rotation matrix
  set aggrot [transmult $aggrot [transaxis $axis $val]]
  puts "aggrot = $aggrot"
  #m_to_user is specifically for the morphology included with translations to origin and back to COM
  set m_rot_around_orig [transmult $m_orig_to_com $aggrot $m_com_to_orig]
  # update aggrot 


  set a1_moved [coordtrans $aggrot $a1]
  set a2_moved [coordtrans $aggrot $a2]
  set a3_moved [coordtrans $aggrot $a3]
  graphics $princ_moved_mol delete all
  graphics $princ_moved_mol color 9
  vmd_draw_vector $princ_moved_mol $princ_axes_com [vecscale $princ_axes_scale $a1_moved]
  graphics $princ_moved_mol color 15
  vmd_draw_vector $princ_moved_mol $princ_axes_com [vecscale $princ_axes_scale $a2_moved]
  graphics $princ_moved_mol color 12
  vmd_draw_vector $princ_moved_mol $princ_axes_com [vecscale $princ_axes_scale $a3_moved]

  draw color 22
  #SPHERE TUBES ARE BROKEN!
  #graphics $princ_moved_mol spheretube "$princ_axes_spherelist" radii 1 drawtubes 0
  
  #coordstrans takes a 4x4 and applies a transformation to each point in the entire sphere_list
  foreach s $princ_axes_spherelist {
    set ts [coordtrans $m_rot_around_orig $s]
    graphics $princ_moved_mol sphere $ts radius 1
    }
  display update on
}


proc ::NeuronVND::revealVars {repdetails} {

    set show [lindex $repdetails 1] 
    set style [lindex $repdetails 3]
    set color [lindex $repdetails 4]
    set material [lindex $repdetails 5]
    set selection [lindex $repdetails 6]
    set num_neurons [lindex $repdetails 8]
    set scale [lindex $repdetails 10] 
    set resolution [lindex $repdetails 11]

    set result "show $show style $style color $color material $material neurons $num_neurons selection {$selection}";#scale $scale resolution $resolution"

    return $result
}

proc ::NeuronVND::visState {mode} {
    variable historyCalls

    set types {
	 {{TCL files} {.tcl}   }
	 {{All Files}        *            }
    }

   # Check ns is a correct namespace

   #################
   
   switch $mode {
      "save" {
         set newpathfile [tk_getSaveFile \
			  -title "Choose file name" \
			  -initialdir [pwd] -filetypes $types]
         if {$newpathfile == ""} {return}
         set fid [open $newpathfile w]
         puts $fid "# Visual Neuronal Dynamics"
         puts $fid "# Visualization State"
         foreach call $historyCalls {
               puts $fid $call
         }
         puts $fid "# List of representations"
         foreach r $neuro::nrepList {
               set s [::NeuronVND::revealVars $r]
               puts $fid "::NeuronVND::createRepArgs $s" 
         }
         
         close $fid  
      }
      "load" {
         set newpathfile [tk_getOpenFile \
			  -title "Choose file name" \
			  -initialdir [pwd] -filetypes $types]
         if {$newpathfile == ""} {return}
         set fid [open $newpathfile r]
         #check this is a multiplot options file
         set line [gets $fid]
         if {[regexp {# Visual Neuronal Dynamics} $line] == 1} {
               source $newpathfile   
         } else {puts "VND) Not a valid state file"}
      }
   } 

}

proc ::NeuronVND::populateTree {} {

    set tv .neuron.fp.systems.info.tv
    # Populate model tree with population
    # file level
    foreach f [::neuro::cmd_query fileset_pop_groups] {
        # pop level
        foreach p [lindex $f 1] {
            set popname [lindex $p 0]
            $tv insert {} end -id $popname -text "population == $popname"
            # group level
            foreach g [lindex $p 1] {
                $tv insert $popname end -id ${popname}_$g -text "group == $g"
                # type level
                foreach t [::neuro::cmd_query node_types_in_group [lindex $f 0] $popname $g] {
                    $tv insert ${popname}_$g end -id ${popname}_${g}_$t -text "type == $t"
                }
            }
        }

    }
}

proc ::NeuronVND::createExampleRep {args} {
    # IDEA: create a temporary rep with selection defined by treeview
    # split str and check length
    set str [split [lindex $args end] _]
    switch [llength $str] {
        "1" {
            set sel "population == [lindex $str 0]"
            puts "# selected: $sel"
        }
        "2" {
            set sel "population == [lindex $str 0] && group == [lindex $str 1]"
            puts "# selected: $sel"
        }
        "3" {
            set sel "population == [lindex $str 0] && group == [lindex $str 1] && type == [lindex $str 2]"
            puts "# selected: $sel"
        }
    }

    ::NeuronVND::createRepArgs style soma selection $sel color yellow

}

proc ::NeuronVND::movieWindow {type} {
    
    # create movie details window
    if {[winfo exists .neuron.moviegui]} {
        set w .neuron.moviegui
        raise $w
        return
    } else {
        set w [toplevel .neuron.moviegui]
        wm resizable $w 1 1
    }
    if {$type == "compartment"} {
        wm title $w "VND Compartment Movie Making"
    } elseif {$type == "spike"} {
        wm title $w "VND Spikes Movie Making"
    }
    wm geometry $w 297x158+650+190
    grid [frame $w.movrec] -row 0 -column 0 -sticky news -padx 1 -pady 2
    set gr1 0
    grid [button $w.movrec.workdirbut -text "Set working directory:" -command {
        set ::NeuronVND::renderWorkDir [tk_chooseDirectory -initialdir "." -title "Choose working directory"]
    }] -row $gr1 -column 0 -sticky news -padx 1 -pady 2 -columnspan 2
    grid [label $w.movrec.workdirlbl -textvariable ::NeuronVND::renderWorkDir] -row $gr1 -column 2 -sticky news -padx 1 -pady 2 -columnspan 2
    incr gr1
    grid [label $w.movrec.filelbl -text "Movie Name:"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2 -columnspan 2
    grid [entry $w.movrec.fileentry -textvariable ::NeuronVND::renderMovFile] -row $gr1 -column 2 -sticky news -padx 1 -pady 2 -columnspan 2
    incr gr1
    grid [label $w.movrec.lbl1 -text "From time:"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
    grid [entry $w.movrec.entry1 -textvariable ::NeuronVND::renderMovTimeFrom -width 8 -justify right] -row $gr1 -column 1 -sticky news -padx 1 -pady 2
    grid [label $w.movrec.lbl2 -text "to:"] -row $gr1 -column 2 -sticky news -padx 1 -pady 2
    grid [entry $w.movrec.entry2 -textvariable ::NeuronVND::renderMovTimeTo -width 8 -justify right] -row $gr1 -column 3 -sticky news -padx 1 -pady 2
    incr gr1
    grid [label $w.movrec.durlbl -text "Movie duration (seconds):"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2 -columnspan 2
    grid [entry $w.movrec.durentry -textvariable ::NeuronVND::renderMovDuration] -row $gr1 -column 2 -sticky news -padx 1 -pady 2 -columnspan 2
    incr gr1
    grid [button $w.movrec.but1 -text "Make movie"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2 -columnspan 2
    grid [button $w.movrec.but2 -text "Abort" -command {set ::NeuronVND::movieAbort 1}] -row $gr1 -column 2 -sticky news -padx 1 -pady 2 -columnspan 2
    incr gr1
    grid [label $w.movrec.plbl -text "Progress:"] -row $gr1 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::progressbar $w.movrec.pbar -variable ::NeuronVND::movieProgressVar] -row $gr1 -column 1 -sticky news -padx 1 -pady 2 -columnspan 3

    set ::NeuronVND::movieProgressVar 0

    if {$type == "compartment"} {
        .neuron.moviegui.movrec.but1 configure -command {
            .neuron.moviegui.movrec.workdirbut configure -state disabled
            .neuron.moviegui.movrec.fileentry configure -state readonly
            .neuron.moviegui.movrec.entry1 configure -state readonly
            .neuron.moviegui.movrec.entry2 configure -state readonly
            .neuron.moviegui.movrec.but1 configure -state disabled
            ::NeuronVND::makeMovie "compartment"
        }
    } elseif {$type == "spike"} {
        .neuron.moviegui.movrec.but1 configure -command {
            .neuron.moviegui.movrec.workdirbut configure -state disabled
            .neuron.moviegui.movrec.fileentry configure -state readonly
            .neuron.moviegui.movrec.entry1 configure -state readonly
            .neuron.moviegui.movrec.entry2 configure -state readonly
            .neuron.moviegui.movrec.but1 configure -state disabled
            ::NeuronVND::makeMovie "spike"
        }
    }
}

proc ::NeuronVND::makeMovie { type } {

    cd $::NeuronVND::renderWorkDir
    # render all frames
    #::neuro::compart_animate_selection_render_ranged $::NeuronVND::compartSel $::NeuronVND::renderMovTimeFrom $::NeuronVND::renderMovTimeTo  \
        $::NeuronVND::compartTimeStride $::NeuronVND::compartStyle $::NeuronVND::compartColor $::NeuronVND::compartMaterial  \
        $::NeuronVND::renderMethod $::NeuronVND::compartRangeMin $::NeuronVND::compartRangeMax $::NeuronVND::renderMovFile \
        .tga $::NeuronVND::compartMolId
    
    # check movie file name does not exist, perhaps code an overwrite file check
    if {[file exists $::NeuronVND::renderMovFile]} {
        puts "Error: movie file name already exists"
        return
    }

    # check movie duration is not 0
    if {$::NeuronVND::renderMovDuration <= 0} {
        puts "Error: duration must be greater that 0"
        return
    }
    
    if {$type == "compartment"} {
        # check input time frames are contained in the data
        if { $::NeuronVND::compartStart > $::NeuronVND::renderMovTimeFrom && 
            $::NeuronVND::renderMovTimeFrom > $::NeuronVND::renderMovTimeTo &&
            $::NeuronVND::renderMovTimeTo > $NeuronVND::compartEnd } {
            puts "Error: wrong time input - values outside of data"
            return
        }
        # loop over time frames, updating the scroll bar
        set ::NeuronVND::movieAbort 0
        set theFrame 0
        set ::NeuronVND::compartTime $::NeuronVND::renderMovTimeFrom
        # define movieProgressVar step
        set stepMovieProgressVar [expr 100 * $::NeuronVND::compartTimeStride / ($::NeuronVND::renderMovTimeTo - $::NeuronVND::renderMovTimeFrom)]
        while {$::NeuronVND::compartTime <= $::NeuronVND::renderMovTimeTo && $::NeuronVND::movieAbort == 0} {
            display update ui

            incr ::NeuronVND::compartTime $::NeuronVND::compartTimeStride
            #display update on
            set fname "$::NeuronVND::renderMovFile.[format %05d $theFrame].tga"
            puts "about to render $fname"
            render $::NeuronVND::renderMethod $fname  
            incr theFrame
            incr ::NeuronVND::movieProgressVar $stepMovieProgressVar        
            
            after $::NeuronVND::compartWaitTime
        }
        set ffmpegTimeStride $::NeuronVND::compartTimeStride
    } elseif {$type == "spike"} {
        # check input time frames are contained in the data
        if { $::NeuronVND::spikeStart > $::NeuronVND::renderMovTimeFrom && 
            $::NeuronVND::renderMovTimeFrom > $::NeuronVND::renderMovTimeTo &&
            $::NeuronVND::renderMovTimeTo > $NeuronVND::spikeEnd } {
            puts "Error: wrong time input - values outside of data"
            return
        }
        # loop over time frames, updating the scroll bar
        set ::NeuronVND::movieAbort 0
        set theFrame 0
        set ::NeuronVND::spikeTime $::NeuronVND::renderMovTimeFrom    
        # define movieProgressVar step
        set stepMovieProgressVar [expr 100 * $::NeuronVND::spikeTimeStride / ($::NeuronVND::renderMovTimeTo + 1 - $::NeuronVND::renderMovTimeFrom)]
        while {$::NeuronVND::spikeTime <= $::NeuronVND::renderMovTimeTo && $::NeuronVND::movieAbort == 0} {
            display update ui

            incr ::NeuronVND::spikeTime $::NeuronVND::spikeTimeStride
            #display update on
            set fname "$::NeuronVND::renderMovFile.[format %05d $theFrame].tga"
            puts "about to render $fname"
            render $::NeuronVND::renderMethod $fname  
            incr theFrame
            incr ::NeuronVND::movieProgressVar $stepMovieProgressVar        
            
            after $::NeuronVND::spikeWaitTime
        }                   
        set ffmpegTimeStride $::NeuronVND::spikeTimeStride
    }

    # run ffmpeg
    if {$::NeuronVND::renderVideoProc == "ffmpeg" && $::NeuronVND::movieAbort == 0} {
        set totalFrames [expr ($::NeuronVND::renderMovTimeTo + 1 - $::NeuronVND::renderMovTimeFrom)/$ffmpegTimeStride]
        set oneOverTimeForEachImage [expr  double($totalFrames / $::NeuronVND::renderMovDuration)]
        puts "totalFrames=$totalFrames, renderMovDuration=$::NeuronVND::renderMovDuration, oneOverTimeForEachImage=$oneOverTimeForEachImage"
        ::ExecTool::exec $::NeuronVND::renderVideoProc -hide_banner -loglevel error -framerate $oneOverTimeForEachImage -i ${::NeuronVND::renderMovFile}.%05d.tga -vcodec libx264 -r 30 -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2" -pix_fmt yuv420p $::NeuronVND::renderMovFile
    }
    # remove img?
    if {$::NeuronVND::renderDelImgBool} {
        file delete {*}[glob ${::NeuronVND::renderMovFile}*tga]
    }
}

proc ::NeuronVND::statusBarChanges { args } {
    # this proc controls the status label ::NeuronVND::statusLabel and progress bar
    # first version is on/off, not computing time remaining

    switch $args {
        "ready" {
            set ::NeuronVND::statusLabel "Ready"
            set ::NeuronVND::statusPbarVal 0
        }
        "loading" {
            set ::NeuronVND::statusLabel "Loading"
        }
        "processing" {
            set ::NeuronVND::statusLabel "Processing"
        }
    }
}

proc ::NeuronVND::goto {args} {
    set ::NeuronVND::spikeTime [lindex $args 1]
}

proc ::NeuronVND::rasterWindow { } {
    variable listOfRepsForConnect
    variable listOfPopsForSpikes
    # create window to define options for the raster plot
    if {[winfo exists .neuron.rastergui]} {
        set w .neuron.rastergui
        raise $w
        return
    } else {
        set w [toplevel .neuron.rastergui]
        wm resizable $w 1 1
    }
    wm title $w "VND Raster Plot Options"
    
    grid [frame $w.main] -row 0 -column 0 -sticky news -padx 1 -pady 2
    set gr 0
    grid [labelframe $w.main.lbl1 -text "Selection of neurons 1 (required)" -labelanchor nw ] -row $gr -column 0 -sticky news  -padx 1 -pady 2
    grid [label $w.main.lbl1.pop -text "Select population:"] -row 0 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $w.main.lbl1.cbpop -width 40 -values $listOfPopsForSpikes -state readonly -textvariable ::NeuronVND::spikePop1] -row 0 -column 1 -columnspan 4 -padx 1 -pady 2
    grid [label $w.main.lbl1.sel -text "Select existing selection:"] -row 1 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $w.main.lbl1.cb -width 40 -values $listOfRepsForConnect -state readonly -textvariable ::NeuronVND::spikeSel1] -row 1 -column 1 -columnspan 4 -padx 1 -pady 2
    incr gr
    grid [label $w.main.lbl1.colorlbl -text "Color by:"] -row 2 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $w.main.lbl1.colorcb -width 40 -values "Type" -state readonly -textvariable defineVariable] -row 2 -column 1 -columnspan 4 -padx 1 -pady 2
    incr gr
    grid [button $w.main.but1 -text "Make Raster Plot" -command {::NeuronVND::rasterPlot}] -row $gr -column 0 -sticky news -padx 1 -pady 2

}

proc ::NeuronVND::rasterPlot { } {
    variable spikeEnd
    variable spikePlothandle
    # Create a raster plot for spike activity data using multiplot
    # separate series using type and colorcode accordingly

    #set ::NeuronVND::spikeEnd [expr ceil([lindex $::neuro::spikeHash(spikeList,$::NeuronVND::spikePop1) end 1])]
    
    #set xdata {}
    #for {set i $::NeuronVND::spikeStart} {$i <= $::NeuronVND::spikeEnd} {incr i} {lappend xdata $i}

    # nodeids for selection
    set nodeIDList [::neuro::parse_full_selection_string "$::NeuronVND::spikeSel1 && population == $::NeuronVND::spikePop1" node]
    
    # in this first version, we color by type only
    # query how many types there are in that population
    set typeList [lsort -unique [::neuro::cmd_query node_list_attrib_values type $nodeIDList]]
    set timeSeriesData {}
    # for each type, find the nodeids and then search the spikeHash for activity data
    foreach t $typeList {
        set auxNodeID [::neuro::parse_full_selection_string "$::NeuronVND::spikeSel1 && type == $t && population == $::NeuronVND::spikePop1" node]
        set auxY {}; set auxX {}

        # create a timeseries for each type in typeList
        foreach p $::neuro::spikeHash(spikeList,$::NeuronVND::spikePop1) {
            if {[lsearch -exact $auxNodeID [lindex $p 0]]!=-1} {
                lappend auxY [lindex $p 0]
                lappend auxX [expr round([lindex $p 1])]
            } 
        }
        lappend timeSeriesData [list $auxY $auxX]
    }

    # define multiplor with first set of data, using colors from VMD 
    set colorList {blue red gray orange yellow tan silver green gray pink cyan purple lime mauve ochre iceblue black}
    # given the type, apply % 32 to get the color from colorList index as vnd_read does
    set colorForData [lindex $colorList [expr [lindex $typeList 0] % 32]] ;# first one outside the loop
    puts $colorForData
    set spikePlothandle [multiplot -x [lindex $timeSeriesData 0 1] -y [lindex $timeSeriesData 0 0] -nolines -xmin 0 -xmax $::NeuronVND::spikeEnd -xlabel "Time (ms)" -marker square -radius 2 -fillcolor white -linecolor $colorForData -title "Neuronal Spike Activity" -callback ::NeuronVND::goto -legend "Type [lindex $typeList 0]"]
    # add the rest of the data to the plot
    for {set i 1} {$i < [llength $typeList]} {incr i} {
        set colorForData [lindex $colorList [expr [lindex $typeList $i] % 32]] ;# rest inside the loop
        puts $colorForData
        $spikePlothandle add [lindex $timeSeriesData $i 1] [lindex $timeSeriesData $i 0] -callback ::NeuronVND::goto -fillcolor white -linecolor $colorForData -nolines -marker square -radius 2 -legend "Type [lindex $typeList $i]"
    }
    # finally plot all 
    $spikePlothandle configure -ylabel "NodeID" -ymax 300 -ymin 0 -xmin 0 -ysize 500 -xsize 700
    $spikePlothandle replot
    #set black color to gray, since black is most common background
    #if {$c ==16} {set c 2}
    
}

# Display frame marker in plot at given frame
proc ::NeuronVND::display_marker { f } {
  # testing adding marker to activity plot
    set plothandle $::NeuronVND::spikePlothandle
    if {[info exists plothandle]} {
      # detect if plot was closed
      if [catch {$plothandle getpath}] {
      unset plothandle
      } else {
        # we tinker a little with Multiplot's internals to get access to its Tk canvas
        # necessary because Multiplot does not expose an interface to draw & delete
        # objects without redrawing the whole plot - which takes too long for this
        set ns [namespace qualifiers $plothandle]
        set xmin [set ${ns}::xmin]
        set xmax [set ${ns}::xmax]
        # Move plot boundaries if necessary
        if { $f < $xmin } {
            set xmax [expr { $xmax + $f - $xmin }]
            set xmin $f
            $plothandle configure -xmin $xmin -xmax $xmax -plot
        }
        if { $f > $xmax } {
            set xmin [expr { $xmin + $f - $xmax }]
            set xmax $f
            $plothandle configure -xmin $xmin -xmax $xmax -plot
        }
        set y1 [set ${ns}::yplotmin]
        set y2 [set ${ns}::yplotmax]
        set xplotmin [set ${ns}::xplotmin]
        set scalex [set ${ns}::scalex]
        set x [expr $xplotmin+($scalex*($f-$xmin))]

        set canv "[set ${ns}::w].f.cf"
        $canv delete frame_marker
        $canv create line  $x $y1 $x $y2 -fill blue -tags frame_marker
      }
    }
}


#gui window
proc ::NeuronVND::alignmentToolWindow {} { 
    variable alignment_population
    variable listOfRepsForConnect
    variable ID
        if {[winfo exists .neuron.aligntoolgui]} {
        set w .neuron.aligntoolgui
        raise $w
        return
    } else {
        set w [toplevel .neuron.aligntoolgui]
        wm resizable $w 1 1
    }

    wm title $w "Prototype Principal Axes Alignment Tool"
    grid [frame $w.main] -row 0 -column 0 -sticky news -padx 2 -pady 1
    set gr 0
    grid [labelframe $w.main.label1 -text "Selection Neurons for Alignment" -labelanchor nw ] -row $gr -column 0 -sticky news -padx 2 -pady 1
    grid [label $w.main.label1.pop -text "Select population:"] -row 0 -column 0 -sticky news -padx 1 -pady 2
    grid [ttk::combobox $w.main.label1.dropdown -width 50 -values $::NeuronVND::listOfRepsForConnect -state readonly -textvariable ::NeuronVND::alignment_population] -row 0 -column 1 -columnspan 2 -padx 2 -pady 1
    bind $w.main.label1.dropdown <<ComboboxSelected>> {
        set text [%W get]
        get_population_ID $text
        #::NeuronVND::draw_box
        %W selection clear
    }    

    incr gr
    #grid [label $w.main.label1.textlabel -text "CURRENT ID OF SELECTION"] -row 1 -column 0 -sticky news -padx 2 -pady 1
    #grid [entry $w.main.label1.textentry -textvariable ::Alignment::alignment_populationID] -row 1 -column 1 -sticky news -padx 2 -pady 1
    incr gr
    grid [button $w.main.but1 -text "Draw Axes" -command {::NeuronVND::draw_axis}] -row 2 -column 0 -sticky news -padx 2 -pady 1
    incr gr
    grid [label $w.main.label1.textlabel2 -text "x"] -row $gr -column 0 -sticky news -padx 2 -pady 1
    grid [entry $w.main.label1.textentry2 -textvariable ::NeuronVND::xin] -row $gr -column 1 -sticky news -padx 2 -pady 1
    incr gr
    grid [label $w.main.label1.textlabel3 -text "y"] -row $gr -column 0 -sticky news -padx 2 -pady 1
    grid [entry $w.main.label1.textentry3 -textvariable ::NeuronVND::yin] -row $gr -column 1 -sticky news -padx 2 -pady 1
    incr gr
    grid [label $w.main.label1.textlabel4 -text "z"] -row $gr -column 0 -sticky news -padx 2 -pady 1
    grid [entry $w.main.label1.textentry4 -textvariable ::NeuronVND::zin] -row $gr -column 1 -sticky news -padx 2 -pady 1
    #grid [button $w.main.but2 -text "Remove Axes" -command {::NeuronVND::hide_axis}] -row $gr -column 0 -sticky news -padx 2 -pady 1
    incr gr 
    grid [button $w.main.but3 -text "Align to x, y, z" -command {::NeuronVND::jump}] -row $gr -column 0 -sticky news -padx 2 -pady 1
    incr gr
    grid [button $w.main.but2 -text "Delete" -command {::NeuronVND::delete}] -row $gr -column 0 -sticky news -padx 2 -pady 1
    #grid [button $w.main.but4 -text "Alignment: Revert" -command {}] -row $gr -column 0 -sticky news -padx 2 -pady 1
}

#this draws the principal axis (3 in total)
proc ::NeuronVND::draw_axis {} {

    variable sel_string
    variable x_array
    variable y_array
    variable z_array
    variable size_array
    variable state
    
    set ::NeuronVND::objList ""
    set ::NeuronVND::objIndex ""
    variable principal_axis_mol


    if ![catch {molinfo $principal_axis_mol get name}] {return}
    set principal_axis_mol [mol new]

    set name [mol rename $principal_axis_mol "Principal Axis"]

    set sel_string $::NeuronVND::alignment_population

    set ID $::NeuronVND::alignment_populationID

    #if soma is drawn use standard node_list_attrib_query, else use the morpho_details query since a morphology is drawn
    if {[lindex [lindex ::neuro::nrepList $ID] 3] == "soma"} {
    set x_array [::neuro::cmd_query node_list_attrib_values x [::neuro::parse_full_selection_string $sel_string node]]
    set y_array [::neuro::cmd_query node_list_attrib_values y [::neuro::parse_full_selection_string $sel_string node]]
    set z_array [::neuro::cmd_query node_list_attrib_values z [::neuro::parse_full_selection_string $sel_string node]]

    set size_array [llength $x_array]

    #calculate mass. Initiliaze mass array of each neuron.
    ::Orient::sel_mass $size_array

    #actually draw the principal access 
    vmd_draw_principalaxes $x_array $y_array $z_array $principal_axis_mol
    } else {
        set output_header [::neuro::cmd_query morpho_details -no_coords "$sel_string && has_morpho == True"]
        set nsize [llength $output_header]
        set output [::neuro::cmd_query morpho_details -moved_coords "$sel_string && has_morpho == True"]
        puts "nsize is $nsize"
        

        set globalNodeID [lindex [lindex $output 0] 0]

        set x_array ""
        set y_array ""
        set z_array ""

        #copying the data from ::neuro:: to ::Orient:: vars
        set morph_spherelist_combo ""

        for {set i 0} {$i < $nsize} {incr i} {
            foreach coord [lindex [lindex $output $i] 3] {
                lappend morph_spherelist_combo $coord
                foreach {x y z} $coord {
                    lappend x_array $x
                    lappend y_array $y
                    lappend z_array $z
                    }
                }
             }
        #share spheres for rotGraphs preview
        set ::NeuronVND::princ_axes_spherelist $morph_spherelist_combo
        set size_array [llength $x_array]

        puts "length of x_array [llength $x_array]"
        puts "length of size_array [llength $size_array]"
        ::Orient::sel_mass $size_array
        vmd_draw_principalaxes $x_array $y_array $z_array $principal_axis_mol      
    }
    #fill Mariano's objlist #haky way
    lappend ::NeuronVND::objList [list $principal_axis_mol $name]
    set ::NeuronVND::objIndex [lindex $::NeuronVND::objList 0]
}

#toggles axes on and off
proc ::NeuronVND::delete {} {
    variable principal_axis_mol
    variable princ_moved_mol
    mol delete $principal_axis_mol
    mol delete $princ_moved_mol
}

#used to jump a aggrot matrix to another aligned matrix
proc ::NeuronVND::jump {} {
  variable objList
  variable objIndex
  variable rotarx
  variable rotary
  variable rotarz
  variable aggrot
  variable princ_moved_mol
  variable princ_axes
  variable princ_axes_scale
  variable princ_axes_com
  variable princ_axes_spherelist
  variable xin
  variable yin
  variable zin
  variable draw_go

  set objid [lindex $objIndex 0]
  if {$objid == ""} {return}

  if {$princ_moved_mol == -1} {
    set princ_moved_mol [mol new]
  }
  set numG [llength [graphics $objid list]]

  set a1 [lindex $princ_axes 0]
  set a2 [lindex $princ_axes 1]
  set a3 [lindex $princ_axes 2]
  puts "a1 = $a1, a2 = $a2, a3 = $a3"

      set user_target [list $xin $yin $zin]

      set m1 [transvecinv $a1]
      set m2 [transvec $user_target]

      set m_orig_to_com [transoffset $princ_axes_com]
      set m_com_to_orig [transoffset [vecscale -1 $princ_axes_com]]

      #m_to_user is specifically for the morphology included with translations to origin and back to COM
      set m_to_user [transmult $m_orig_to_com $m2 $m1 $m_com_to_orig]
      set aggrot [transmult $m2 $m1]

      set a1_moved [coordtrans $aggrot $a1]
      set a2_moved [coordtrans $aggrot $a2]
      set a3_moved [coordtrans $aggrot $a3]

      graphics $princ_moved_mol delete all
      graphics $princ_moved_mol color 9
      vmd_draw_vector $princ_moved_mol $princ_axes_com [vecscale $princ_axes_scale $a1_moved]
      graphics $princ_moved_mol color 15
      vmd_draw_vector $princ_moved_mol $princ_axes_com [vecscale $princ_axes_scale $a2_moved]
      graphics $princ_moved_mol color 12
      vmd_draw_vector $princ_moved_mol $princ_axes_com [vecscale $princ_axes_scale $a3_moved]

      draw color 22
      foreach s $princ_axes_spherelist {
      set ts [coordtrans $m_to_user $s]
      graphics $princ_moved_mol sphere $ts radius 1
      }
  display update on
}

#utility function to get the ID of a neuronal selection
proc get_population_ID {population} {
    if {$population == ""} {
        puts "population error"
        set ::NeuronVND::alignment_populationID "null"
        return ::NeuronVND::alignment_populationID
    }
    variable alignment_populationID
    set alignment_population $population
    foreach elem $::neuro::nrepList {
        set comp "[lindex $elem 6]"
        if {[string equal $comp $alignment_population]} {
            puts "Now returning ID of selected population"
            set ::NeuronVND::alignment_populationID [lindex $elem 0]
        }
    }
    return $::NeuronVND::alignment_populationID
}


proc ::NeuronVND::resetVND {} {

    # eliminate info from population tree
    # file level
    foreach f [::neuro::cmd_query fileset_pop_groups] {
        # pop level
        foreach p [lindex $f 1] {
            set popname [lindex $p 0]
            .neuron.fp.systems.info.tv delete $popname
        }
    }

    ::NeuronVND::initialize

    # eliminate info in tables
    .neuron.fp.systems.main.tb delete 0 end
    .neuron.fp.systems.rep.main.table.tb delete 0 end

    foreach m [molinfo list] {mol delete $m}

}

proc ::NeuronVND::exit {} {
    # prompt exit confirmation
    set answer [tk_messageBox -message "Do you want to quit VND?" -type yesno -title "Closing VND" -icon info -parent $::NeuronVND::topGui]
    if {$answer == "no"} {
        return
    }
    destroy .neuron

    trace remove variable ::NeuronVND::spikeTime write {::NeuronVND::animateSpike}
    trace remove variable ::NeuronVND::compartTime write {::NeuronVND::animatecompart}


    # Trying to quit the whole VND/VMD program from here
    # but when using "exit" or "quit" it prompts 'bad window path name' error on .neuron
    catch {quit}

}

