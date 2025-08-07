##
## RMSD Visualizer 1.1
##
## $Id: rmsdvt-gui.tcl,v 1.8 2022/07/04 23:57:26 johns Exp $
##
## VMD plugin (Tcl extension) for calculating and visualizing RMSD and RMSF calculations
##
## Authors: Anssi Nurminen, Sampo Kukkurainen, Laurie S. Kaguni, Vesa P. Hytönen
## Institute of Biomedical Technology
## University of Tampere
## Tampere, Finland
## and
## BioMediTech, Tampere, Finland
## 30-01-2012 
##
## email: anssi.nurminen_a_uta.fi
##
##

#
# Create the window and initialize data structures
# Note: Variables that start with a lower case 'i' are global within this namespace
#
proc ::Rmsdvt::rmsdvt { args } {
    
  # Traced global variables
  global vmd_trajectory_read
  global vmd_initialize_structure      
    
  #GUI Window  
  variable iW
  variable m
  variable t
    
  # Variables for storing GUI elements data
  variable iSelMolId
  variable iSelMolFrames
  
  variable iAtomSelectionModifiers
  
  # GUI Trajectory box variables, iTraj
  variable iTrajOptions
  
  # General settings array
  variable iSettings
  
  # Variables for storing results, iRes
  variable iResListboxArray 
  
  
  
  ##
  ## Set up Window
  ##
  
  # If already initialized, just turn on
  if { [winfo exists .rmsdvt] } {

    catch {destroy $iW}    
    set refreshed 1

    #Rmsdvt::RefreshMolecules
    #wm deiconify $iW    
    #return
  }

  set iW [toplevel ".rmsdvt"]
  wm title $iW "RMSD Visualizer"
  wm iconname $iW "RMSD Visualizer"
  wm resizable $iW 0 0
  bind $iW <Destroy> [namespace code TheEnd]
  
  #wm protocol $iW WM_DELETE_WINDOW ::Rmsdvt::destroy
  #wm protocol $iW WM_DELETE_WINDOW [namespace code hallo]
  
  #puts "args: $::argv0"
  #puts "infoargs: [info args ::Rmsdvt::rmsdvt]"
  #puts "script: [info script]"
  #puts "hostname: [info hostname]"
  
  # Get plugin folder for help html file
  
  set help_file [join [list "file://" $::env(RMSDVTDIR) "/documentation/" "index.html"] ""]
  #set plugin_folder [string range $::argv0 0 [string last "/" $::argv0]]
  #set plugin_folder [join [list "file://" $plugin_folder "plugins/noarch/tcl/rmsdvt1.1/index.html"] ""]
  #puts $plugin_folder
  
  #
  # Outlook
  #  

  option add *rmsdvt.*borderWidth 1
  option add *rmsdvt.*Button.padY 0
  option add *rmsdvt.*Menubutton.padY 0  
  option add *tearOff 0
  
  
  ##
  ## Menubar
  ##

  menu $iW.menubar
  $iW configure -menu $iW.menubar
  set m $iW.menubar

  #
  # File
  #

  menu $m.file
  $m add cascade -menu $m.file -label File -underline 0
  
    
  $m.file add command -label "Save heatmap data As..." -command "[namespace current]::SaveDataBrowse summary" -underline 0
  $m.file add command -label "Reset settings to default" -command "[namespace current]::SaveDataBrowse summary" -underline 0  
  $m.file add command -label "Save current settings" -command "[namespace current]::SaveDataBrowse summary" -underline 0  
  
  menu $m.file.load_atomsel
  $m.file add cascade -menu $m.file.load_atomsel -underline 5 -label "Load Atom Selection..." -underline 0
  

    
  $m.file add command -label "Save Atom Selection String" -command "[namespace current]::AddSavedAtomSelections" -underline 0  
  $m.file add command -label "Edit Saved Atom Selections" -command "[namespace current]::EditSavedAtomSelections" -underline 0  
  
  $m.file entryconfigure 0 -state disabled
  $m.file entryconfigure 1 -state disabled
  $m.file entryconfigure 2 -state disabled
  

  bind $m.file <1> { ::Rmsdvt::PopulateSavedAtomSelections }  
  #[namespace current]::PopulateSavedAtomSelections
  
  #$iW.menubar.file.menu entryconfigure 2 -state disabled
  #$iW.menubar.file.menu entryconfigure 3 -state disabled
  #$iW.menubar.file.menu entryconfigure 4 -state disabled
  
  #
  # Options
  #

  menu $m.options
  $m add cascade -menu $m.options -label Options -underline 0
  
  menu $m.options.hm_settings
  $m.options add cascade -menu $m.options.hm_settings -underline 0 -label "Heatmap plot..." 
  $m.options.hm_settings add radiobutton -label "Plot resids in atom selection" -variable [namespace current]::iSettings(heatmap) -value "resid"
  $m.options.hm_settings add radiobutton -label "Plot residues in atom selection" -variable [namespace current]::iSettings(heatmap) -value "residue"
  $m.options.hm_settings add radiobutton -label "Plot resid backbone atoms in atom selection" -variable [namespace current]::iSettings(heatmap) -value "backbone"
  $m.options.hm_settings add radiobutton -label "Plot residue backbone atoms in atom selection" -variable [namespace current]::iSettings(heatmap) -value "backbone2"
  $m.options.hm_settings add radiobutton -label "Plot resid sidechain atoms in atom selection" -variable [namespace current]::iSettings(heatmap) -value "sidechain"
  $m.options.hm_settings add radiobutton -label "Plot residue sidechain atoms in atom selection" -variable [namespace current]::iSettings(heatmap) -value "sidechain2"
  $m.options.hm_settings add radiobutton -label "Plot every atom in atom selection" -variable [namespace current]::iSettings(heatmap) -value "atom"
  
  menu $m.options.bbdef
  $m.options add cascade -menu $m.options.bbdef -underline 0 -label "Backbone def..." -underline 0
  $m.options.bbdef add radiobutton -label "C CA N" -variable [namespace current]::iSettings(backbone) -value "C CA N"
  $m.options.bbdef add radiobutton -label "C CA N O" -variable [namespace current]::iSettings(backbone) -value "C CA N O"
  $m.options.bbdef add radiobutton -label "CA only" -variable [namespace current]::iSettings(backbone) -value "CA"
  
  menu $m.options.plot
  $m.options add cascade -menu $m.options.plot -underline 0 -label "2D Plot settings..." 
  $m.options.plot add radiobutton -label "Multiplot (all)" -variable [namespace current]::iSettings(2dplot) -value "multiplot"
  $m.options.plot add radiobutton -label "Xmgrace (Unix)" -variable [namespace current]::iSettings(2dplot) -value "xmgrace"
  $m.options.plot add radiobutton -label "MS Excel (Windows)" -variable [namespace current]::iSettings(2dplot) -value "excel"
  
  # TODO implement using other 2D plotters
  $m.options.plot entryconfigure 1 -state disabled
  $m.options.plot entryconfigure 2 -state disabled
  
  $m.options add command -label "Show atom selection units" -command "[namespace current]::PrintSelectedUnits"
  
  #
  # Result
  #

  menu $m.result
  $m add cascade -menu $m.result -label Result -underline 0
  
  
  $m.result add command -label "Plot Heatmap" -command "[namespace current]::CalculateHeatmapThroughTrajectory" -underline 0
  $m.result add command -label "Plot 2D" -command "[namespace current]::PlotUsingMultiplot" -underline 0
  
  $m.result add command -label "Remove" -command "[namespace current]::RemoveSelectedResults" -underline 0
  
  menu $m.result.heatmap
  $m.result add cascade -menu $m.result.heatmap -underline 0 -label "Heatmap..." 
  $m.result.heatmap add command -label "Save data to file..." -command "[namespace current]::SaveHeatmapResultsToFile"
  $m.result.heatmap add command -label "Set Y-label" -command "[namespace current]::HeatmapConfig ylabel"
  $m.result.heatmap add command -label "Set X-label" -command "[namespace current]::HeatmapConfig xlabel"
  $m.result.heatmap add command -label "Set X-step" -command "[namespace current]::HeatmapConfig xstep"
  
  $m.result add command -label "Show selected units" -command "[namespace current]::PrintSelectedUnits 1"
  
  #
  # Help
  #

  menu $m.help
  $m add cascade -menu $m.help -label Help -underline 0

  $m.help add command -label "About" -command [namespace current]::HelpAbout
  $m.help add command -label "Help..." -command "vmd_open_url [string trimright [vmdinfo www] /]/plugins/rmsdvt"
  
  
  ##
  ## Window contents
  ##

  frame $iW.top
  set t $iW.top
  grid $t -sticky news -column 0 -row 0 -sticky news 

  grid columnconfigure $iW 0 -weight 1
  grid columnconfigure $t 0 -weight 1
  grid rowconfigure $t 0 -weight 1
  
  
  #
  # Molecule selection
  #

  labelframe $t.molsel -text "Molecule" -relief ridge -bd 2 -padx 2 -pady 2
  grid $t.molsel -in $t -column 0 -row 0 -sticky nwes
  grid columnconfigure $t.molsel 0 -weight 1


  ttk::combobox $t.molsel.combo -state readonly -width 22 -values [list]
  bind $t.molsel.combo <<ComboboxSelected>> { ::Rmsdvt::SetSelectedMoleculeId }
  button $t.molsel.update -text "Refresh" -width 7 -relief raised -command [namespace current]::RefreshMolecules -bd 2  

  grid $t.molsel.combo -sticky news -column 0 -row -0 -padx 1 -pady 5
  grid $t.molsel.update -sticky e -column 1 -row 0 -padx 1 -pady 5
     
  ##
  ## Atom Selection textedit
  ##

  labelframe $t.sels -text "Atom Selection" -relief ridge -bd 2 
  grid $t.sels -in $t -column 0 -row 1 -sticky nwes
  text $t.sels.sel -height 4 -width 33 -highlightthickness 0 -selectborderwidth 0 -exportselection yes -wrap word -relief sunken -bd 1  
  $t.sels.sel insert end "protein"

  grid $t.sels.sel -sticky news -padx 2 -pady 2
  grid rowconfigure $t.sels 0 -weight 1
  grid columnconfigure $t.sels 0 -weight 1
    
  
  #
  # Atom Selection modifiers
  #

  labelframe $t.mods -text "Atom Selection Modifiers" -relief ridge -bd 2 
  grid $t.mods -in $t -column 0 -row 2 -sticky nwes
  
  checkbutton $t.mods.bb -text "Backbone" -variable [namespace current]::iAtomSelectionModifiers(backbone) -command "[namespace current]::SelectionModifiersChange backbone"
  checkbutton $t.mods.tr -text "Trace" -variable [namespace current]::iAtomSelectionModifiers(trace) -command "[namespace current]::SelectionModifiersChange trace"
  checkbutton $t.mods.noh -text "noH" -variable [namespace current]::iAtomSelectionModifiers(noh) -command "[namespace current]::SelectionModifiersChange noh"
  grid $t.mods.bb $t.mods.tr $t.mods.noh -sticky w 

  


  ##
  ## Trajectory Options
  ##
  
  labelframe $t.traj -text "Trajectory" -relief ridge -bd 2 
  grid $t.traj -sticky news
    
  set row -1
  
 
  # - FRAMES FROM
  set row [expr $row + 1]
  checkbutton $t.traj.fr_checkbox -variable [namespace current]::iTrajOptions(frames_checkbox) -command [namespace current]::RefreshTrajectoryOptions
  label $t.traj.fr_label_from -text "Frames from:"
  spinbox $t.traj.fr_from -width 5 -from 0 -to 100 -textvariable [namespace current]::iTrajOptions(frames_from)
  label $t.traj.fr_label_to -text "to:"
  spinbox $t.traj.fr_to -width 5 -from 0 -to 100 -textvariable [namespace current]::iTrajOptions(frames_to)
  
  bind $t.traj.fr_from <Return> { ::Rmsdvt::ValidateSpinbox %W from}
  bind $t.traj.fr_from <FocusOut> { ::Rmsdvt::ValidateSpinbox %W from}
  bind $t.traj.fr_to <Return> { ::Rmsdvt::ValidateSpinbox %W to}
  bind $t.traj.fr_to <FocusOut> { ::Rmsdvt::ValidateSpinbox %W to}
  
  grid $t.traj.fr_checkbox -column 0 -row $row
  grid $t.traj.fr_label_from -column 1 -row $row -sticky w
  grid $t.traj.fr_from -column 2 -row $row
  grid $t.traj.fr_label_to -column 3 -row $row
  grid $t.traj.fr_to -column 4 -row $row  
  
  #$t.traj.fr_checkbox configure -state disabled
  $t.traj.fr_label_from configure -state disabled
  $t.traj.fr_from configure -state disabled
  $t.traj.fr_label_to configure -state disabled
  $t.traj.fr_to configure -state disabled
  
  
  # - STEP
  set row [expr $row + 1]
  checkbutton $t.traj.step_checkbox -variable [namespace current]::iTrajOptions(step_checkbox) -command [namespace current]::RefreshTrajectoryOptions    
  label $t.traj.step_label -text "Step size:"
  spinbox $t.traj.step_spin -width 5 -from 0 -to 100 -textvariable [namespace current]::iTrajOptions(step_size)
  
  bind $t.traj.step_spin <Return> { ::Rmsdvt::ValidateSpinbox %W from}
  bind $t.traj.step_spin <FocusOut> { ::Rmsdvt::ValidateSpinbox %W from}
  
  grid $t.traj.step_checkbox -column 0 -row $row
  grid $t.traj.step_label -column 1 -row $row -sticky w
  grid $t.traj.step_spin -column 2 -row $row
   
  #$t.traj.step_checkbox configure -state disabled
  #$t.traj.step_label configure -state disabled
  $t.traj.step_spin configure -state disabled
  
  # Set in Top
  grid $t.traj -in $t -column 1 -row 0
    
  
  
  
  ##
  ## Reference Options
  ##
  
  labelframe $t.ref -text "Reference" -relief ridge -bd 2 
  grid $t.ref -sticky n
    
  grid columnconfigure $t.ref 3 -weight 1
  grid rowconfigure $t.ref 1 -weight 1
  set row -1  
    
  
  # - Reference Molecule
  set row [expr $row + 1]
  label $t.ref.mollabel -text "Molecule ID:  "
  spinbox $t.ref.molspin -width 5 -textvariable [namespace current]::iTrajOptions(ref_mol) -values [list "self"] -command [namespace current]::RefreshTrajectoryOptions
  #bind $t.ref.molspin <Return> { ::Rmsdvt::ValidateSpinbox %W from; ::Rmsdvt::RefreshTrajectoryOptions }
  #bind $t.ref.molspin <FocusOut> { ::Rmsdvt::ValidateSpinbox %W from; ::Rmsdvt::RefreshTrajectoryOptions }
  bind $t.ref.molspin <Return> { ::Rmsdvt::RefreshTrajectoryOptions }
  bind $t.ref.molspin <FocusOut> { ::Rmsdvt::RefreshTrajectoryOptions }
  
  grid $t.ref.mollabel -column 1 -row $row -sticky w
  grid $t.ref.molspin -column 2 -row $row -sticky w -columnspan 2
  
  
  # - Reference Frame
  set row [expr $row + 1]
  radiobutton $t.ref.rsel_frame -variable [namespace current]::iTrajOptions(ref_selection) -value 0 -command [namespace current]::SetRMSFLabelState
  label $t.ref.reflabel -text "Frame:"
  spinbox $t.ref.refspin -width 5 -from 0 -to 100 -textvariable [namespace current]::iTrajOptions(ref_frame)    
  bind $t.ref.refspin <Return> { ::Rmsdvt::ValidateSpinbox %W from}
  bind $t.ref.refspin <FocusOut> { ::Rmsdvt::ValidateSpinbox %W from}
  
  grid $t.ref.rsel_frame -column 0 -row $row
  grid $t.ref.reflabel -column 1 -row $row -sticky w
  grid $t.ref.refspin -column 2 -row $row -sticky w -columnspan 2
  
  
  # - WINDOW SIZE
  set row [expr $row + 1]
  radiobutton $t.ref.rsel_window -variable [namespace current]::iTrajOptions(ref_selection) -value 1 -command [namespace current]::SetRMSFLabelState
  #checkbutton $t.ref.wnd_checkbox -variable [namespace current]::iTrajOptions(window_checkbox) -command [namespace current]::RefreshTrajectoryOptions    
  label $t.ref.wnd_label -text "Window:"  
  spinbox $t.ref.wnd_spin -width 5 -from 0 -to 100 -textvariable [namespace current]::iTrajOptions(ref_window);# -command [namespace current]::SetRMSFLabelState
  bind $t.ref.wnd_spin <Return> { ::Rmsdvt::ValidateSpinbox %W from}
  bind $t.ref.wnd_spin <FocusOut> { ::Rmsdvt::ValidateSpinbox %W from}
  label $t.ref.wnd_label2 -text "(RMSF)"
  

  grid $t.ref.rsel_window -column 0 -row $row
  grid $t.ref.wnd_label -column 1 -row $row -sticky w
  grid $t.ref.wnd_spin -column 2 -row $row -sticky w
  grid $t.ref.wnd_label2 -column 3 -row $row
  
  [namespace current]::SetRMSFLabelState
  
  # Set in Top
  grid $t.ref -in $t -column 1 -row 1 -sticky nswe
  
  
  
  ##
  ## RMSD and Align Buttons
  ##
  frame $t.pushfr -relief ridge -bd 2  
  grid $t.pushfr -in $t -column 1 -row 2 -sticky nsew 

  button $t.pushfr.rmsd -text "RMSD" -relief raised -command [namespace current]::CalculateRmsdAvgThroughTrajectory -pady 2 -bd 2 -padx 2
  button $t.pushfr.align -text "ALIGN" -relief raised -command [namespace current]::AlignMoleculeThroughTrajectory -pady 2 -bd 2 -padx 2
  #grid $t.pushfr.rmsd $t.pushfr.align -sticky nwse
  # buttons on the left or buttons in the middle....
  grid $t.pushfr.rmsd -sticky nsew -column 0 -row 0 -pady 10 -padx 5
  grid $t.pushfr.align -sticky nsew -column 1 -row 0 -pady 10 -padx 5
  grid columnconfigure $t.pushfr 0 -weight 1
  grid columnconfigure $t.pushfr 1 -weight 1
  
  
  #
  # Results
  #
  frame $iW.results -relief ridge -bd 2 -pady 0 
  grid $iW.results -sticky news
  
  #separator          
  #ttk::separator $iW.results.sepr
  #pack $iW.results.sepr -side top -fill x
  
  #label $iW.results.lf -text "Results"
  # -relief ridge -bd 2
  #pack $iW.results.lf -side top -fill x
  
  #
  # Results list
  #  
  # make res colum expand 3 times more than mol column and run column not at all
  #grid columnconfigure $iW.results 2 -weight 3
  #grid rowconfigure $iW.results 1 -weight 1
  #grid columnconfigure $iW.results 1 -weight 1
  #grid rowconfigure $iW.results 1 -weight 1
  
  label $iW.results.header_run  -text "run"  -width 4  -relief flat
  label $iW.results.header_mol -text "mol" -width 20 -relief flat
  label $iW.results.header_res -text "result" -width 40  -relief flat


  grid $iW.results.header_run -column 0 -row 0
  grid $iW.results.header_mol -column 1 -row 0 
  grid $iW.results.header_res -column 2 -row 0 -sticky we -columnspan 2

 
  set iResListboxArray(run) [listbox $iW.results.body_run -height 10 -width 4  -relief sunken -exportselection 0 -yscrollcommand [namespace current]::MoveScrollbar -selectmode extended]
  set iResListboxArray(mol) [listbox $iW.results.body_mol -height 10 -width 20 -relief sunken -exportselection 0 -yscrollcommand [namespace current]::MoveScrollbar -selectmode extended]
  set iResListboxArray(res) [listbox $iW.results.body_res -height 10 -width 40 -relief sunken -exportselection 0 -yscrollcommand [namespace current]::MoveScrollbar -selectmode extended]
  
  grid $iW.results.body_run -in $iW.results -column 0 -row 1 -sticky ns
  grid $iW.results.body_mol -in $iW.results -column 1 -row 1 -sticky nswe
  grid $iW.results.body_res -in $iW.results -column 2 -row 1 -sticky nswe

  #grid columnconfigure $iW.results 0 -weight 1
  grid columnconfigure $iW.results 1 -weight 1
  grid columnconfigure $iW.results 2 -weight 3
  grid rowconfigure $iW.results 1 -weight 1


  foreach key [array names iResListboxArray] {
    bind $iW.results.body_$key <<ListboxSelect>> "[namespace current]::ListSelection %W"
  }  
  
  # Scrollbar
  scrollbar $iW.results.scrbar -orient vert -command [namespace current]::SetScollbar
  #scrollbar $iW.scrbar.scrbar -relief raised -activerelief raised -bd 2 -elementborderwidth 2 -orient vert -command {rmsdtt::scroll_data}
  grid $iW.results.scrbar -column 3 -row 1 -sticky ns  
  
  
  #
  # Bottom buttons
  #
  frame $iW.bottom -relief ridge -bd 2 
  grid $iW.bottom -sticky new -pady 3 
  
  button $iW.bottom.plot        -text "Plot result" -relief raised -command [namespace current]::PlotUsingMultiplot -bd 2 -state disabled
  button $iW.bottom.heatmap     -text "Heatmap plot" -relief raised -command [namespace current]::CalculateHeatmapThroughTrajectory -bd 2 -state disabled
  button $iW.bottom.remove      -text "Remove" -relief raised -command [namespace current]::RemoveSelectedResults -bd 2 -state disabled
  button $iW.bottom.remove_all  -text "Remove all" -relief raised -command [namespace current]::ClearResults -bd 2 -state disabled 
  grid  $iW.bottom.plot -in $iW.bottom -column 0 -row 0 -sticky  ew
  grid  $iW.bottom.heatmap -in $iW.bottom -column 1 -row 0 -sticky  ew
  grid  $iW.bottom.remove -in $iW.bottom -column 2 -row 0 -sticky  ew
  grid  $iW.bottom.remove_all -in $iW.bottom -column 3 -row 0 -sticky ew

  # This is an improper way to do this, but works for now. 
  grid rowconfigure $iW 1 -weight 10000
  grid columnconfigure $iW.bottom 0 -weight 1
  grid columnconfigure $iW.bottom 1 -weight 1
  grid columnconfigure $iW.bottom 2 -weight 1
  grid columnconfigure $iW.bottom 3 -weight 1
  
  
  #
  # Statusbar
  #
  frame $iW.statusbar -relief flat 
  grid $iW.statusbar -in $iW -sticky sw
  grid rowconfigure $iW 2 -weight 1
  
  label $iW.statusbar.label -text "No molecules loaded." 
  grid $iW.statusbar.label -sticky ws -padx 3 -pady 2 
  
  
  
  #
  # Initialize GUI
  #  
  [namespace current]::RefreshMolecules
  
  # Update the molecules when molecules are deleted or added
  trace variable vmd_initialize_structure w [namespace current]::RefreshMolecules
  trace variable vmd_trajectory_read w [namespace current]::RefreshMolecules
    
  
  update
  wm minsize $iW [winfo width $iW] [winfo height $iW]
  wm resizable $iW 1 1  
  
  #[namespace current]::UpdateStatusText "No molecules loaded."
  
}

proc ::Rmsdvt::PopulateSavedAtomSelections { } {
    
    variable iW
    variable iSavedAtomSelections    
            
    # puts "POPULATING!"
    
    [namespace current]::LoadSavedAtomSelections
    
    # Clear old
    $iW.menubar.file.load_atomsel delete 0 last
    
    # Create new
    set i 0
    foreach name [array names iSavedAtomSelections] { 
        $iW.menubar.file.load_atomsel add command -label $name -command "[namespace current]::GetSavedAtomSelection $i"
        incr i
    } 
    
    # Enable/Disable menu item
    if { ![llength [array names iSavedAtomSelections]] } {
        $iW.menubar.file entryconfigure 2 -state disabled
    } else {
        $iW.menubar.file entryconfigure 2 -state normal
    }
   
}

proc ::Rmsdvt::AddSavedAtomSelections { } {
    
    variable iW
    variable iSavedAtomSelections    
        
 
    set retval [[namespace current]::Inputbox $iW .inputparamdlg "Save Atom Selection String" "Set short description for the current\natom selection string:" "" "Save"]
    
    set retval [string trim $retval " \t\n"]
    set retval [string map {":" "_" "\$" "USD" "\[" "\(" "\]" "\)"} $retval]
    
    
    if { [string equal $retval "can_zel"] } {
        #Cancelled
        return
    } elseif { [llength $retval] == 0 } {        
        [namespace current]::UpdateStatusText "Not saved."   
	    return
    } else {        
        # Max length set to 50 chars
        set iSavedAtomSelections([string range $retval 0 50]) [string trim [[namespace current]::AtomselectionStr] " \t"]        
        [namespace current]::SaveSavedAtomSelections
    }    
    
    
}


proc ::Rmsdvt::DataDir { } {
 
    variable iDataDir
    
    if { ![string equal $iDataDir ""] } {
        # Directory has already been set
        return $iDataDir
    }
    
    set possible_locations [list]
    
    # Try to locate a suitable (writable) user directory
    
    # Trying VMD environment variables, there are no guarantees which
    # variables are available on each system
    
    # 'C:\Users\Username\AppData\Local' on Win7
    if { [info exists ::env(LOCALAPPDATA)] } {
        lappend possible_locations [string map {"\\" "/"} $::env(LOCALAPPDATA)]
    }
        
    # 'C:\Users\Username\AppData\Local\Temp' on Win7
    if { [info exists ::env(TEMP)] } {
        lappend possible_locations [string map {"\\" "/"} $::env(TEMP)]
    }    
    
    # 'C:\Users\Username\AppData\Local\Temp' on Win7
    if { [info exists ::env(TMP)] } {
        lappend possible_locations [string map {"\\" "/"} $::env(TMP)]
    }              
    
    # On windows 'C:\' on linux '/usr/tmp'
    if { [info exists ::env(TMPDIR)] } {
        lappend possible_locations [string map {"\\" "/"} $::env(TMPDIR)]
    }        
   
    # Plugin installation dir
    if { [info exists ::env(RMSDVTDIR)] } {
        lappend possible_locations [string map {"\\" "/"} $::env(RMSDVTDIR)]
    }         

    # Last chances    
    lappend possible_locations "/usr/tmp"
    
    if { [info exists ::env(USER)] } {
        lappend possible_locations [join [list "C:/Users/" [string map {"\\" "/"} $::env(USER)] "/AppData/Local" ] ""]  
        lappend possible_locations [join [list "/home/" [string map {"\\" "/"} $::env(USER)] "/vmd_rmsdvt" ] ""]
    }      
        
    # TODO Mac folders?
    
    #Open a dialog for selecting a writable directory
    lappend possible_locations "CHOOSEDIR"
    
    
    foreach trydir $possible_locations {
        
        if { [string equal $trydir "CHOOSEDIR"] } {
            # Prompt user to select a writable directory
            set trydir [tk_chooseDirectory  -title "Choose a writable directory" ]
        }
        
        if { [string equal $trydir ""] } {
            continue    
        }
        
        
        # Make sure plugin's dir exists under appdatadir
	if { ![file writable $trydir] } {
            puts "Directory $trydir missing or not writable (0)"
	    continue
	}
        set trydir [join [list $trydir "/VMD_RMSDVT"] ""]
        set mkdir_retval [file mkdir $trydir]
        
        # Was dir created OK?        
        if { [string equal $mkdir_retval ""] } {
            
            # Dir created successfully or already existed
            # Try writing into the dir
            set tryfile [join [list $trydir "/" "tmp_vmd_rmsdvt.txt"] ""]
                         
            #Try to open file for writing
            if { [catch { set fp [open $tryfile "w"]} open_err] } {
                
                # Error writing file, Try next                
                # DEBUG
                puts "Directory $trydir not writable (1): $open_err"
                
            } else {
                # File written successfully,
                # directory is writable
                #puts $fp "temp"
                close $fp
                catch { file delete -force $tryfile }
                set iDataDir $trydir
                return $trydir
            }
            
            
        } else {
            # DEBUG
            puts "Directory $trydir not writable (2)"
        }

        
    }
    

    puts "ERROR: Unable to find a writable data directory for RMSDVT plugin."
    set iDataDir ""
    return ""
       
}



proc ::Rmsdvt::EditSavedAtomSelections { } {
    
    set atmselfile [join [list [[namespace current]::DataDir] "/" "atomselections.txt"] ""]  
    
    if { ![file exists $atmselfile] } {
        [namespace current]::SaveSavedAtomSelections
    }
    
    if { [file exists $atmselfile] } {
        # puts "File: $atmselfile"
        # exec notepad $atmselfile
        
        if { [catch {package require multitext} msg] } {            
            puts "Warning: Package multitext not installed."
            set win_atmselfile [string map {"/" "\\"} $atmselfile]
            
            if { [catch { exec notepad $win_atmselfile &} msg] } { 
                
                # Notepad not working            
                if { [catch { exec vim $atmselfile &} msg] } { 
                    # Vim not working
                    # Last resort is to open in browser                
                    vmd_open_url "file://$atmselfile"   
                }     	    
            }             
            
                        
        } else {
            puts "Opening multitext"
            set instancehandle [multitext]
            $instancehandle openfile $atmselfile
            # $instancehandle quit
        }          
    }
}

proc ::Rmsdvt::LoadSavedAtomSelections { } {
    
    variable iSavedAtomSelections    
    
    array unset iSavedAtomSelections *
    #array set iSavedAtomSelections {}
    
    set atmselfile [join [list [[namespace current]::DataDir] "/" "atomselections.txt"] ""]
    
    if { ![file exists $atmselfile] } {
        return
    }    
    
    set sel_err ""
    if { [catch {set fp [open $atmselfile r]} sel_err] } { 
        [namespace current]::UpdateStatusText "ERROR: $sel_err"   
	    return -1
    }      
    

    set file_data [read $fp]
    close $fp

    # Process file data
    set data [split $file_data "\n"]
    
    foreach line $data {        
        

        if { [string equal [string index $line 0] "#"] || [string first "::" $line] == -1  } {
            # Comment or erroneous line
            continue
        } 

        set split_line [split $line "::"]             
        
        #puts "SPLITLINE: $split_line"

        set desc [string trim [lindex $split_line 0] " \t"]
        set selstr [string trim [lindex $split_line 2] " \t"]
        

        
        set iSavedAtomSelections($desc) $selstr 
    }    

}

proc ::Rmsdvt::SaveSavedAtomSelections { } {
    
    variable iSavedAtomSelections    
    
    set atmselfile [join [list [[namespace current]::DataDir] "/" "atomselections.txt"] ""]
    
    set sel_err ""
    if { [catch {set fp [open $atmselfile w]} sel_err] } { 
        [namespace current]::UpdateStatusText "ERROR: $sel_err"   
	    return -1
    }      

    puts $fp "# File format: description :: atom_selection_string"
    puts $fp "# One desc-atom_sel_str per line\n"
    
    foreach desc [array names iSavedAtomSelections] {
                
        puts $fp "$desc :: $iSavedAtomSelections($desc)"           
    }
    
    close $fp

    [namespace current]::UpdateStatusText "Atom Selection Strings saved." 
    
}

proc ::Rmsdvt::GetSavedAtomSelection { aSelNum } {
    
    variable iW
    variable iSavedAtomSelections    
    
    $iW.top.sels.sel delete 0.0 end
    
    
    set i 0
    foreach desc [array names iSavedAtomSelections] {
        
        if { $i == $aSelNum } {
            #puts "Inserting $i: \"$iSavedAtomSelections($desc)\""
            $iW.top.sels.sel insert 0.0 $iSavedAtomSelections($desc)
            return
        }
        incr i
    }
        
    
    
}







proc ::Rmsdvt::SetBottomButtonsStatus { {aDisable 0} } {
    
    variable iResListboxArray
    variable iW
    
    set sel [$iResListboxArray(run) curselection]
    
    set state "normal"
    
    if { [string equal $sel ""] || $aDisable == 1 } { set state "disabled" }
       
    $iW.bottom.plot configure -state $state
    $iW.bottom.heatmap configure -state $state
    $iW.bottom.remove configure -state $state
    
    # Check number of results in the list
    if { [$iResListboxArray(run) index end] == 0 || $aDisable == 1 } {
        $iW.bottom.remove_all configure -state disabled
    } else {
        $iW.bottom.remove_all configure -state normal
    }  
}


proc ::Rmsdvt::SetRMSFLabelState { } {

    variable iW
    variable iTrajOptions
    
    #puts "SetRMSFLabelState $iTrajOptions(ref_window)"
    
    
    if { $iTrajOptions(ref_selection) == 1 } { 
       # Reference window selected
       $iW.top.ref.wnd_label configure -state normal
       $iW.top.ref.wnd_label2 configure -state normal
       $iW.top.ref.wnd_spin configure -state normal
       
       $iW.top.ref.refspin configure -state disabled    
       
       #$iW.top.ref.reflabel configure -state disabled  
       $iW.top.ref.reflabel configure -state normal
        
    } else {
       # Reference frame selected
       #$iW.top.ref.wnd_label configure -state disabled
       $iW.top.ref.wnd_label configure -state normal
       
       $iW.top.ref.wnd_label2 configure -state disabled
       $iW.top.ref.wnd_spin configure -state disabled
       
       $iW.top.ref.refspin configure -state normal    
       $iW.top.ref.reflabel configure -state normal             
    }
    
    return 
        
}
    
proc ::Rmsdvt::ValidateSpinbox { aPath {aFromOrTo from} {aSwap yes} } {
    
    #puts "ValidateSpinbox: $aPath"
                
    set ret_val 0
    set fail_ind 0
    set input [$aPath get]
    set special_list_values 0
    
    # Special case for molecule Id spinbox "self option"
    if { [string equal [string range $aPath end-6 end] "molspin"] } {
        if { [string equal "self" $input] } { return $ret_val }
        set special_list_values 1
    }
    
    set is_integer [string is integer -strict -failindex fail_ind $input]    
        
    # Make sure input is something that can be compared as an integer
    if { !$is_integer } {
    
        if { $fail_ind > 0 } {
            # Use part of input that can be converted into an integer
            set input [string range $input 0 [expr $fail_ind - 1]]
        } elseif { [string equal $aFromOrTo "to"] } {
            set input 99999999    
        } else {
            set input 0
        }
    
        # DEBUG
        #puts "input set to $input"
        
        $aPath set $input
        set $ret_val 1
    }            
        
    if { [llength [lrange [$aPath cget -values] $special_list_values end]] } {
        # A list of allowed values has been set
        set found [lsearch -exact -integer [lrange [$aPath cget -values] $special_list_values end] $input]        
        if { $found < 0 } {
            # Value not found from the list of allowed values
            $aPath set [lindex [$aPath cget -values] 0]
            set $ret_val 1          
        }           
    } else {
        # To and From used
        set from [expr int([$aPath cget -from])]
        set to [expr int([$aPath cget -to])]                
        
        if { $input < $from } {
            $aPath set $from
            set $ret_val 1     
        } elseif { $input > $to } {
            $aPath set $to
            set $ret_val 1
        } 
        # Else keep typed value   
    }

    #puts "Validated Spinbox $aPath value: [$aPath get]"        
    
    if { !$aSwap } { return $ret_val }
        
    # Make sure _to value is bigger than _from
    if { [string equal [string range $aPath end-2 end] "_to"] } {
        # get values form both spinboxes and swap in necessary
        set to_value [$aPath get]
        set from_value [[join [list [string range $aPath 0 end-3] "_from"] ""] get]        
        if { $to_value < $from_value } { 
            # swap
            set temp $to_value
            $aPath set $from_value
            [join [list [string range $aPath 0 end-3] "_from"] ""] set $temp 
            set $ret_val 1
        }                    
    } elseif { [string equal [string range $aPath end-4 end] "_from"] } {   
             
        set to_value [[join [list [string range $aPath 0 end-5] "_to"] ""] get]
        set from_value [$aPath get]  
        if { $to_value < $from_value } {      
            # swap
            set temp $to_value
            [join [list [string range $aPath 0 end-5] "_to"] ""] set $from_value
            $aPath set $temp
            set $ret_val 1
        }
    }
    
    return $ret_val
}


# Click on Atom Selection Modifiers handled here
# selection noH mean no H atoms
proc ::Rmsdvt::SelectionModifiersChange { aVal } {
    
    variable iAtomSelectionModifiers    
    
    if { !$iAtomSelectionModifiers($aVal) } {
        # Unchecking checked box
        return
    }
    
    
    if { [string equal $aVal "backbone"] } {
        set iAtomSelectionModifiers(noh) 0
        set iAtomSelectionModifiers(trace) 0
    } elseif { [string equal $aVal "trace"] } {
        set iAtomSelectionModifiers(backbone) 0
        set iAtomSelectionModifiers(noh) 0
    } else {
        set iAtomSelectionModifiers(backbone) 0
        set iAtomSelectionModifiers(trace) 0
    }
    
    
    
}

proc ::Rmsdvt::showMessage {mess} {
  bell
  toplevel .messpop 
  grab .messpop
  wm title .messpop "Warning"
    message .messpop.msg -relief groove -bd 2 -text $mess -aspect 400 -justify center -padx 20 -pady 20
  
  button .messpop.okb -text OK -command {destroy .messpop ; return 0}
  grid .messpop.msg .messpop.okb -sticky n
}



proc ::Rmsdvt::SelectedRun { } {
    variable iResListboxArray

    set cur_selection [$iResListboxArray(run) curselection]
    # If multiple selected, pick only first
    if { [llength $cur_selection] > 1 } { set cur_selection [lindex $curselection 0] }
    if { [string equal $cur_selection ""] } { return -1 }
    
    return $cur_selection
}



proc ::Rmsdvt::ListSelection { widget } {
  
    variable iResListboxArray
    variable iW
    variable iRes
    
    set sel [$widget curselection]
    
    #Higlight whole row in results list
    foreach key [array names iResListboxArray] {
        
        $iResListboxArray($key) selection clear 0 end
        
        foreach item $sel {
            $iResListboxArray($key) selection set $item
        }
    }
    
    # TODO figure out what this does and why it is broken
    #if { [llength $sel] == 1 } {
    #    $iW.menubar.result configure -state normal           
    #} else {
    #    $iW.menubar.result configure -state disabled    
    #}
      
    # If single result selected and it has heatmap data 
    if { [llength $sel] == 1 && [info exists iRes(heatmap_type,[[namespace current]::SelectedRun])] && \
                                ![string equal $iRes(heatmap_type,[[namespace current]::SelectedRun]) ""] } {
        $iW.menubar.result entryconfigure 3 -state normal
        #puts "HM: normal iRes size [llength [array names iRes heatmap_type,*]] val: $iRes(heatmap_type,[[namespace current]::SelectedRun])"
    } else {
        $iW.menubar.result entryconfigure 3 -state disabled
        #puts "HM: disabled"
    }
    
    
    [namespace current]::SetBottomButtonsStatus
}

proc ::Rmsdvt::HeatmapConfig { aConfig  } {
    
    variable iRes
    variable iW
    
    set run [[namespace current]::SelectedRun]
    
    if { $run < 0 } { 
        puts "ERROR: No run selected."
        return
    }
    
    # Get heatmap namespace associated with the selected result row
    set ns [string replace $iRes(hm_handle,$run) [expr [string length $iRes(hm_handle,$run)] - [string length "::plothandle"]] end ""]
    
    #puts "DEBUG: handle to heatmap: $iRes(hm_handle,$run)"
    #puts "DEBUG: ns Exists: [namespace exists $iRes(hm_handle,$run)]"    
    #puts "DEBUG: ns : $ns"
    
    
    if { ![info exists iRes(hm_handle,$run)] } {
        puts "ERROR: Heatmap handle not found for run $aRun"
        return
    } elseif { [string equal $aConfig ""] } {
        puts "ERROR: No configure parameters given"
        return
    } elseif { ![namespace exists $ns] } {
        puts "ERROR: Heatmap does not exist anymore. Replot the heatmap."
        [namespace current]::UpdateStatusText "Heatmap does not exist anymore. Replot the heatmap."
        return
    }
    
    #set def_value [$iRes(hm_handle,$run) cget $aConfig]
    set def_value ""
    #puts "CGET:"
    #puts "[$iRes(hm_handle,$run) cget $aConfig]"
    #$iRes(hm_handle,$run) cget $aConfig
    #puts "Default value: $def_value"
    
    #puts -nonewline "Direct:"
    #puts [::HeatMapper::Plot2::plothandle cget xlabel]
    
    set retval [[namespace current]::Inputbox $iW .inputparamdlg "Set $aConfig" "Set heatmap parameter $aConfig to:" $def_value]
    
    if { [string equal $retval "can_zel"] } {
        #puts "RMSDVT: Dialog Cancelled." 
    } else {
        # Apply to heatmap
        set aConfig [join [list "-" $aConfig] ""]
        $iRes(hm_handle,$run) configure [join [concat $aConfig "$retval"] " "]   
    }
        
}

proc ::Rmsdvt::AtomselectionStr {} {
  
  variable iW
  variable iAtomSelectionModifiers
  variable iSettings

  regsub -all "\#.*?\n" [$iW.top.sels.sel get 1.0 end] "" temp1
  regsub -all "\n" $temp1 " " temp2
  regsub -all " $" $temp2 "" temp3

  if { $iAtomSelectionModifiers(trace) } {
    append rms_sel "($temp3) and name CA"
  } elseif { $iAtomSelectionModifiers(backbone) } {
    append rms_sel "($temp3) and name $iSettings(backbone)"
  } elseif { $iAtomSelectionModifiers(noh) } {
    append rms_sel "($temp3) and noh"
  } else {
    append rms_sel $temp3
  }
  #puts "AtomSelection: $rms_sel"
  return $rms_sel

}

proc ::Rmsdvt::Cancel { } {
    
    variable iCancelled
    
    #if { iCancelled == 0 } { destroy $iW.statusbar.cancel }
    set iCancelled 1
}


proc ::Rmsdvt::Cancellable { aEnable } {
    
    variable iW
    variable iCancelled 
    
    # DEBUG
    #puts "cancel exists: [info exists $iW.statusbar.cancel], enable: $aEnable"
    
    if { $aEnable && $iCancelled == 0 } {  
        
        if { ![winfo exists $iW.statusbar.cancel] } {        
            button $iW.statusbar.cancel -text "Cancel" -relief raised -command [namespace current]::Cancel -state normal        
            grid $iW.statusbar.cancel  -sticky e -padx 3 -pady 1
        }
        
        $iW.statusbar.cancel configure -state normal
        
    } elseif { !$aEnable } {
        
        $iW.statusbar.cancel configure -state disabled
                       
        # Destroying the cancel button clears array iRes! and probably others
        # Does the whole toplevel window get destroyed?        
        #destroy $iW.statusbar.cancel    
        set iCancelled 0
    }
    
    update
    
}


proc ::Rmsdvt::UpdateStatusText { statusText } {
    
    variable iW    
    #set path $iW.top.right.info.label
    set path $iW.statusbar.label
    
    $path configure -text $statusText
    update
    
}

# Called when molecule selection combobox selection is changed
proc ::Rmsdvt::SetSelectedMoleculeId {} {
    
    variable iW
    variable iSelMolId
    variable iSelMolFrames
    
    set path $iW.top.molsel.combo
    
    #puts "Rmsdvt::SetSelectedMoleculeId"
        
    # Get mol ID. Substring of selected comboBox string before ":" (mol id)
    set newId [string range [$path get] 0 [expr [string first ":" [$path get]]-1]]
    set frames 0
    
    catch { set frames [molinfo $newId get numframes] }
    
    #puts "SelMol:$iSelMolId newId:$newId SelMolFrames:$iSelMolFrames newframes:$frames"
    
    if { $iSelMolId == $newId && $iSelMolFrames == $frames } {
        # No change in selection
        return   
    }
    
    set iSelMolId $newId
    set iSelMolFrames $frames
    
    #puts "Rmsdvt::SetSelectedMoleculeId $iSelMolId"
    [namespace current]::RefreshTrajectoryOptions        
        
}



proc ::Rmsdvt::RefreshAndValidateReferenceMoleculeList { } {
    
    variable iW
 
    set mol_ids [list "self"]
    
    for {set i 0} {$i < [molinfo num]} {incr i} {
         lappend mol_ids [molinfo index $i]
    }
    
    set old_val [$iW.top.ref.molspin get]
    $iW.top.ref.molspin configure -values $mol_ids    
    $iW.top.ref.molspin set $old_val
    
    [namespace current]::ValidateSpinbox $iW.top.ref.molspin        
}

proc ::Rmsdvt::NumberOfMoleculeFrames { aMolId } {
    
    variable iSelMolId
    
    # No molecules loaded
    if { $iSelMolId < 0 } { return 0 }
    
    if { [string equal $aMolId "self"] } {        
        set aMolId $iSelMolId
    }
    
    if { [lsearch [molinfo list] $iSelMolId] < 0 } {
        puts "ERROR: Molecule $aMolId does not exist."
        return 0
    } 
    
    # DEBUG
    #puts "Mol $aMolId has [molinfo $aMolId get numframes] frames"
    
    return [molinfo $aMolId get numframes]
}


# Update GUI Trajectory options
proc ::Rmsdvt::RefreshTrajectoryOptions { } {

    variable iW
    variable iSelMolId
    variable iSelMolFrames
    variable iTrajOptions
    
    
    # DEBUG
    #puts "Rmsdvt::RefreshTrajectoryOptions"
    #puts "SelMolframes: $iSelMolFrames"

    
    # Reference molecule
    [namespace current]::RefreshAndValidateReferenceMoleculeList      
    
    # Reference frame
    set numof_refmol_frames [[namespace current]::NumberOfMoleculeFrames [$iW.top.ref.molspin get]]
    if { $numof_refmol_frames < 2 } { 
        $iW.top.ref.refspin configure -values [list 0] 
    } else { 
        $iW.top.ref.refspin configure -values [list] -from 0 -to [expr $numof_refmol_frames - 1]
    } 
    [namespace current]::ValidateSpinbox $iW.top.ref.refspin from no
        
    

    # Window size
    if { $numof_refmol_frames < 2 } { 
        $iW.top.ref.wnd_spin configure -values [list 0]         
    } else { 
        $iW.top.ref.wnd_spin configure -values [list] -from 0 -to [expr $numof_refmol_frames - 1]        
    }    
    [namespace current]::ValidateSpinbox $iW.top.ref.wnd_spin        
    
    # Frames from
    if { $iSelMolFrames < 1 } { 
        $iW.top.traj.fr_from configure -values [list 0] 
        $iW.top.traj.fr_to configure -values [list 0] 
    } else { 
        $iW.top.traj.fr_from configure -values [list] -from 0 -to [expr $iSelMolFrames - 1]
        $iW.top.traj.fr_to configure -values [list] -from 0 -to [expr $iSelMolFrames - 1]        
    }
    # Set to spinbiox to upper limit if selection below 2 (for convenience)
    if { $iTrajOptions(frames_to) < 2 } { set iTrajOptions(frames_to) [expr $iSelMolFrames - 1] }
    [namespace current]::ValidateSpinbox $iW.top.traj.fr_from "from" no
    [namespace current]::ValidateSpinbox $iW.top.traj.fr_to "to"
        
    
    # Step
    if { $iSelMolFrames < 2 } { 
        $iW.top.traj.step_spin configure -values [list 1]         
    } else { 
        $iW.top.traj.step_spin configure -values [list] -from 1 -to [expr $iSelMolFrames]        
    }    
    [namespace current]::ValidateSpinbox $iW.top.traj.step_spin


    
    # Handle disabled/normal states
    set fr_state disabled
    set step_state disabled
    #set skip_state disabled    
    #set window_state disabled
    
    if { $iTrajOptions(frames_checkbox) } { set fr_state normal }
    if { $iTrajOptions(step_checkbox) } { set step_state normal }

    # Frames from
    #$iW.top.traj.fr_label_from configure -state $fr_state
    $iW.top.traj.fr_label_from configure -state normal
    $iW.top.traj.fr_from configure -state $fr_state
    $iW.top.traj.fr_label_to configure -state $fr_state
    $iW.top.traj.fr_to configure -state $fr_state        
 
    # Step
    $iW.top.traj.step_label configure -state normal
    $iW.top.traj.step_spin configure -state $step_state
        
}

# Updates molecules combobox list
# Called when refresh is pressed or molecules loaded or deleted
# or when trajectories are added.
# Note: Does not get called when trajectory frames are deleted.
#       No appropriate Tcl callback available. http://www.ks.uiuc.edu/Research/vmd/current/ug/node155.html
#
# In case of molecule deletions selection may change
# since a deleted molecule cannot be selected
proc ::Rmsdvt::RefreshMolecules {args} {

    
    #$path configure -values [list ]
    #variable molecules
    variable iW
    variable iSelMolId
    
    set path $iW.top.molsel.combo
    #puts "Rmsdvt::RefreshMolecules"
    
    # Don't update if the window isn't turned on
    if { [string compare [wm state $iW] normal] } {
        #puts "DEBUG: Do not update"
        return
    }    
    
    #puts "mool:"
    #puts $molecules
    
    set oldSel [$path get]
    #puts "Oldsel: $oldSel"
    #puts $oldSel
    set selList [list]
    set molIdList [list]
    
    
    # Create combobox list elements
    if { [molinfo num] > 0 } {
    
        set topLine [format "%d: Top  (%d frames)" [molinfo top get id] [molinfo top get numframes]]
        lappend selList $topLine
        lappend molIdList [molinfo top get id]
        
        for {set i 0} {$i < [molinfo num]} {incr i} {
            
            set molid [molinfo index $i]
            set line [format "%d" $molid]
            append line ": "
            append line [format "%s" [molinfo $molid get name]]
            append line "  ("
            append line [format "%d" [molinfo $molid get numframes]]
            append line "fs)"
                        
            lappend selList $line
            lappend molIdList $molid
        }
    } else {
        lappend selList "None"   
        lappend molIdList -1
    }

    # Set comboBox contents
    $path configure -values $selList
    
    # Set selection
    # Keep selection based on molecule ID
    # If TOP selected change selection to new TOP molecule when loaded
    set oldSelId [string range $oldSel 0 [string first ":" $oldSel]]
    set x [lsearch -all $selList $oldSelId*]
    #puts "Searching for \"$oldSelId\" x is: $x"    
    if { [string equal $oldSelId ""] || [llength $x] < 1 || [string first ": Top " $oldSel] > 0 } {
        $path current 0
        #Selection changed or no previous selection or TOP selected
        #TODO: update other fields and buttons
        [namespace current]::UpdateStatusText "Molecules updated"
        #puts "Molecules selection changed"
    } else {
        #set last matching element from list to current sel
        #to avoid TOP selection
        $path current [lrange $x end end]
    }        
    
    [namespace current]::SetSelectedMoleculeId
    #set iSelMolId [lindex $molIdList [$path current]]
    #puts "SelectedMoleculeId: $iSelMolId"
    
    if { $iSelMolId == -1 } {
        [namespace current]::UpdateStatusText "No molecules available."
    }
    
    [namespace current]::RefreshTrajectoryOptions
    
    #[namespace current]::RefreshReferenceMoleculeList    
}

# Scrollbars y-scroll command
proc ::Rmsdvt::MoveScrollbar args {
  variable iW
  
  #puts "yset args: $args"
  #puts "Scrollbar: [linsert $args 0 $iW.data.scrbar set]"
  eval [linsert $args 0 $iW.results.scrbar set]
  [namespace current]::SetScollbar moveto [lindex [$iW.results.scrbar get] 0]
}


proc ::Rmsdvt::SetScollbar args {
    
  variable iResListboxArray
  
  foreach name [array names iResListboxArray] {
    eval [linsert $args 0 $iResListboxArray($name) yview]
  }
  
}

proc ::Rmsdvt::HelpAbout { {parent .rmsdvt} } {
  
    set vn [package present rmsdvt]
  
    tk_messageBox -title "About rmsdvt v$vn" -parent $parent -message \
    "\
    RMSDVT v$vn extension for VMD\n\
    RMSD Visualizer Tool\n\n\
    Anssi Nurminen \n\
    University of Tampere \n\
    Institute of Biomedical Technology \n\
    30-01-2012"

}

proc ::Rmsdvt::TheEnd { args } {
    # Delete traces
    # Delete remaining selections
    #puts "WINDOW DESTROYED: Rmsdvt"
    variable iResListboxArray
    variable iExitting
    
    global vmd_trajectory_read
    global vmd_initialize_structure  
    
    trace vdelete vmd_initialize_structure w [namespace current]::RefreshMolecules
    trace vdelete vmd_trajectory_read w [namespace current]::RefreshMolecules
    
    # Prevent multiple calls when exitting
    if { !$iExitting } {
    
        [namespace current]::ClearResults
        array unset iResListboxArray *
    }
    
    set iExitting 1
    
}
