## APBS Run 1.2
##
## GUI plugin for APBS. More info on APBS can be found at
## <http://agave.wustl.edu/apbs/>
##
## Authors: Eamon Caddigan, John Stone, Robert Brunner, Axel Kohlmeyer
##          vmd@ks.uiuc.edu
##
## $Id: apbsrun.tcl,v 1.139 2022/07/04 23:50:57 johns Exp $
##
## TODO:
## * Load charges and radii from ff-parameter files better.
## * User-defined ff-parameter file location.
## * Specify which molecule maps should be loaded into upon completion.
## * Real modal dialogs -- stop stealing focus from other VMD plugins.
## * In main window, display descriptive names for ELEC statements (e.g.,
##   molecule and calculation type) instead of simply displaying their
##   indecies.
## * Kill APBS on windows.
## * User-defined map names for write statements (also prevent clobbering).
## * GUI elements for counterion declarations, calcenergy, calcforce, 
##   writemat, usemap.
## * Display new molecules in drop-down menus immediately after loading them.
## * Progress bar during run (by parsing io.mc?).
## * New defaults.



## Tell Tcl that we're a package and any dependencies we may have
package require Tcl 8.4
package require exectool 1.2
package provide apbsrun 1.4

namespace eval ::APBSRun:: {
  namespace export apbsrun

  # window handles
  variable main_win      ;# handle to main window
  variable elec_win      ;# handle to elec-statement editing window 
  variable settings_win  ;# handle to settings window
  variable map_win       ;# handle to map-loading window
  variable edition_win   ;# handle to ion editing window

  # global settings
  variable elec_listbox  ;# the listbox displaying the elec statements
  variable elec_list     ;# a list containing the elements of elec_listbox
  variable elec_index    ;# next unused index for new elec_listbox elements
  variable elec_current_index ;# elec item being edited
  variable apbs_status   ;# status of the current apbs run
  variable apbs_button   ;# text of the APBS Button
  variable apbs_type     ;# type of apbs run
  variable apbs_fd       ;# file handle of running APBS process


  # Default and user-edited apbs input information, stored as a hash with
  # each key representing a "type" and each element consisting of a list
  # of elec settings, where each elec setting is a list containing pairs of
  # elements (for setting with 'array set')
  variable default_apbs_config
  variable current_apbs_config

  variable elec_temp

  # APBSRun Configuration variables
  variable workdir
  variable workdirsuffix
  variable apbsbin
  variable setup_only
  variable use_dat_radii
  variable use_dat_charges
  variable datfile

  variable apbs_input
  variable ff_radii
  variable ff_charges
  variable pqrfiles
  variable elec_keyword
  variable molids
  variable output_files
  variable load_files
  variable load_files_dest_mol    1

  # ion editor temporary vars
  variable use_ions  1
  variable ionconc   0.150
  variable ionrad    2.0

  # where to run the job
  variable apbs_job_type  "local"

  # some vars used for running remote jobs and accessing BioCoRE
  variable remjob_id -1
  variable remjob_outfiles
  variable remjob_abort

  proc ff_parameter_init {} {
    variable datfile
    variable ff_radii
    variable ff_charges
  
    set datfile [file join $::env(APBSRUNDIR) radii.dat]
    if { ![file exists $datfile] || [catch {set file [open $datfile]}] } {
      puts "apbsrun) warning, can't find parameter file"
      set datfile {}
    } else {
      # Load the radii and charges
      while {-1 != [gets $file line]} {
        if {![regexp {\s*#} $line]} {
          set line [split $line \t]
          set ff_radii([lindex $line 0],[lindex $line 1]) [lindex $line 3]
          set ff_charges([lindex $line 0],[lindex $line 1]) [lindex $line 2]
        }
      }
      close $file
    }
  }

  ##
  ## read parameters immediately during package load, so they are made
  ## available for access by other plugins.
  ##
  ## XXX this is a hack, and the code should probably be migrated out
  ## of apbsrun altogether now that other plugins want to use it.
  ##
  ff_parameter_init
}

##
## Initialize the values, then launch the main window
##
proc ::APBSRun::apbsrun {} {
  variable apbs_status
  variable apbs_button
  variable apbs_type
  variable workdir
  variable workdirsuffix
  variable apbsbin
  variable setup_only
  variable use_dat_radii
  variable use_dat_charges
  variable file_list
  global env

  if [info exists env(TMPDIR)] {
    set workdir $env(TMPDIR)
  } else {
    switch [vmdinfo arch] {
      WIN64 -
      WIN32 {
        set workdir "c:/"
      }
      MACOSXX86_64 -
      MACOSXX86 -
      MACOSX {
        set workdir "/"
      }
      default {
        set workdir "/tmp"
      }
    }
  }
  
  switch [vmdinfo arch] {
    WIN64 -
    WIN32 {
      set apbsbin [::ExecTool::find apbs.exe]
    }
    default {
      set apbsbin [::ExecTool::find apbs]
    }
  }

  set setup_only 0
  set use_dat_radii 0
  set use_dat_charges 0
  set apbs_status "Status: Ready"
  set apbs_button "Run APBS"

  # Maintain a list of VMD's molecules 
  ::APBSRun::update_file_list
  trace add variable ::vmd_initialize_structure write \
    ::APBSRun::update_file_list

  # Set the default for all types
  trace remove variable ::APBSRun::apbs_type write \
    ::APBSRun::update_elec_list
  set apbs_type {}
  ::APBSRun::set_default 

  # Update the elec list every time the type is changed
  trace add variable ::APBSRun::apbs_type write \
    ::APBSRun::update_elec_list

  # Launch the main window
  ::APBSRun::apbs_mainwin
}


# Update the list of elec statements, to reflect the current type of APBS
# run
proc ::APBSRun::update_elec_list {args} {
  variable elec_list
  variable elec_index
  variable current_apbs_config
  variable apbs_type

  set elec_list {}
  for {set i 0} {$i < [llength $current_apbs_config($apbs_type)]} {incr i} {
    if {[lindex $::APBSRun::current_apbs_config($apbs_type) $i] != {}} {
      lappend elec_list $i
    }
  }
  set elec_index $i
}

proc ::APBSRun::update_file_list {args} {
  variable file_list

  set file_list {}

  # Append each loaded molecule to the list of files
  # XXX - Omitting molecules without atoms or coordinates would be
  # preferable, but the vmd_initialize_structure variable is only written
  # when a new molecule is created, so there's no way to know what other
  # information will be loaded into a molecule later
  foreach molid [molinfo list] {
    lappend file_list [concat $molid [molinfo $molid get name]]
  }

  # If there are no valid molecules loaded, add an empty item to the list
  if { [llength $file_list] == 0 } {
    lappend file_list {}
  }
}


##
## Create the main window
##
proc ::APBSRun::apbs_mainwin {} {
  variable main_win
  variable elec_listbox
  variable elec_list
  variable elec_index

  # If already initialized, just turn on
  if { [winfo exists .apbsrun] } {
    wm deiconify $w
    return
  }

  set main_win [toplevel ".apbsrun"]
  wm title $main_win "APBS Tool" 
  wm resizable $main_win yes yes
  option add *tearOff 0
  set w $main_win

  ## make the menu bar
  menu $w.menubar
  $w configure -menu $w.menubar
  set m $w.menubar
  menu $m.edit
  menu $m.help

  $m add cascade -menu $m.edit -label Edit -underline 0
  $m add cascade -menu $m.help -label Help -underline 0

  ## edit menu
  $m.edit add command -label "Settings..." -command ::APBSRun::apbs_settings

  ## help menu
  $m.help add command -label "About" -command {tk_messageBox \
              -type ok -title "About apbsrun"  \
              -message "GUI for initiating APBS runs."}
  $m.help add command -label "Help..." \
              -command "vmd_open_url [string trimright [vmdinfo www] /]/plugins/apbsrun"



  ## main window
  grid columnconfigure $w 0 -weight 1
  grid rowconfigure $w 1 -weight 1
  # edit frame
  frame $w.edit 
  tk_optionMenu $w.edit.type ::APBSRun::apbs_type \
    "Electrostatic Potential" "Solvent Accessibility" "Custom"
  $w.edit.type config -width 25
  button $w.edit.button -text "Default" -width 8 \
    -command ::APBSRun::set_default
  grid $w.edit.type -sticky w -column 0 -row 0 -pady 4
  grid $w.edit.button -column 1 -row 0 -sticky w -pady 4
  grid $w.edit -column 0 -row 0 -sticky news -padx 10

  # list frame
  labelframe $w.list -text "Individual PB calculations (ELEC): " -borderwidth 0
  set elec_listbox [listbox $w.list.names \
    -yscrollcommand {$::APBSRun::main_win.list.scroll set} \
    -listvariable ::APBSRun::elec_list -relief sunken -bd 2 -height 5]
  grid [scrollbar $w.list.scroll -command {$::APBSRun::main_win.list.names yview}] -in $w.list \
    -sticky nes -column 1 -row 0
  grid $w.list.names -column 0 -row 0 -sticky news
  grid $w.list -column 0 -row 1 -sticky news -padx 10
  grid columnconfigure $w.list 0 -weight 1
  grid rowconfigure $w.list 0 -weight 1

  # 3 button frame
  frame $w.buttons 
  button $w.buttons.add -text "Add" -width 8 \
    -command ::APBSRun::elec_add
  button $w.buttons.edit -text "Edit" -width 8 \
    -command ::APBSRun::elec_edit
  button $w.buttons.del -text "Delete" -width 8 \
    -command ::APBSRun::elec_del
  grid $w.buttons.add -column 0 -row 0
  grid $w.buttons.edit -column 1 -row 0
  grid $w.buttons.del -column 2 -row 0
  grid $w.buttons -column 0 -row 2 -sticky news -padx 10 -pady 4

  # run apbs frame
  labelframe $w.apbs 
  label $w.apbs.status -textvar ::APBSRun::apbs_status
  $w.apbs configure -labelwidget $w.apbs.status -borderwidth 0
  button $w.apbs.run -textvar ::APBSRun::apbs_button \
    -width 10 -command ::APBSRun::apbs_start

  radiobutton $w.apbs.uselocal \
    -text "Run job locally"  -value "local" \
    -variable ::APBSRun::apbs_job_type

  radiobutton $w.apbs.usebiocore \
    -text "Run job remotely (BioCoRE)"  -value "biocore" \
    -variable ::APBSRun::apbs_job_type

  grid $w.apbs.uselocal -column 1 -row 0 -sticky w
  grid $w.apbs.usebiocore -column 1 -row 1 -sticky w
  
  grid $w.apbs.run -column 0 -row 0 -rowspan 2
  grid $w.apbs -column 0 -row 3 -sticky news -padx 10 -pady 8
}

proc ::APBSRun::apbs_start {} {
  if { $APBSRun::apbs_job_type == "biocore" } {
    return [ ::APBSRun::apbs_setup biocore ]
  } elseif {$APBSRun::apbs_job_type == "local"} {
    return [ ::APBSRun::apbs_setup normal ]
  } else {
    tk_dialog .errmsg {APBS Tool Error} "Unsupported job type." error 0 Dismiss
  }
}

# Validate values, set up the files for APBS, and run it
proc ::APBSRun::apbs_setup { mode } {
  variable apbs_status
  variable apbs_button
  variable apbs_fd
  variable current_apbs_config
  variable selected_apbs_config 
  variable apbs_type
  variable elec_temp
  variable workdir
  variable workdirsuffix
  variable apbs_input
  variable apbsbin
  variable setup_only
  variable pqrfiles
  variable molids

  
  # find a unique dir name for work files
  puts "apbsrun) Running job mode=$mode"
  
  set dirindx [expr int(rand() * 100000)]
  set workdirsuffix apbs.$dirindx
    while {[catch {close [open [file join $workdir $workdirsuffix] \
           {RDWR CREAT EXCL}]}]} {
    set dirindx [expr rand() * 100000]
    set workdirsuffix apbs.$dirindx
  }
  puts "apbsrun) dir is [file join $workdir $workdirsuffix]"
  # we reserved the name, but its not a dir. Delete it and remake it
  # Unfortunately, this is not atomic. I can't think of a way to make
  # it more robust
  file delete [file join $workdir $workdirsuffix]
  file mkdir [file join $workdir $workdirsuffix]

  if { $mode == "normal" } {
    # If APBS is running, do nothing
    if {[string equal $apbs_button "Stop APBS"]} {
      # Try to kill the process. 
      # XXX - this simply won't work on Windows without a seperate "kill"
      # program being installed, so fail gracefully.
      if { [catch {exec kill [pid $apbs_fd]} err] } {
        tk_dialog .errmsg {APBS Tool Error} "Cannot close APBS:\n $err" error 0 Dismiss
      }
      return
    }

    # Check that we have a valid location for apbs before proceeding
    if {$apbsbin == {} && !$setup_only} {
      # Prompt the user for its location
      switch [vmdinfo arch] {
        WIN64 -
        WIN32 {
          set apbsbin [::ExecTool::find -interactive -path "c:/Program files/APBS/apbs.exe" -description "APBS" apbs.exe]
        }
        default {
          set apbsbin [::ExecTool::find -interactive apbs]
        }
      }
      if {$apbsbin == {}} {
        tk_dialog .errmsg {APBS Tool Error} "Please specify the location of the APBS binary in the Settings Menu" error 0 Dismiss
        return
      }
    }
  }

  set pqrfiles {}

  # Copy the data (a list of elec statements) into selected_apbs_config
  set selected_apbs_config $current_apbs_config($apbs_type)

  # XXX - this implementation won't work when the user wants to use the same
  # molecule with more than one unique selection in different elec
  # statements

  # Create a list of all molecules used by the plugin
  array unset molids
  array unset selections
  set molid_list {}
  set mol_index 1
  for {set i 0} {$i < [llength $selected_apbs_config]} {incr i} {
    array set elec_temp [lindex $selected_apbs_config $i]

    # Check the elec statement for errors
    if { ![::APBSRun::elec_check elec_temp] } {
      puts "apbsrun) Exiting."
      return
    }

    set vmd_molid [string index $elec_temp(mol) 0]
    set vmd_cgcent_molid [string index $elec_temp(cgcent_mol) 0]
    set vmd_fgcent_molid [string index $elec_temp(fgcent_mol) 0]

    if {![info exists molids($vmd_molid)]} {
      set molids($vmd_molid) $mol_index
      lappend molid_list $vmd_molid
      set selections($vmd_molid) $elec_temp(atomsel)
      incr mol_index
    }

    if {[string equal $elec_temp(cgcent_method) "molid"] &&
        ![info exists molids($vmd_cgcent_molid)]} {
      set molids($vmd_cgcent_molid) $mol_index
      lappend molid_list $vmd_cgcent_molid
      incr mol_index
    }

    if {[string equal $elec_temp(fgcent_method) "molid"] &&
        ![info exists molids($vmd_fgcent_molid)]} {
      set molids($vmd_fgcent_molid) $mol_index
      lappend molid_list $vmd_fgcent_molid
      incr mol_index
    }
  }

  # Write a pqr file for each molecule referenced in the plugin
  foreach vmd_molid $molid_list {
    if {[info exists selections($vmd_molid)]} {
      set sel [atomselect $vmd_molid $selections($vmd_molid)]
    } else {
      set sel [atomselect $vmd_molid all]
    }
    set filename [file rootname [molinfo $vmd_molid get name]]
    set filename [file join $workdir $workdirsuffix "$filename.pqr"]
    lappend pqrfiles $filename

    set apbs_status "Status: Writing PQR file: $filename"
    if { [catch {::APBSRun::write_mol $sel $filename} err] } {
      tk_dialog .errmsg {APBS Tool Error} "Error writing PQR file $filename:\n$err" error 0 Dismiss
      set apbs_status "Status: Ready"
      return
    }

    $sel delete
  }

  if { $mode == "normal" } {
    set use_relative_files 1
  } else {
    set use_relative_files 0
  }
  # Write the APBS input file to dir
  set apbs_input [file join $workdir $workdirsuffix apbs.in]
  set apbs_status "Status: Writing APBS input file: $apbs_input"
  if { [catch {::APBSRun::write_input $apbs_input \
                 $use_relative_files } err] } {
    tk_dialog .errmsg {APBS Tool Error} "Error writing APBS input file $apbs_input:\n$err" error 0 Dismiss
    set apbs_status "Status: Ready"
    return
  }

  if { $mode == "normal" } {
    # Run apbs in the working directory
    if {! $setup_only} {
      set currentdir [pwd]
      cd [file join $workdir $workdirsuffix]
      set apbs_status "Status: Running APBS"
      set apbs_button "Stop APBS"
      ::APBSRun::apbs_run
      cd $currentdir
      puts "apbsrun) Output files $::APBSRun::output_files"
    } else {
      set apbs_status "Status: Ready"
      set apbs_button "Run APBS"
    }
  } else {
      set apbs_status "Status: Running on BioCoRE"
      ::APBSRun::apbs_run_biocore
  }
}

proc ::APBSRun::apbs_run_biocore {} {
  variable remjob_id
  
  set apbs_status "Status: Setting up job"
  if { $remjob_id == -1 } {
    set remjob_id [ ::ExecTool::remjob_create_job ]
  } else {
    set res [tk_dialog .biocore_err "Job already running" \
      "It looks like there's already a job running. Forget about old job?" \
      error 0 "Forget old job" "Keep waiting" ]
    if { $res == 0 } {
      biocore_job_cancelled $remjob_id
      puts "apbsrun) It looks like there was already a job running. I will ignore it."
    } else {
      puts "apbsrun) It looks like there's already a job running. To ignore it, run \"::APBSRun::biocore_job_cancelled $remjob_id\""
    }
    return
  }
  
  # check error code here
  set err [::ExecTool::remjob_config_prog $remjob_id "biocore" 1 ]
  if { $err < 0 } {
    puts "apbsrun) Error $err in remjob_config_prog"
    tk_dialog .biocore_err "BioCoRE Connection Problem" \
      "Connection to BioCoRE failed. Job cancelled" \
      error 0 "Ok"
    biocore_job_cancelled $remjob_id
    return
  }

  # Configure job
  set err [ ::APBSRun::biocore_config_run "::APBSRun::biocore_setup_files" \
    "::APBSRun::biocore_job_cancelled" ]
    
  if { $err != 0 } {
    tk_dialog .errmsg {APBS Tool Error} "Error detected in biocore_config_run:\n$err" error 0 Dismiss
    puts "apbsrun) Error $err detected in biocore_config_run"
    biocore_job_cancelled $remjob_id
    set apbs_status "Status: Ready"
    return
  }
  # After the user clicks okay, jump to biocore_setup_files callback
}

proc ::APBSRun::biocore_setup_files { job_id } {
  variable workdir
  variable workdirsuffix
  variable output_files
  variable remjob_id
  variable remjob_outlist

  puts "apbsrun) staging input and output files"
  # Get the list of files from the work dir and send it
  # to my biocore /Private directory
  set local_dir [file join $workdir $workdirsuffix]
  set infiles [glob -dir $local_dir *]
  foreach f $infiles {
    set err [::ExecTool::remjob_config_input_file $remjob_id $f]
    if { $err != 0 } {
      tk_dialog .errmsg {APBS Tool Error} "config_input_file error\[$f\]: $err" error 0 Dismiss
      set apbs_status "Status: Ready"
      return
    }
  }

  # Config stdout and stderr
  set err [::ExecTool::remjob_config_stdout_file $remjob_id $local_dir \
      "apbs.out" 0]
  if { $err != 0 } {
    tk_dialog .errmsg {APBS Tool Error} "config_stdout_file error: $err" error 0 Dismiss
    set apbs_status "Status: Ready"
    return
  }
  set err [::ExecTool::remjob_config_stderr_file $remjob_id $local_dir \
      "apbs.err" 0]
  if { $err != 0 } {
    tk_dialog .errmsg {APBS Tool Error} "config_stderr_file error: $err" error 0 Dismiss
    set apbs_status "Status: Ready"
    return
  }
  
  # Build the list of files that need to be retrieved, then
  # exec the command. We'll use $workdirsuffix for the job name
  set remjob_outlist [ ::APBSRun::biocore_build_output_list $output_files ]

  # Make sure the job is set up correctly  
  set err [::ExecTool::remjob_config_validate $remjob_id ]
  if { $err != 0 } {
    tk_dialog .errmsg {APBS Tool Error} "config_validate error: $err" error 0 Dismiss
    set apbs_status "Status: Ready"
    return
  }

  # Send the input files
  set apbs_status "Status: Sending input files"
  set err [::ExecTool::remjob_send_files $remjob_id]
  if { $err != 0 } {
    tk_dialog .errmsg {APBS Tool Error} "send_files error: $err" error 0 Dismiss
    set apb_status "Status: Ready"
    return
  }
  
  # Start the job
  set apbs_status "Status: Starting job"
  set err [::ExecTool::remjob_run $remjob_id]
  if { $err != 0 } {
    tk_dialog .errmsg {APBS Tool Error} "remjob_run error: $err" error 0 Dismiss
    set apb_status "Status: Ready"
    return
  }
  
  # Install watcher for completion
  ::APBSRun::biocore_reschedule_status_check
}

proc ::APBSRun::biocore_config_run { run_cb cancelled_cb} {
  variable remjob_id
  variable remjob_abort
  variable workdirsuffix
  
  set remjob_abort 0 

  # Pack params in a list to preserve spaces
  set job(biocore_jobName) [ list $workdirsuffix ]
  set job(biocore_jobDesc) [ list "VMD APBS run" ]
  set job(biocore_workDir) [ list $workdirsuffix ]
  set job(biocore_cmd) "apbs"
  set job(biocore_cmdParams) [list "apbs.in" readonly]
  
  set err [::ExecTool::remjob_config_account $remjob_id \
    [array get job] $run_cb $cancelled_cb ]
  
  if { $err != 0 } {
    puts "apbsrun) biocore_config_run error $err"
  }
  
  return $err    
}

proc ::APBSRun::biocore_job_cancelled { job_id } {
  variable remjob_id
  variable apbs_status
  
  set apbs_status "Ready"
  set remjob_id -1
}

# The var output_files has the list of file types that must be returned
# but the .dx extension needs to be added
proc ::APBSRun::biocore_build_output_list { output_files } {
  variable remjob_id
  variable workdir
  variable workdirsuffix
  
  set retrieve_list { }
  foreach f $output_files {
    lappend retrieve_list "$f.dx"
  }
  lappend retrieve_list "io.mc"
  
  set local_dir [ file join $workdir $workdirsuffix ]
  foreach f $retrieve_list {
    set err [ ::ExecTool::remjob_config_output_file $remjob_id \
      $local_dir $f 0 ]
    if { $err != 0 } {
      puts "apbsrun) Config_output_file error \[$f\]: $err"
    }
  }
  
  return $retrieve_list
}

proc ::APBSRun::biocore_check_status {} {
  variable remjob_id
  
  set status [ ::ExecTool::remjob_poll $remjob_id ]
  if { $status == -1 || $status == -2 } {
    puts "apbsrun) Error retrieving status $status"
  }
  
  if { [ ::ExecTool::remjob_isComplete $status ] } {
    after idle { ::APBSRun::biocore_retrieve_files }
    return
  }

  if { !$::APBSRun::remjob_abort } {
    # Wait 5 seconds, then check again
    after 5000 { ::APBSRun::biocore_reschedule_status_check }
  } else {
    puts "apbsrun) APBSRun status check aborted"
    set remjob_id -1
  }
}

proc ::APBSRun::biocore_reschedule_status_check {} {
  # Only check if we are otherwise idle
  after idle { after 0 ::APBSRun::biocore_check_status }
}

proc ::APBSRun::biocore_retrieve_files {} {
  variable remjob_id
  variable remjob_outlist
  variable workdir
  variable workdirsuffix
  
  # Specify which files we want. Add stdout and err to list...
  set file_list [ concat $remjob_outlist "apbs.out" "apbs.err"]
  foreach f $file_list {
    set err [ ::ExecTool::remjob_get_file $remjob_id $f ]
    if { $err != 0 } {
      puts "apbsrun) Error retrieving $f: $err"
    }
  }
  
  # Actually go get the files
  set handle [ ::ExecTool::remjob_start_transfer $remjob_id ]
  if { $handle < 0 }  {
    puts "apbsrun) Error start_transfer: $handle"
  }
  
  # Wait for transfer to complete
  set file_status 0
  while { $file_status != 1 } {
    after 10000
    set file_status [ ::ExecTool::remjob_waitfor_transfer $remjob_id $handle ]
    if { $file_status < 0 } {
      puts "apbsrun) File transfer status: $file_status"
      break
    }
  }
  
  # HACK--- If we specified files that were not produced, we'll get back
  # zero-length files instead. So we'll scan through the files we got back
  # and delete them if they're empty
  set local_dir [ file join $workdir $workdirsuffix ]
  foreach f $file_list {
    set fpath [ file join $local_dir $f]
    if { [file size $fpath ] == 0 } {
      puts "apbsrun) Output file $fpath not retrieved"
      file delete $fpath
    }
  }
  
  # Finish up. Display the results menu
  set remjob_id -1
  ::APBSRun::apbs_stop biocore
  return
}

#
# Procs for running and stopping APBS. These can be overridden locally.
#
proc ::APBSRun::apbs_run {} {
  variable apbsbin
  variable apbs_input
  variable apbs_fd

  # cope with filenames containing spaces
  set apbscmd [format "\"%s\"" $apbsbin]

  # Attach APBS to a filehandle and print output as it becomes available
  if { [catch {set apbs_fd [open "|$apbscmd $apbs_input"]}] } {
    puts "apbsrun: error running $apbsbin"
    ::APBSRun::apbs_stop
  } else {
    fconfigure $apbs_fd -blocking false
    fileevent $apbs_fd readable [list ::APBSRun::read_handler $apbs_fd]
  }
}

# Call this function when apbs is done
proc ::APBSRun::apbs_stop { { mode "normal" } } {
  variable apbs_status
  variable apbs_button
  variable apbs_fd

  if { $mode == "normal" } {
    if { [catch {close $apbs_fd} err] } {
      puts "apbsrun) Warning: possible problem while running APBS:\n  $err"
    } 
  }

  # check whether or not output files exist, are readable, and have
  # non-zero size, and if so prompt the user to load them into VMD
  if { [check_maps_ok] } {
    ::APBSRun::prompt_load_maps
  } else {
    tk_dialog .errmsg "APBSRun Error" "APBSRun: output files missing or unreadable" error 0 Dismiss
  }

  set apbs_status "Status: Ready"
  set apbs_button "Run APBS"
}

# Read and print a line of APBS output.
proc ::APBSRun::read_handler { chan } {
  if {[eof $chan]} {
    fileevent $chan readable ""
    ::APBSRun::apbs_stop
    return
  }
  if {[gets $chan line] > 0} {
    puts "$line"
  }
}


# Write an apbs input file. Return error if the file can't be written.
proc ::APBSRun::write_input {outfile { use_rel_dir 0 } } {
  variable selected_apbs_config 
  variable pqrfiles
  variable molids
  variable output_files

  if { [catch {set file [open $outfile w]}] } {
    error "apbsrun: can't open $outfile for writing"
  }

  # Write the READ section, a list of molecules to use 
  puts $file "read"
  foreach pqrfile $pqrfiles {
    if { $use_rel_dir } {
      set pqrfile [file normalize $pqrfile]
    } else {
      set pqrfile [file tail $pqrfile]
    }
    puts $file "  mol pqr $pqrfile"
  }
  puts $file "end"

  # Write the ELEC statements
  for {set i 0} {$i < [llength $selected_apbs_config]} {incr i} {
    array set elec_statement [lindex $selected_apbs_config $i]
    set apbs_cgcent $molids([string index $elec_statement(cgcent_mol) 0])
    set apbs_fgcent $molids([string index $elec_statement(fgcent_mol) 0])

    puts $file "elec"

    # mg-manual|mg-auto|mg-para|mg-dummy
    puts $file "  $elec_statement(calc_type)"

    # dime
    puts $file "  dime $elec_statement(dime_x) $elec_statement(dime_y) $elec_statement(dime_z)"

    if {[string equal $elec_statement(calc_type) "mg-manual"] ||
        [string equal $elec_statement(calc_type) "mg-dummy"]} {
      # nlev
      puts $file "  nlev $elec_statement(nlev)"

      # glen
      puts $file "  glen $elec_statement(cglen_x) $elec_statement(cglen_y) $elec_statement(cglen_z)" 

      # gcent
      if {[string equal $elec_statement(cgcent_method) "molid"]} {
        puts $file "  gcent mol $apbs_cgcent"
      } else {
        puts $file "  gcent $elec_statement(cgcent_x) $elec_statement(cgcent_y) $elec_statement(cgcent_z)"
      }
    } elseif {[string equal $elec_statement(calc_type) "mg-auto"] ||
              [string equal $elec_statement(calc_type) "mg-para"]} {
      # cglen
      puts $file "  cglen $elec_statement(cglen_x) $elec_statement(cglen_y) $elec_statement(cglen_z)" 

      # cgcent
      if {[string equal $elec_statement(cgcent_method) "molid"]} {
        puts $file "  cgcent mol $apbs_cgcent"
      } else {
        puts $file "  cgcent $elec_statement(cgcent_x) $elec_statement(cgcent_y) $elec_statement(cgcent_z)"
      }

      # fglen
      puts $file "  fglen $elec_statement(fglen_x) $elec_statement(fglen_y) $elec_statement(fglen_z)" 

      # fgcent
      if {[string equal $elec_statement(fgcent_method) "molid"]} {
        puts $file "  fgcent mol $apbs_fgcent"
      } else {
        puts $file "  fgcent $elec_statement(fgcent_x) $elec_statement(fgcent_y) $elec_statement(fgcent_z)"
      }

      if {[string equal $elec_statement(calc_type) "mg-para"]} {
        # pdime
        puts $file "  pdime $elec_statement(pdime_x) $elec_statement(pdime_y) $elec_statement(pdime_z)"

        # ofrac
        puts $file "  ofrac $elec_statement(ofrac)"
      }
    } else {
      puts "apbsrun) unknown calc_type $elec_statement(calc_type)"
    }

    # mol
    set apbs_molid $molids([string index $elec_statement(mol) 0])
    puts $file "  mol $apbs_molid"

    # lpbe|npbe
    puts $file "  $elec_statement(pbe)"

    # bcfl
    if {[string equal $elec_statement(bcfl) "Zero boundary conditions"]} {
      puts $file "  bcfl zero"
    } elseif {[string equal $elec_statement(bcfl) "Single ion for molecule"]} {
      puts $file "  bcfl sdh"
    } elseif {[string equal $elec_statement(bcfl) "Single ion for each ion"]} {
      puts $file "  bcfl mdh"
    } elseif {[string equal $elec_statement(bcfl) "Solution from previous calculation"]} {
      puts $file "  bcfl focus"
    } else {
      puts "apbsrun) unknown bcfl $elec_statement(bcfl)"
    }

    # srfm
    if {[string equal $elec_statement(srfm) "No smoothing"]} {
      puts $file "  srfm mol"
    } elseif {[string equal $elec_statement(srfm) "Harmonic average smoothing"]} {
      puts $file "  srfm smol"
    } elseif {[string equal $elec_statement(srfm) "Spline-based surface definitions"]} {
      puts $file "  srfm spl2"
    } else {
      puts "apbsrun) unknown srfm $elec_statement(srfm)"
    }

    # chgm
    if {[string equal $elec_statement(chgm) "Trilinear hat-function"]} {
      puts $file "  chgm spl0"
    } elseif {[string equal $elec_statement(chgm) "Cubic B-Spline"]} {
      puts $file "  chgm spl2"
    } else {
      puts "apbsrun) unknown chgm $elec_statement(chgm)"
    }

    # ion (optional)
    if {[info exists elec_statement(ion)] && [llength $elec_statement(ion)] != 0} {
      foreach ion $elec_statement(ion) {
        puts $file "  ion $ion"
      }
    }

    # pdie sdie sdens srad swin temp gamma
    foreach keyword {pdie sdie sdens srad swin temp gamma} {
      puts $file "  $keyword  $elec_statement($keyword)"
    }

    #XXX - fix these
    puts $file "  calcenergy no"
    puts $file "  calcforce no"

    # write (optional)
    # XXX - this *will* break when multiple ELEC statements attempt to
    # output the same type of file.
    set output_files {}
    foreach type {charge pot smol sspl vdw ivdw lap edens ndens qdens dielx diely dielz kappa} {
      if { [info exists elec_statement(write,$type)] &&
           ($elec_statement(write,$type) == 1) } {
        puts $file "  write $type dx $type"
        lappend output_files $type
      }
    }

    # XXX - writemat (optional)

    puts $file "end"
  }

  puts $file "quit"
  close $file
}

# Overwrite the selection's radii with those found in the CHARMM parameter
# file
proc ::APBSRun::set_parameter_radii {sel} {
  variable ff_radii

  set radiusOK yes
  set newradius {}

  foreach {resname} [$sel get resname] {name} [$sel get name] {radius} [$sel get radius] {
    if {[info exists ff_radii($resname,$name)]} {
      lappend newradius $ff_radii($resname,$name)
    } else {
      lappend newradius $radius
      set radiusOK no
    }
  }

  $sel set radius $newradius
  if {!$radiusOK} {
    puts "apbsrun) warning, parameter file does not contain entries for all selected"
    puts "apbsrun) atoms, using VMD radii for these."
  }
}

# Overwrite the selection's charges with those found in the CHARMM parameter
# file
proc ::APBSRun::set_parameter_charges {sel} {
  variable ff_charges

  set chargeOK yes
  set newcharge {}

  foreach {resname} [$sel get resname] {name} [$sel get name] {charge} [$sel get charge] {
    if {[info exists ff_charges($resname,$name)]} {
      lappend newcharge $ff_charges($resname,$name)
    } else {
      lappend newcharge $charge
      set chargeOK no
    }
  }

  $sel set charge $newcharge
  if {!$chargeOK} {
    puts "apbsrun) warning, parameter file does not contain entries for all selected"
    puts "apbsrun) atoms, using VMD charges for these."
  }
}


# Create a pqr file for the given atom selection with the given name
proc ::APBSRun::write_mol {sel file} {
  variable datfile
  variable use_dat_radii
  variable use_dat_charges

  # Save the radius and charge before overriding with parameter values
  set oldradius [$sel get radius]
  set oldcharge [$sel get charge]

  # Override current VMD values with CHARMM parameter values
  if { $datfile != {} } {
    if { $use_dat_radii } {
      puts "apbsrun) using CHARMM radii"
      ::APBSRun::set_parameter_radii $sel
    } else {
      puts "apbsrun) using VMD radii"
    }

#XXX - Disabled until the parameter assigning code is improved
#    if { $use_dat_charges } {
#      puts "apbsrun) using CHARMM charges"
#      ::APBSRun::set_parameter_charges $sel
#    } else {
#      puts "apbsrun) using VMD charges"
#    }
  }

  # Make sure the molecule is charged.
  # XXX - APBS should (maybe?) allow uncharged molecules for mg-dummy
  # calculation, but it currently doens't. If future versions allow it, we
  # should add a simple if statement to do so as well.
  set chargeOK 0
  foreach charge [$sel get charge] {
    if {$charge != 0} {
      set chargeOK 1
      break
    }
  }
  if {!$chargeOK && 
      [string equal "no" [tk_messageBox -type yesno \
       -title "Uncharged Molecule" -icon warning \
       -message "Molecule is uncharged. Proceed?\n(Use pdb2pqr or the AutoPSF plugin to correct this)"]]  } {
    error "apbsrun: refusing to write uncharged molecule"
  }

  # Check for the availability of the pqrplugin
  set plugin_available [plugin info {mol file reader} pqr plugin_info]
  if {$plugin_available} {
    puts "apbsrun) using pqrplugin for $file"
    if { [catch {$sel writepqr $file}] } {
      error "apbsrun: couldn't write $file"
    }
  } else {
    puts "apbsrun) creating $file"
    if { [catch {set fd [open $file w]}] } {
      error "apbsrun: can't open $file for writing"
    }
    set i 0

    foreach name [$sel get name] resname [$sel get resname] \
      resid [$sel get resid] x [$sel get x] y [$sel get y] z [$sel get z] \
      charge [$sel get charge] radius [$sel get radius] {
      puts $fd [format "ATOM  %5d %-4s %s %5d    %8.3f%8.3f%8.3f %.3f %.3f" \
        $i [string range $name 0 3] [string range $resname 0 3] \
        [string range $resid 0 6] $x $y $z $charge $radius]
      incr i
    }

    close $fd
  }

  # Restore original values
  $sel set radius $oldradius
  $sel set charge $oldcharge
}


# 
# Open a window for changing APBSRun settings
# 
proc ::APBSRun::apbs_settings {} {
  variable main_win
  variable settings_win

  set ::APBSRun::use_dat_charges_temp $::APBSRun::use_dat_charges
  set ::APBSRun::use_dat_radii_temp $::APBSRun::use_dat_radii
  set ::APBSRun::setup_only_temp $::APBSRun::setup_only
  set ::APBSRun::apbsbin_temp $::APBSRun::apbsbin
  set ::APBSRun::workdir_temp $::APBSRun::workdir
  set w $main_win

  # If already initialized, just turn on
  if { [winfo exists $w.settings] } {
    wm deiconify $settings_win
    return
  }

  set settings_win [toplevel "$w.settings"]
  wm title $settings_win "Settings" 
  wm resizable $settings_win yes yes

  # Make this window modal.
  grab $settings_win
  wm transient $settings_win $w
  wm protocol $settings_win WM_DELETE_WINDOW {
    grab release $::APBSRun::settings_win
    after idle destroy $::APBSRun::settings_win
  }
  raise $settings_win

  frame $settings_win.workdir
  grid [label $settings_win.workdir.label -anchor w \
    -text "Working Directory"] -row 0 -column 0 -sticky ew
  grid [entry $settings_win.workdir.value -width 30 \
    -textvariable ::APBSRun::workdir_temp] -row 1 -column 0 -sticky nsew
  grid [button $settings_win.workdir.button -text "Browse" \
    -command {
      set tempdir [tk_chooseDirectory]
      if {![string equal $tempdir ""]} {
        set ::APBSRun::workdir_temp $tempdir
      }}] -row 1 -column 1 -sticky ew
  grid columnconfigure $settings_win.workdir 0 -weight 1
  grid rowconfigure $settings_win.workdir 1 -weight 1

  frame $settings_win.apbsbin
  grid [label $settings_win.apbsbin.label -anchor w \
    -text "APBS Location"] -row 0 -column 0 -sticky ew
  grid [entry $settings_win.apbsbin.value -width 30 \
    -textvariable ::APBSRun::apbsbin_temp] -row 1 -column 0 -sticky nsew
  grid [button $settings_win.apbsbin.button -text "Browse" \
    -command {
      set tempfile [tk_getOpenFile]
      if {![string equal $tempfile ""]} {
        set ::APBSRun::apbsbin_temp $tempfile
      }}] -row 1 -column 1 -sticky ew
  grid columnconfigure $settings_win.apbsbin 0 -weight 1
  grid rowconfigure $settings_win.apbsbin 1 -weight 1

  frame $settings_win.apbssetup
  checkbutton $settings_win.apbssetup.setup_button \
    -text "Setup files only, do not run APBS" \
    -variable ::APBSRun::setup_only_temp
  checkbutton $settings_win.apbssetup.radii_button \
    -text "Use CHARMM radii" \
    -variable ::APBSRun::use_dat_radii_temp

#XXX - Disabled until the parameter assigning code is improved
#  checkbutton $settings_win.apbssetup.charges_button \
#    -text "Use CHARMM charges" \
#    -variable ::APBSRun::use_dat_charges_temp

  grid $settings_win.apbssetup.setup_button -column 0 -row 0 -pady 2 -sticky w
  grid $settings_win.apbssetup.radii_button -column 0 -row 1 -pady 2 -sticky w
  
  frame $settings_win.okaycancel
  button $settings_win.okaycancel.okay -text OK -width 6 \
    -command {
      set ::APBSRun::use_dat_charges $::APBSRun::use_dat_charges_temp
      set ::APBSRun::use_dat_radii $::APBSRun::use_dat_radii_temp
      set ::APBSRun::setup_only $::APBSRun::setup_only_temp
      set ::APBSRun::apbsbin $::APBSRun::apbsbin_temp
      set ::APBSRun::workdir $::APBSRun::workdir_temp
      grab release $::APBSRun::settings_win
      after idle destroy $::APBSRun::settings_win
    }
  button $settings_win.okaycancel.cancel -text "Cancel" -width 6 \
    -command {
      grab release $::APBSRun::settings_win
      after idle destroy $::APBSRun::settings_win
    }
  grid $settings_win.okaycancel.okay -column 0 -row 0 -padx 2 -pady 2 -sticky w
  grid $settings_win.okaycancel.cancel -column 1 -row 0 -padx 2 -pady 2 -sticky w

  grid $settings_win.workdir  -column 0 -row 0 -pady 10 -padx 10 -sticky news
  grid $settings_win.apbsbin  -column 0 -row 1 -pady 10 -padx 10 -sticky news
  grid $settings_win.apbssetup  -column 0 -row 2 -pady 10 -padx 10 -sticky w
  grid $settings_win.okaycancel  -column 0 -row 3 -pady 10 -padx 10 -sticky w
  grid columnconfigure $settings_win 0 -weight 1
  grid rowconfigure $settings_win 0 -weight 1
  grid rowconfigure $settings_win 1 -weight 1
}


# Reset the current apbs configuration to the default values and 
# reset the current *default* apbs configuration to reflect the top molecule
proc ::APBSRun::set_default {} {
  variable default_apbs_config
  variable current_apbs_config
  variable apbs_type
  variable elec_list
  variable elec_index
  variable file_list

  # Get information about the top mol to set the defaults
  set topmol {}
  set topmol_id [molinfo top]
  if { $file_list != {{}} } {
    set topmol [lsearch -inline $file_list [molinfo top]*]
    if {$topmol == {}} {
      set topmol [lindex $file_list 0]
    }

    # Make sure this molecule contains atoms and coordinates. If not, use
    # the first molecule that does.
    foreach loaded_mol [concat [list $topmol] $file_list] {
      set topmol_id [string index $loaded_mol 0]
      if { [molinfo $topmol_id get numatoms] != 0  &&
           [molinfo $topmol_id get numframes] != 0 } {
        set topmol $loaded_mol
        break
      } else {
        set topmol {}
      }
    }
  }

  set selection_text "all"
  if {($topmol == {}) || ($topmol_id < 0)} {
    set molsize_x 0
    set molsize_y 0
    set molsize_z 0
  } else {
    if {[molinfo $topmol_id get numreps] > 0} {
        set selection_text [lindex [molinfo $topmol_id get {"selection 0"}] 0]
    }

    # Find the size of the molecule
    set sel [atomselect $topmol_id all]
    set minmax [measure minmax $sel]
    $sel delete

    set molsize_x [expr [lindex $minmax 1 0] - [lindex $minmax 0 0]]
    set molsize_y [expr [lindex $minmax 1 1] - [lindex $minmax 0 1]]
    set molsize_z [expr [lindex $minmax 1 2] - [lindex $minmax 0 2]]
  }

  # Set Default APBS info
  set default_apbs_config([concat "Electrostatic" "Potential"]) [list [list \
    mol $topmol atomsel $selection_text pbe lpbe \
    bcfl "Single ion for molecule" pdie 1.0 sdie 78.54 \
    srfm "Harmonic average smoothing" chgm "Cubic B-Spline" \
    sdens 10.0 srad 1.4 swin 0.3 temp 298.15 gamma 0.105 \
    write,pot 1 \
    ion { {1 0.150 2.0} {-1 0.150 2.0} } \
    calc_type {mg-auto} dime_x 129 dime_y 129 dime_z 129 \
    cglen_x [expr 1.5 * $molsize_x] cglen_y [expr 1.5 * $molsize_y] \
    cglen_z [expr 1.5 * $molsize_z] cgcent_method {molid} \
    cgcent_x {} cgcent_y {} cgcent_z {} cgcent_mol $topmol \
    fglen_x [expr 1.5 * $molsize_x] fglen_y [expr 1.5 * $molsize_y] \
    fglen_z [expr 1.5 * $molsize_z] fgcent_method {molid} \
    fgcent_x {} fgcent_y {} fgcent_z {} fgcent_mol $topmol \
    nlev 4 ofrac 0.1 pdime_x 4 pdime_y 4 pdime_z 4 ] ]

  set default_apbs_config([concat "Solvent" "Accessibility"]) [list [list \
    mol $topmol atomsel $selection_text pbe lpbe \
    bcfl "Single ion for molecule" pdie 1.0 sdie 78.54 \
    srfm "Harmonic average smoothing" chgm "Cubic B-Spline" \
    sdens 10.0 srad 1.4 swin 0.3 temp 298.15 gamma 0.105 \
    write,sspl 1 \
    ion { {1 0.150 2.0} {-1 0.150 2.0} } \
    calc_type {mg-dummy} dime_x 129 dime_y 129 dime_z 129 \
    cglen_x [expr 1.5 * $molsize_x] cglen_y [expr 1.5 * $molsize_y] \
    cglen_z [expr 1.5 * $molsize_z] cgcent_method {molid} \
    cgcent_x {} cgcent_y {} cgcent_z {} cgcent_mol $topmol \
    fglen_x [expr 1.5 * $molsize_x] fglen_y [expr 1.5 * $molsize_y] \
    fglen_z [expr 1.5 * $molsize_z] fgcent_method {molid} \
    fgcent_x {} fgcent_y {} fgcent_z {} fgcent_mol $topmol \
    nlev 4 ofrac 0.1 pdime_x 4 pdime_y 4 pdime_z 4 ] ]

  set default_apbs_config(Custom) {}

  # Copy the defaults to the user-edited APBS info
  if {$apbs_type == {}} {
    array set current_apbs_config [array get default_apbs_config]
    set apbs_type "Electrostatic Potential"
  } else {
    set current_apbs_config($apbs_type) $default_apbs_config($apbs_type)
  }

  ::APBSRun::update_elec_list
}


# Add an ELEC statement to elec_vals
proc ::APBSRun::elec_add {} {
  variable elec_temp
  variable elec_index
  variable elec_current_index

  # Clear the temp array
  array unset elec_temp

  # Launch the elec-editing window
  set elec_current_index $elec_index
  ::APBSRun::elecmenu
}


# Edit an ELEC statement in elec_vals
proc ::APBSRun::elec_edit {} {
  variable elec_temp
  variable elec_listbox
  variable elec_list
  variable elec_current_index
  variable current_apbs_config
  variable apbs_type

  # Can't edit anything if no ELEC statements exist
  if {[llength $elec_list] == 0} {
    return
  }
 
  set elec_current_index [string index [$elec_listbox get active] 0]

  # Clear the temporary array, and load it with previous values
  array unset elec_temp
  array set elec_temp \
    [lindex $current_apbs_config($apbs_type) $elec_current_index]

  # Launch the elec-editing window
  ::APBSRun::elecmenu
}


# Remove an ELEC statement from elec_vals
proc ::APBSRun::elec_del {} {
  variable elec_listbox
  variable current_apbs_config
  variable apbs_type

  set index [string index [$elec_listbox get active] 0]

  # Remove the entry from the listbox
  $elec_listbox delete active

  # Set the appropriate item in current_apbs_config to nothing
  #XXX - this is ugly
  lset current_apbs_config($apbs_type) $index {}
}


# Open a window for editing the values of an elec statement
proc ::APBSRun::elecmenu {} {
  variable main_win
  variable elec_win
  variable elec_temp
  variable file_list
  variable elec_keyword
  set w $main_win
  option add *tearOff 0

  # If already initialized, just turn on
  if { [winfo exists $w.elec] } {
    wm deiconify $elec_win
    return
  }

  set elec_win [toplevel "$w.elec"]
  set ew $elec_win
  wm title $ew "ELEC values" 
  wm resizable $ew yes yes

  # Make this window modal.
  grab $ew
  wm transient $ew $w
  wm protocol $ew WM_DELETE_WINDOW {
    grab release $::APBSRun::elec_win
    after idle destroy $::APBSRun::elec_win
  }
  raise $ew

  menu $ew.menubar
  $ew configure -menu $ew.menubar
  set m $ew.menubar
  menu $m.calc
  menu $m.output

  $m add cascade -menu $m.calc -label Calculation -underline 0
  $m add cascade -menu $m.output -label Output -underline 0

  # calculation menu
  $m.calc add radiobutton -label "Automatic" -variable ::APBSRun::elec_temp(calc_type) -value {mg-auto}
  $m.calc add radiobutton -label "Manual" -variable ::APBSRun::elec_temp(calc_type) -value {mg-manual}
  $m.calc add radiobutton -label "Parallel" -variable ::APBSRun::elec_temp(calc_type) -value {mg-para}
  $m.calc add radiobutton -label "Dummy" -variable ::APBSRun::elec_temp(calc_type) -value {mg-dummy}
  $m.calc add separator
  $m.calc add radiobutton -label "Linearized PBE" -variable ::APBSRun::elec_temp(pbe) -value {lpbe}
  $m.calc add radiobutton -label "Nonlinear PBE" -variable ::APBSRun::elec_temp(pbe) -value {npbe}


  # output menu
  $m.output add checkbutton -label "Charge distribution" -variable ::APBSRun::elec_temp(write,charge)
  $m.output add checkbutton -label "Potential" -variable ::APBSRun::elec_temp(write,pot)
  $m.output add checkbutton -label "Solvent accessibility" -variable ::APBSRun::elec_temp(write,sspl)
  $m.output add checkbutton -label "Van der Waals accessibility" -variable ::APBSRun::elec_temp(write,vdw)
  $m.output add checkbutton -label "Ion accessibility" -variable ::APBSRun::elec_temp(write,ivdw)
  $m.output add checkbutton -label "Laplacian of potential" -variable ::APBSRun::elec_temp(write,lap)
  $m.output add checkbutton -label "Energy density" -variable ::APBSRun::elec_temp(write,edens)
  $m.output add checkbutton -label "Ion number density" -variable ::APBSRun::elec_temp(write,ndens)
  $m.output add checkbutton -label "Ion charge density" -variable ::APBSRun::elec_temp(write,qdens)
  $m.output add checkbutton -label "x-shifted dielectric map" -variable ::APBSRun::elec_temp(write,dielx)
  $m.output add checkbutton -label "y-shifted dielectric map" -variable ::APBSRun::elec_temp(write,diely)
  $m.output add checkbutton -label "z-shifted dielectric map" -variable ::APBSRun::elec_temp(write,dielz)
  $m.output add checkbutton -label "Map function" -variable ::APBSRun::elec_temp(write,kappa)


  if {![info exists ::APBSRun::elec_temp(calc_type)]} {
    set ::APBSRun::elec_temp(calc_type) {mg-auto}
  }

  # Trace the keyword variable so different options can be displayed when it
  # changes
  trace add variable ::APBSRun::elec_temp(calc_type) write \
    ::APBSRun::change_keyword

  # Remove the trace when this window is destroyed
  bind $ew <Destroy> {+trace remove variable \
    ::APBSRun::elec_temp(calc_type) write ::APBSRun::change_keyword}

  ### frame for options used by all ELEC keyworks
  labelframe $ew.options -text "options*"

  # mol
  # XXX this code fails to propagate changes to the selected molecule
  #     due to an interaction between the 'top' molecule, and the 
  #     molecule selected in the edit interface.
  frame $ew.options.mol
  label $ew.options.mol.label -text "Molecule: " \
    -anchor w
  eval tk_optionMenu $ew.options.mol.id ::APBSRun::elec_temp(mol) \
    $file_list
  $ew.options.mol.id configure -width 12
  grid $ew.options.mol.label  -column 0 -row 0 -sticky w
  grid $ew.options.mol.id  -column 1 -row 0 -sticky ew
  grid columnconfigure $ew.options.mol 1 -weight 1

  # selection
  frame $ew.options.atomsel
  label $ew.options.atomsel.label -text "Selection: " \
    -anchor w
  entry $ew.options.atomsel.entry -width 20 \
    -textvar ::APBSRun::elec_temp(atomsel)
  grid $ew.options.atomsel.label  -column 0 -row 0 -sticky w
  grid $ew.options.atomsel.entry  -column 1 -row 0 -sticky ew
  grid columnconfigure $ew.options.atomsel 1 -weight 1

  # bcfl
  frame $ew.options.bcfl
  label $ew.options.bcfl.label -text "Boundary condition: "
  tk_optionMenu $ew.options.bcfl.menu ::APBSRun::elec_temp(bcfl) \
    "Zero boundary conditions" \
    "Single ion for molecule" \
    "Single ion for each ion" \
    "Solution from previous calculation"
  $ew.options.bcfl.menu config -width 25
  grid $ew.options.bcfl.label  -column 0 -row 0 -sticky w
  grid $ew.options.bcfl.menu  -column 0 -row 1 -sticky w

  # ion (optional)
  frame $ew.options.ions
  label $ew.options.ions.label -text "Mobile Ions: "
  button $ew.options.ions.edit -text "Edit..." -command ::APBSRun::edit_ions
  grid $ew.options.ions.label  -column 0 -row 0 
  grid $ew.options.ions.edit  -column 1 -row 0

  # pdie
  # sdie
  frame $ew.options.diel
  label $ew.options.diel.label -text "Dielectric constants: "
  label $ew.options.diel.plabel -text "solute: "
  entry $ew.options.diel.pval -width 6 -textvar ::APBSRun::elec_temp(pdie)
  label $ew.options.diel.slabel -text " solvent: "
  entry $ew.options.diel.sval -width 6 -textvar ::APBSRun::elec_temp(sdie)
  grid $ew.options.diel.label  -column 0 -row 0 -columnspan 4 -sticky w
  grid $ew.options.diel.plabel  -column 0 -row 1
  grid $ew.options.diel.pval  -column 1 -row 1
  grid $ew.options.diel.slabel  -column 2 -row 1
  grid $ew.options.diel.sval  -column 3 -row 1

  # chgm
  frame $ew.options.chgm
  label $ew.options.chgm.label -text "Charge discretization: "
  tk_optionMenu $ew.options.chgm.menu ::APBSRun::elec_temp(chgm) \
    "Trilinear hat-function" \
    "Cubic B-Spline" 
  $ew.options.chgm.menu config -width 25
  grid $ew.options.chgm.label -column 0 -row 0 -sticky w
  grid $ew.options.chgm.menu -column 0 -row 1 -sticky w


  # srfm
  frame $ew.options.srfm
  label $ew.options.srfm.label -text "Surface definition: "
  tk_optionMenu $ew.options.srfm.menu ::APBSRun::elec_temp(srfm) \
    "No smoothing" \
    "Harmonic average smoothing" \
    "Spline-based surface definitions"
  $ew.options.srfm.menu config -width 25
  grid $ew.options.srfm.label -column 0 -row 0 -sticky w
  grid $ew.options.srfm.menu -column 0 -row 1 -sticky w

  # usemap (optional)
  # XXX - TODO
 
  # Grid containing a few system options
  frame $ew.options.system

  # sdens added for APBS 0.4.0 
  label $ew.options.system.sdensl -text "Vacc sphere density: " \
    -anchor w
  entry $ew.options.system.sdensval -width 6 \
    -textvar ::APBSRun::elec_temp(sdens)
  grid $ew.options.system.sdensl $ew.options.system.sdensval \
    -row 0 -sticky ew

  # srad
  label $ew.options.system.sradl -text "Solvent radius: " \
    -anchor w
  entry $ew.options.system.sradval -width 6 \
    -textvar ::APBSRun::elec_temp(srad)
  grid $ew.options.system.sradl $ew.options.system.sradval \
    -row 1 -sticky ew
  
  # swin
  label $ew.options.system.swinl -text "Spline window: " \
    -anchor w
  entry $ew.options.system.swinval -width 6  \
    -textvar ::APBSRun::elec_temp(swin)
  grid $ew.options.system.swinl $ew.options.system.swinval \
    -row 2 -sticky ew

  # temp
  label $ew.options.system.templ -text "System temperature (K): " \
    -anchor w
  entry $ew.options.system.tempval -width 6 \
    -textvar ::APBSRun::elec_temp(temp)
  grid $ew.options.system.templ $ew.options.system.tempval \
    -row 3 -sticky ew

  # gamma
  label $ew.options.system.gammal -text "Surface tension: " \
    -anchor w
  entry $ew.options.system.gammaval -width 6 \
    -textvar ::APBSRun::elec_temp(gamma)
  grid $ew.options.system.gammal $ew.options.system.gammaval \
    -row 4 -sticky ew

  grid columnconfigure $ew.options.system 1 -weight 1

  # XXX calcforce and calcenergy -- write results to stdout

  # write (optional)
  # XXX - TODO

  # writemat (optional)
  # XXX - TODO

  grid $ew.options.mol     -column 0 -row 0 -sticky news -padx 8 -pady 8 
  grid $ew.options.atomsel -column 0 -row 1 -sticky news -padx 8 -pady 8 
  grid $ew.options.bcfl    -column 0 -row 2 -sticky news -padx 8 -pady 8
  grid $ew.options.ions    -column 0 -row 3 -sticky news -padx 8 -pady 8
  grid $ew.options.diel    -column 0 -row 4 -sticky news -padx 8 -pady 8
  grid $ew.options.chgm    -column 0 -row 5 -sticky news -padx 8 -pady 8
  grid $ew.options.srfm    -column 0 -row 6 -sticky news -padx 8 -pady 8
  grid $ew.options.system  -column 0 -row 7 -sticky news -padx 8 -pady 8
  grid columnconfigure $ew.options 0 -weight 1
    

  # End the frame for selecting general APBS options
  grid $ew.options -column 0 -row 0 \
    -sticky nsew -padx 8 -pady 0


  ### Grid (and keyword) specific options
  frame $ew.grid

  # dime
  frame $ew.grid.dime 
  label $ew.grid.dime.label -text "Number of gridpoints: "
  frame $ew.grid.dime.coord
  label $ew.grid.dime.coord.xlabel -text "x: "
  entry $ew.grid.dime.coord.xentry -width 6 -textvar ::APBSRun::elec_temp(dime_x)
  label $ew.grid.dime.coord.ylabel -text " y: "
  entry $ew.grid.dime.coord.yentry -width 6 -textvar ::APBSRun::elec_temp(dime_y)
  label $ew.grid.dime.coord.zlabel -text " z: "
  entry $ew.grid.dime.coord.zentry -width 6 -textvar ::APBSRun::elec_temp(dime_z)

  grid $ew.grid.dime.coord.xlabel -column 0 -row 1 -sticky w
  grid $ew.grid.dime.coord.xentry -column 1 -row 1 -sticky w
  grid $ew.grid.dime.coord.ylabel -column 2 -row 1 -sticky w
  grid $ew.grid.dime.coord.yentry -column 3 -row 1 -sticky w
  grid $ew.grid.dime.coord.zlabel -column 4 -row 1 -sticky w
  grid $ew.grid.dime.coord.zentry -column 5 -row 1 -sticky w
  grid $ew.grid.dime.label -column 0 -row 0 -sticky w
  grid $ew.grid.dime.coord -column 0 -row 1 -sticky w
  grid $ew.grid.dime -column 0 -row 0 -sticky w -pady 8 -padx 8

  # Draw the appropriate keyword options
  draw_mg_para $ew.grid.mg_para
  draw_mg_auto $ew.grid.mg_auto
  draw_mg_manual $ew.grid.mg_manual
  set elec_keyword $ew.grid.mg_auto
  ::APBSRun::change_keyword
  
  # End the frame for selecting ELEC keyword and keyword-specific options
  grid $ew.grid -column 1 -row 0 -rowspan 2 \
    -sticky nsew -padx 8 -pady 0

  frame $ew.okaycancel
  raise $ew.okaycancel
  button $ew.okaycancel.okay -text OK -width 6 \
    -command {
      if { [::APBSRun::elec_check ::APBSRun::elec_temp] } {
        ::APBSRun::elec_save ::APBSRun::elec_temp
        grab release $::APBSRun::elec_win
        after idle destroy $::APBSRun::elec_win
      }
    }
  button $ew.okaycancel.cancel -text Cancel -width 6 \
    -command {
      grab release $::APBSRun::elec_win
      after idle destroy $::APBSRun::elec_win
    }

  grid $ew.okaycancel.okay -column 0 -row 0 -sticky w
  grid $ew.okaycancel.cancel -column 1 -row 0 -sticky w
  grid $ew.okaycancel -column 0 -row 1 \
    -sticky w -padx 8 -pady 8

  grid columnconfigure $ew {0} -weight 1
  grid rowconfigure $ew 0 -weight 1 
  grid rowconfigure $ew 1 -minsize 50
}


# When elec_temp(calc_type) changes, change the contents of the elec_win
proc ::APBSRun::change_keyword {args} {
  variable elec_win
  variable elec_temp
  variable elec_keyword

  grid forget $elec_keyword

  if {[string equal $elec_temp(calc_type) "mg-para"]} {
    set elec_keyword $elec_win.grid.mg_para
  } elseif {[string equal $elec_temp(calc_type) "mg-auto"]} {
    set elec_keyword $elec_win.grid.mg_auto
  } elseif {[string equal $elec_temp(calc_type) "mg-manual"] ||
            [string equal $elec_temp(calc_type) "mg-dummy"]} {
    set elec_keyword $elec_win.grid.mg_manual
  }

  grid $elec_keyword -column 0 -row 1 -sticky news
}


# Edit ion settings
proc ::APBSRun::edit_ions { } {
  variable elec_win
  variable edition_win
  variable use_ions
  variable ionconc
  variable ionrad

  # this is a hack until we have a full ion editing browser
  # Users will generally add equal concentrations of +1 and -1 ions, 
  # both with equal radii
  if { [info exists ::APBSRun::elec_temp(ion)] } {
    set ionlist $::APBSRun::elec_temp(ion)

    if { [llength ionlist] == 0 } {
#puts "apbsrun) edit_ion: selecting sane defaults1"
      set ionconc 0.150 
      set ionrad  2.0 
    } else {
#puts "apbsrun) edit_ion: using existing settings"
      set ionconc [lindex $ionlist 0 1]
      set ionrad  [lindex $ionlist 0 2] 
    }
  } else {
#puts "apbsrun) edit_ion: selecting sane defaults2"
    set ionconc 0.150 
    set ionrad  2.0 
  }

  set w [toplevel "$elec_win.editions"]
  set edition_win $w

  wm title $w "APBSRun - Edit Mobile Ions"
  wm resizable $w 0 0

  # Make this window modal.
  grab $w
  wm transient $w $elec_win
  wm protocol $w WM_DELETE_WINDOW {
    grab release $::APBSRun::edition_win
    after idle destroy $::APBSRun::edition_win
  }
  raise $w

  frame $w.enable 
  checkbutton $w.enable.check \
    -text "Enable mobile ions" -variable ::APBSRun::use_ions
  grid $w.enable.check -column 0 -row 0 -sticky w
 
  frame $w.conc
  label $w.conc.label -text "Mobile ion concentration (M)"
  entry $w.conc.entry -textvar ::APBSRun::ionconc 
  grid $w.conc.label -column 0 -row 0 -sticky w
  grid $w.conc.entry -column 1 -row 0 -sticky w

  frame $w.rad
  label $w.rad.label -text "Mobile ion species radius (Angstroms)"
  entry $w.rad.entry -textvar ::APBSRun::ionrad
  grid $w.rad.label -column 0 -row 0 -sticky w
  grid $w.rad.entry -column 1 -row 0 -sticky w

  button $w.done -text "Done" -command {
    if { $::APBSRun::use_ions } {
#puts "apbsrun) using ions..."
      set ionlist [list [list  1 $::APBSRun::ionconc $::APBSRun::ionrad] \
                        [list -1 $::APBSRun::ionconc $::APBSRun::ionrad]]
      set ::APBSRun::elec_temp(ion) $ionlist
    } else {
#puts "apbsrun) not using ions..."
      if { [info exists ::APBSRun::elec_temp(ion)] } {
        unset ::APBSRun::elec_temp(ion)
      }
    }
    after idle destroy $::APBSRun::edition_win
  }

  grid $w.enable -sticky w -column 0 -row 0
  grid $w.conc -sticky w -column 0 -row 1 
  grid $w.rad -sticky w -column 0 -row 2
  grid $w.done -sticky w -column 0 -row 3
}



# Draw the mg_manual frame
proc ::APBSRun::draw_mg_manual {pathName} {
  variable elec_temp
  variable file_list

  frame $pathName

  #
  # Grid
  #

  frame $pathName.g -relief groove -bd 2
  grid [label $pathName.g.label -text "Grid Options"] \
    -sticky w -column 0 -row 0 -padx 8 -pady 4

  # glen
  frame $pathName.g.len
  label $pathName.g.len.label -text "Mesh Lengths:"

  frame $pathName.g.len.coord
  label $pathName.g.len.coord.xlabel -text "x: "
  entry $pathName.g.len.coord.xvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cglen_x)
  label $pathName.g.len.coord.ylabel -text " y: "
  entry $pathName.g.len.coord.yvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cglen_y)
  label $pathName.g.len.coord.zlabel -text " z: "
  entry $pathName.g.len.coord.zvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cglen_z)
  grid $pathName.g.len.coord.xlabel -column 0 -row 0 -sticky w
  grid $pathName.g.len.coord.xvalue -column 1 -row 0 -sticky w
  grid $pathName.g.len.coord.ylabel -column 2 -row 0 -sticky w
  grid $pathName.g.len.coord.yvalue -column 3 -row 0 -sticky w
  grid $pathName.g.len.coord.zlabel -column 4 -row 0 -sticky w
  grid $pathName.g.len.coord.zvalue -column 5 -row 0 -sticky w

  grid $pathName.g.len.label -column 0 -row 0
  grid $pathName.g.len.coord -column 0 -row 1
  grid $pathName.g.len -column 0 -row 1 -sticky new -padx 8 -pady 4
  
  # gcent
  frame $pathName.g.cent
  label $pathName.g.cent.label -text "Center:" -anchor w

  frame $pathName.g.cent.mol
  radiobutton $pathName.g.cent.mol.button -anchor w \
    -variable ::APBSRun::elec_temp(cgcent_method) -value "molid"
  eval tk_optionMenu $pathName.g.cent.mol.id \
    ::APBSRun::elec_temp(cgcent_mol) $file_list
  $pathName.g.cent.mol.id configure -width 12
  grid $pathName.g.cent.mol.button -column 0 -row 0 -sticky w
  grid $pathName.g.cent.mol.id -column 1 -row 0 -sticky w

  frame $pathName.g.cent.coord
  radiobutton $pathName.g.cent.coord.button -anchor w \
    -variable ::APBSRun::elec_temp(cgcent_method) -value "coord"
  label $pathName.g.cent.coord.xlabel -text "x: "
  entry $pathName.g.cent.coord.xvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cgcent_x)
  label $pathName.g.cent.coord.ylabel -text " y: "
  entry $pathName.g.cent.coord.yvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cgcent_y)
  label $pathName.g.cent.coord.zlabel -text " z: "
  entry $pathName.g.cent.coord.zvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cgcent_z)
  grid $pathName.g.cent.coord.button -column 0 -row 0 -sticky w
  grid $pathName.g.cent.coord.xlabel -column 1 -row 0 -sticky w
  grid $pathName.g.cent.coord.xvalue -column 2 -row 0 -sticky w
  grid $pathName.g.cent.coord.ylabel -column 3 -row 0 -sticky w
  grid $pathName.g.cent.coord.yvalue -column 4 -row 0 -sticky w
  grid $pathName.g.cent.coord.zlabel -column 5 -row 0 -sticky w
  grid $pathName.g.cent.coord.zvalue -column 6 -row 0 -sticky w

  grid $pathName.g.cent.label -column 0 -row 0 -sticky w
  grid $pathName.g.cent.mol -column 0 -row 1 -sticky w
  grid $pathName.g.cent.coord -column 0 -row 2 -sticky w
  grid $pathName.g.cent -column 0 -row 2 -padx 8 -pady 4

  grid $pathName.g -sticky new -column 1 -row 1 -pady 4

  # nlev
  frame $pathName.nlev
  label $pathName.nlev.label -text "Number of levels: "
  entry $pathName.nlev.entry -width 6 -textvariable ::APBSRun::elec_temp(nlev)
  grid $pathName.nlev.label -column 0 -row 0 -sticky w
  grid $pathName.nlev.entry -column 1 -row 0 -sticky w
  grid $pathName.nlev -column 1 -row 2 -sticky w -padx 8 -pady 4
}



# Draw the mg_auto frame
proc ::APBSRun::draw_mg_auto {pathName} {
  variable elec_temp
  variable file_list

  frame $pathName

  #
  # Coarse Grid
  #

  frame $pathName.cg -relief groove -bd 2
  grid [label $pathName.cg.label -text "Coarse Grid Options"] \
    -sticky w -column 0 -row 0 -column 0

  # cglen
  frame $pathName.cg.len
  label $pathName.cg.len.label -text "Mesh Lengths:"

  frame $pathName.cg.len.coord
  label $pathName.cg.len.coord.xlabel -text "x: "
  entry $pathName.cg.len.coord.xvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cglen_x)
  label $pathName.cg.len.coord.ylabel -text " y: "
  entry $pathName.cg.len.coord.yvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cglen_y)
  label $pathName.cg.len.coord.zlabel -text " z: "
  entry $pathName.cg.len.coord.zvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cglen_z)
  grid $pathName.cg.len.coord.xlabel -column 0 -row 0 -sticky w
  grid $pathName.cg.len.coord.xvalue -column 1 -row 0 -sticky w
  grid $pathName.cg.len.coord.ylabel -column 2 -row 0 -sticky w
  grid $pathName.cg.len.coord.yvalue -column 3 -row 0 -sticky w
  grid $pathName.cg.len.coord.zlabel -column 4 -row 0 -sticky w
  grid $pathName.cg.len.coord.zvalue -column 5 -row 0 -sticky w

  grid $pathName.cg.len.label -column 0 -row 0 -sticky w
  grid $pathName.cg.len.coord -column 0 -row 1 -sticky w
  grid $pathName.cg.len -column 0 -row 1 -sticky new -padx 8 -pady 4
  
  # cgcent
  frame $pathName.cg.cent
  label $pathName.cg.cent.label -text "Center:" -anchor w

  frame $pathName.cg.cent.mol
  radiobutton $pathName.cg.cent.mol.button -anchor w \
    -variable ::APBSRun::elec_temp(cgcent_method) -value "molid"
  eval tk_optionMenu $pathName.cg.cent.mol.id \
    ::APBSRun::elec_temp(cgcent_mol) $file_list
  $pathName.cg.cent.mol.id configure -width 12
  grid $pathName.cg.cent.mol.button -sticky w -column 0 -row 0
  grid $pathName.cg.cent.mol.id -sticky w -column 1 -row 0

  frame $pathName.cg.cent.coord
  radiobutton $pathName.cg.cent.coord.button -anchor w \
    -variable ::APBSRun::elec_temp(cgcent_method) -value "coord"
  label $pathName.cg.cent.coord.xlabel -text "x: "
  entry $pathName.cg.cent.coord.xvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cgcent_x)
  label $pathName.cg.cent.coord.ylabel -text " y: "
  entry $pathName.cg.cent.coord.yvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cgcent_y)
  label $pathName.cg.cent.coord.zlabel -text " z: "
  entry $pathName.cg.cent.coord.zvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(cgcent_z)
  grid $pathName.cg.cent.coord.button -column 0 -row 0 -sticky w
  grid $pathName.cg.cent.coord.xlabel -column 1 -row 0 -sticky w
  grid $pathName.cg.cent.coord.xvalue -column 2 -row 0 -sticky w
  grid $pathName.cg.cent.coord.ylabel -column 3 -row 0 -sticky w
  grid $pathName.cg.cent.coord.yvalue -column 4 -row 0 -sticky w
  grid $pathName.cg.cent.coord.zlabel -column 5 -row 0 -sticky w
  grid $pathName.cg.cent.coord.zvalue -column 6 -row 0 -sticky w

  grid $pathName.cg.cent.label -column 0 -row 0 -sticky w
  grid $pathName.cg.cent.mol -column 0 -row 1 -sticky w
  grid $pathName.cg.cent.coord -column 0 -row 2 -sticky w
  grid $pathName.cg.cent -column 0 -row 2 -padx 8 -pady 4

  grid $pathName.cg -column 0 -row 0 -pady 4

  #
  # Fine Grid
  #
  frame $pathName.fg -relief groove -bd 2
  grid [label $pathName.fg.label -text "Fine Grid Options"] \
    -column 0 -row 0 -sticky w -padx 8 -pady 4

  # fglen
  frame $pathName.fg.len
  label $pathName.fg.len.label -text "Mesh Lengths:"

  frame $pathName.fg.len.coord
  label $pathName.fg.len.coord.xlabel -text "x: "
  entry $pathName.fg.len.coord.xvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(fglen_x)
  label $pathName.fg.len.coord.ylabel -text " y: "
  entry $pathName.fg.len.coord.yvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(fglen_y)
  label $pathName.fg.len.coord.zlabel -text " z: "
  entry $pathName.fg.len.coord.zvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(fglen_z)
  grid $pathName.fg.len.coord.xlabel -column 0 -row 0 -sticky w
  grid $pathName.fg.len.coord.xvalue -column 1 -row 0 -sticky w
  grid $pathName.fg.len.coord.ylabel -column 2 -row 0 -sticky w
  grid $pathName.fg.len.coord.yvalue -column 3 -row 0 -sticky w
  grid $pathName.fg.len.coord.zlabel -column 4 -row 0 -sticky w
  grid $pathName.fg.len.coord.zvalue -column 5 -row 0 -sticky w

  grid $pathName.fg.len.label -column 0 -row 0 -sticky w
  grid $pathName.fg.len.coord -column 0 -row 1 -sticky w
  grid $pathName.fg.len -column 0 -row 1 -sticky new -padx 8 -pady 4
  
  # fgcent
  frame $pathName.fg.cent
  label $pathName.fg.cent.label -text "Center:" -anchor w

  frame $pathName.fg.cent.mol
  radiobutton $pathName.fg.cent.mol.button -anchor w \
    -variable ::APBSRun::elec_temp(fgcent_method) -value "molid"
  eval tk_optionMenu $pathName.fg.cent.mol.id \
    ::APBSRun::elec_temp(fgcent_mol) $file_list
  $pathName.fg.cent.mol.id configure -width 12
  grid $pathName.fg.cent.mol.button -column 0 -row 0 -sticky w
  grid $pathName.fg.cent.mol.id -column 1 -row 0 -sticky w

  frame $pathName.fg.cent.coord
  radiobutton $pathName.fg.cent.coord.button -anchor w \
    -variable ::APBSRun::elec_temp(fgcent_method) -value "coord"
  label $pathName.fg.cent.coord.xlabel -text "x: "
  entry $pathName.fg.cent.coord.xvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(fgcent_x)
  label $pathName.fg.cent.coord.ylabel -text " y: "
  entry $pathName.fg.cent.coord.yvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(fgcent_y)
  label $pathName.fg.cent.coord.zlabel -text " z: "
  entry $pathName.fg.cent.coord.zvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(fgcent_z)
  grid $pathName.fg.cent.coord.button -column 0 -row 0 -sticky w
  grid $pathName.fg.cent.coord.xlabel -column 1 -row 0 -sticky w
  grid $pathName.fg.cent.coord.xvalue -column 2 -row 0 -sticky w
  grid $pathName.fg.cent.coord.ylabel -column 3 -row 0 -sticky w
  grid $pathName.fg.cent.coord.yvalue -column 4 -row 0 -sticky w
  grid $pathName.fg.cent.coord.zlabel -column 5 -row 0 -sticky w
  grid $pathName.fg.cent.coord.zvalue -column 6 -row 0 -sticky w

  grid $pathName.fg.cent.label -column 0 -row 0 -sticky w
  grid $pathName.fg.cent.mol -column 0 -row 1 -sticky w
  grid $pathName.fg.cent.coord -column 0 -row 2 -sticky w
  grid $pathName.fg.cent -column 0 -row 2 -padx 8 -pady 4

  grid $pathName.fg -sticky new -column 0 -row 1 -pady 4
}


# Draw the mg_para frame
proc ::APBSRun::draw_mg_para {pathName} {
  variable elec_temp
  variable file_list

  frame $pathName 

  draw_mg_auto $pathName.mg_auto
  grid $pathName.mg_auto -sticky new -column 0 -row 1 

  # pdime
  frame $pathName.pdime
  label $pathName.pdime.label -text "Number of Processors:"

  frame $pathName.pdime.coord
  label $pathName.pdime.coord.xlabel -text "x: "
  entry $pathName.pdime.coord.xvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(pdime_x)
  label $pathName.pdime.coord.ylabel -text " y: "
  entry $pathName.pdime.coord.yvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(pdime_y)
  label $pathName.pdime.coord.zlabel -text " z: "
  entry $pathName.pdime.coord.zvalue -width 6 \
    -textvariable ::APBSRun::elec_temp(pdime_z)
  grid $pathName.pdime.coord.xlabel -column 0 -row 0 -sticky w
  grid $pathName.pdime.coord.xvalue -column 1 -row 0 -sticky w
  grid $pathName.pdime.coord.ylabel -column 2 -row 0 -sticky w
  grid $pathName.pdime.coord.yvalue -column 3 -row 0 -sticky w
  grid $pathName.pdime.coord.zlabel -column 4 -row 0 -sticky w
  grid $pathName.pdime.coord.zvalue -column 5 -row 0 -sticky w

  grid $pathName.pdime.label -column 0 -row 0 -sticky w
  grid $pathName.pdime.coord -column 0 -row 1 -sticky w
  grid $pathName.pdime -column 0 -row 2 -sticky w -padx 8 -pady {8 4}

  # ofrac
  frame $pathName.ofrac
  label $pathName.ofrac.label -text "Mesh Overlap:"
  entry $pathName.ofrac.entry -width 6 -textvariable ::APBSRun::elec_temp(ofrac)
  grid $pathName.ofrac.label -sticky w -column 0 -row 0
  grid $pathName.ofrac.entry -sticky w -column 1 -row 0
  grid $pathName.ofrac -sticky w -column 0 -row 3 -padx 8 -pady {4 8}
}


proc ::APBSRun::is_integer {args} {
  if { [llength $args] != 1 } {
    return 0
  }

  set x [lindex $args 0]
  if { [catch {incr x 0}] } {
    return 0
  } else {
    return 1
  }
}

proc ::APBSRun::is_real {args} {
  if { [llength $args] != 1 } {
    return 0
  }

  set n [lindex $args 0]
  if { [catch {expr $n + 0}] } {
    return 0
  } else {
    return 1
  }
}

#
# Check for legal APBS grid dimensions:  n = a * 2^b + 1
#   where n is the number of grid points, b is an integer >= 5 
#   (ideally 5), and a is a positive integer.  
#   The test is pretty easy; I simply make sure I can divide 
#   (n-1) by 2 at least 5 times.
#
# Some valid dimension sizes are thus:
#  33, 65, 97, 129, 161, 193, 225, 257, 289, 321, 353, 385, 417, 449, 481, 513,
#  545, 577, 609, 641, 673, 705, 737, 769, 801, 833, 865, 897, 929, 961, 993
#
proc ::APBSRun::is_valid_dime {args} {
  if { ![is_integer $args] } {
    return 0
  }

  set n [lindex $args 0]
  if { $n <= 1 ||
       [expr (32 * round(($n-1)/32))+1] != $n } {
    return 0
  } else {
    return 1
  }
}


# Validate the elec statement return 1 on success, 0 on failure
proc ::APBSRun::elec_check {elec_ref} {
  upvar $elec_ref elec_statement

  # dime - must be (n = a * 2^b + 1)
  if { ![is_valid_dime $elec_statement(dime_x)] ||
       ![is_valid_dime $elec_statement(dime_y)] ||
       ![is_valid_dime $elec_statement(dime_z)] } {
    tk_dialog .errmsg {APBS Tool Error} "Invalid grid dimension: $elec_statement(dime_x) x $elec_statement(dime_y) x $elec_statement(dime_z)" error 0 Dismiss
    return 0
  }

  # (c)gcent
  if { [string equal $elec_statement(cgcent_method) "molid"] } {
    if { [catch {molinfo [string index $elec_statement(cgcent_mol) 0] \
                   get id}] } {
      tk_dialog .errmsg {APBS Tool Error} "Invalid molecule: $elec_statement(cgcent_mol)." error 0 Dismiss
      return 0
    }
  } else {
    if { ![is_real $elec_statement(cgcent_x)] ||
         ![is_real $elec_statement(cgcent_y)] ||
         ![is_real $elec_statement(cgcent_z)] } {
      tk_dialog .errmsg {APBS Tool Error} "Invalid grid center: $elec_statement(cgcent_x), $elec_statement(cgcent_y), $elec_statement(cgcent_z)." error 0 Dismiss
      return 0
    }
  }

  # (c)glen
  if { ![is_real $elec_statement(cglen_x)] ||
       ($elec_statement(cglen_x) <= 0) ||
       ![is_real $elec_statement(cglen_y)] ||
       ($elec_statement(cglen_y) <= 0) ||
       ![is_real $elec_statement(cglen_z)] ||
       ($elec_statement(cglen_z) <= 0) } {
    tk_dialog .errmsg {APBS Tool Error} "Invalid grid lengths: $elec_statement(cglen_x), $elec_statement(cglen_y), $elec_statement(cglen_z)." error 0 Dismiss
    return 0
  }

  if { [string equal $elec_statement(calc_type) "mg-manual"] ||
       [string equal $elec_statement(calc_type) "mg-dummy"] } {
    # nlev must be a positive integer
    if { ![is_integer $elec_statement(nlev)] || 
         ($elec_statement(nlev) <= 0) } {
      tk_dialog .errmsg {APBS Tool Error} "Number of levels must be a positive integer: nlev=$elec_statement(nlev)" error 0 Dismiss
      return 0
    }
  } elseif { [string equal $elec_statement(calc_type) "mg-auto"] ||
             [string equal $elec_statement(calc_type) "mg-para"] } {
    # fgcent
    if { [string equal $elec_statement(fgcent_method) "molid"] } {
      if { [catch {molinfo [string index $elec_statement(fgcent_mol) 0] \
                   get id}] } {
        tk_dialog .errmsg {APBS Tool Error} "Invalid molecule: $elec_statement(fgcent_mol)." error 0 Dismiss
        return 0
      }
    } else {
      if { ![is_real $elec_statement(fgcent_x)] ||
           ![is_real $elec_statement(fgcent_y)] ||
           ![is_real $elec_statement(fgcent_z)] } {
        tk_dialog .errmsg {APBS Tool Error} "Invalid fine grid center: $elec_statement(fgcent_x), $elec_statement(fgcent_y), $elec_statement(fgcent_z)." error 0 Dismiss
        return 0
      }
    }

    # fglen
    if { ![is_real $elec_statement(fglen_x)] ||
         ($elec_statement(fglen_x) <= 0) ||
         ![is_real $elec_statement(fglen_y)] ||
         ($elec_statement(fglen_y) <= 0) ||
         ![is_real $elec_statement(fglen_z)] ||
         ($elec_statement(fglen_z) <= 0) } {
      tk_dialog .errmsg {APBS Tool Error} "Invalid fine grid lengths: $elec_statement(fglen_x), $elec_statement(fglen_y), $elec_statement(fglen_z)." error 0 Dismiss
      return 0
    }

    if {[string equal $elec_statement(calc_type) "mg-para"]} {
      # pdime
      if { ![is_integer $elec_statement(pdime_x)] ||
           ($elec_statement(pdime_x) <= 0) ||
           ![is_integer $elec_statement(pdime_y)] ||
           ($elec_statement(pdime_y) <= 0) ||
           ![is_integer $elec_statement(pdime_z)] ||
           ($elec_statement(pdime_z) <= 0) } {
        tk_dialog .errmsg {APBS Tool Error} "Invalid processor array: $elec_statement(pdime_x), $elec_statement(pdime_y), $elec_statement(pdime_z)." error 0 Dismiss
        return 0
      }
 
      # ofrac
      if { ![is_real $elec_statement(ofrac)] || 
           ($elec_statement(ofrac) <= 0) || ($elec_statement(ofrac) >= 1) } {
        tk_dialog .errmsg {APBS Tool Error} "Mesh overlap must be between 0 an 1: $elec_statement(ofrac)." error 0 Dismiss
        return 0
      }
    }
  } else {
    tk_dialog .errmsg {APBS Tool Error} "Invalid calculation type $elec_statement(calc_type)." error 0 Dismiss
    return 0
  }

  # mol: make sure it's loaded in VMD and has atoms and structure
  if { [catch {molinfo [string index $elec_statement(mol) 0] get id}] ||
       [molinfo [string index $elec_statement(mol) 0] get numatoms] == 0  ||
       [molinfo [string index $elec_statement(mol) 0] get numframes] == 0 } {
    tk_dialog .errmsg {APBS Tool Error} "Invalid molecule: $elec_statement(mol)." error 0 Dismiss
    return 0
  }

  # TODO: Maybe check these; they should always be valid since they're
  # selected from a drop-down menu.
  # lpbe
  # bcfl
  # srfm
  # chgm

  # pdie sdie sdens srad swin temp gamma
  foreach keyword {pdie sdie sdens srad swin temp gamma} {
    if { ![is_real $elec_statement($keyword)] } {
      puts "apbsrun) $keyword invalid"
    }
  }

  # XXX - TODO: writemat, ion.

  return 1
}

# Save the elec statement to current_apbs_config 
# add/edit the entry in the elec_list with the given index
proc ::APBSRun::elec_save {elec_ref} {
  variable elec_win
  variable elec_list
  variable elec_index
  variable elec_current_index
  variable current_apbs_config
  variable apbs_type

  upvar $elec_ref elec_statement 

  # Copy the contents of elec_statement into an element in current_apbs_config

  if {$elec_current_index == $elec_index} {
    # Add an entry to the listbox
    lappend elec_list $elec_current_index
    incr elec_index
    
    # Append the data to current_apbs_config
    lappend current_apbs_config($apbs_type) [array get elec_statement]
  } else {
    # Change an entry in the listbox
    #lset elec_list $index $index

    # Change the data in current_apbs_config
    lset current_apbs_config($apbs_type) $elec_current_index [array get elec_statement]
  }
}

# check existence and readability of output files
proc ::APBSRun::check_maps_ok {} {
  variable output_files
  variable workdir
  variable workdirsuffix

  foreach type $output_files {
    set tf [file join $workdir $workdirsuffix "$type.dx"] 
    if { ![file exists $tf] || ![file readable $tf] || [file size $tf] == 0} {
      puts "apbsrun) Cannot access output file $tf"
      return 0
    }
  }
  return 1
}

# Prompt the user with a list of the maps created by APBS
proc ::APBSRun::prompt_load_maps {} {
  variable main_win
  variable map_win
  variable output_files
  variable load_files
  variable load_files_dest_mol
  set w $main_win

  # If already initialized, just turn on
  if { [winfo exists $w.maps] } {
    wm deiconify $map_win
    return
  }

  set map_win [toplevel "$w.maps"]
  wm title $map_win "APBSRun: Load APBS Maps" 
  wm resizable $map_win yes yes

  # Make this window modal.
  grab $map_win
  wm transient $map_win $w
  wm protocol $map_win WM_DELETE_WINDOW {
    grab release $::APBSRun::map_win
    after idle destroy $::APBSRun::map_win
  }
  raise $map_win

  label $map_win.label -text "APBSRun: Load APBS Maps"
  grid $map_win.label -sticky w -column 0 -row 0

  radiobutton $map_win.loadtopmol \
    -text "Load files into top molecule"  -value "1" \
    -variable ::APBSRun::load_files_dest_mol

  radiobutton $map_win.loadnewmol \
    -text "Load files into a new molecule"  -value "2" \
    -variable ::APBSRun::load_files_dest_mol

  radiobutton $map_win.loadnewmols \
    -text "Load files into separate molecules"  -value "3" \
    -variable ::APBSRun::load_files_dest_mol

  grid $map_win.loadtopmol -sticky w -column 0 -row 1
  grid $map_win.loadnewmol -sticky w -column 0 -row 2
  grid $map_win.loadnewmols -sticky w -column 0 -row 3

  frame $map_win.filelist
  label $map_win.filelist.label -text "Output maps to load:"
  grid $map_win.filelist.label -column 0 -row 0 -sticky w

  array unset load_files

  set i 0
  foreach type $output_files {
    set ::APBSRun::load_files($type) 1        ;# default "on"
    checkbutton $map_win.filelist.$type \
      -text $type -variable ::APBSRun::load_files($type) 
    incr i
    grid $map_win.filelist.$type -sticky w -column 0 -row $i
  }
  grid $map_win.filelist -sticky w -column 0 -row 4

  frame $map_win.buttons
  button $map_win.buttons.okay -text "OK" -width 6 \
    -command {
      ::APBSRun::load_maps
      grab release $::APBSRun::map_win
      after idle destroy $::APBSRun::map_win
    }
  button $map_win.buttons.cancel -text "Cancel" -width 6 \
    -command {
      grab release $::APBSRun::map_win
      after idle destroy $::APBSRun::map_win
    }
  grid $map_win.buttons.okay -sticky w -column 0 -row 0 
  grid $map_win.buttons.cancel -sticky w -column 1 -row 0 
  grid $map_win.buttons -sticky w  -padx 4 -pady 4 -column 0 -row 5
}


# Load the maps into VMD
proc ::APBSRun::load_maps {} {
  variable load_files
  variable workdir
  variable workdirsuffix
  variable load_files_dest_mol

  if { $load_files_dest_mol == 1 } {
    foreach file [array names load_files] {
      if { $load_files($file) } {
        mol addfile [file join $workdir $workdirsuffix "$file.dx"] type dx
      }
    }
  } elseif { $load_files_dest_mol == 2 } {
    set newapbsmol [mol new]
    mol rename $newapbsmol "APBS Output" 
    foreach file [array names load_files] {
      if { $load_files($file) } {
        mol addfile [file join $workdir $workdirsuffix "$file.dx"] type dx
      }
    }
  } else {
    foreach file [array names load_files] {
      if { $load_files($file) } {
        set newapbsmol [mol new [file join $workdir $workdirsuffix "$file.dx"] type dx]
        mol rename $newapbsmol "APBS $file"
      }
    }
  }
}


# This gets called by VMD the first time the menu is opened.
proc apbsrun_tk_cb {} {
  variable foobar
  # Don't destroy the main window, because we want to register the window
  # with VMD and keep reusing it.  The window gets iconified instead of
  # destroyed when closed for any reason.
  #set foobar [catch {after idle destroy $::APBSRun::main_win}] ;# destroy any old windows

  ::APBSRun::apbsrun   ;# start the tool 
  return $APBSRun::main_win
}

