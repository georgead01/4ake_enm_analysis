#
# $Id: qwikfold.tcl,v 1.2 2022/10/04 17:49:20 johns Exp $
#
#==============================================================================
# QwikFold
#
# Authors:
#   Diego E. B. Gomes
#     Auburn University
#     dgomes@auburn.edu
#
#   Rafael C. Bernardi
#     Beckman Institute for Advanced Science and Technology
#       University of Illinois, Urbana-Champaign
#     Auburn University
#     rcbernardi@ks.uiuc.edu
#     http://www.ks.uiuc.edu/~rcbernardi/
#
# Usage:
#   QwikFold was designed to be used exclusively through its GUI,
#   launched from the "Extensions->Simulation" menu.
#
#   Also see http://www.ks.uiuc.edu/Research/vmd/plugins/qwikfold/ for the
#   accompanying documentation.
#
#=============================================================================

package provide qwikfold 0.8


# REMOVE THIS BEFORE RELEASE ##################################
#set env(QWIKFOLDDIR) "/home/dgomes/github/QwikFold/"
################################################################


#font create myDefaultFont -family Helvetica -size 12
#option add *font myDefaultFont

namespace eval ::QWIKFOLD:: {
    namespace export qwikfold
#	variable topGui ".qwikfold"

# 	Window handles
    variable main_win      			;	# handle to main window
    variable settings_win 			;	# handle to settings window
	variable review_win    			;	# handle to review window

#   Job ID will be used as output.
	variable job_id "qwikfold"				;	# Job id
	variable af_mode  "reduced_dbs"			;   # AlphaFold Database mode
	variable model_preset "monomer_ptm" 	;   # monomer, monomer_ptm, monomer_casp14, multimer.
	variable max_template_date "2021-11-01"
#   Where to hold the results
	variable results_folder			;   # Yet to be propagated in more functions

# 	Run options
	variable run_mode "local"		;   # AlphaFold run mode
#	variable alphafold_server		;   # DNS for our server # 	Reserved future use.
	variable use_msa "no"
	variable use_gpu "False"		; # User OpenMM CUDA code.

# 	Original path	
	variable alphafold_path			;#"Path to AlphaFold cloned from github" 
	variable alphafold_data			;#"Path to AlphaFold Genetic Databases"									
	
# 	FASTA variables
	variable fasta_sequence    		;	# Contents of FASTA sequence
	variable fasta_file      		;	# Path to FASTA sequence file to READ   
	variable fasta_input      		;	# Path to FASTA sequence file to AlphaFold

# 	AlphaFold variables
	variable data_params
	variable data_bfd
	variable data_small_bfd
	variable data_mgnify
	variable data_pdb70
	variable data_pdb_mmcif
	variable data_obsolete
	variable data_uniclust30
	variable data_uniref90
	variable data_pdb_seqres
	variable data_uniprot
	
# Dictionary
   variable data_paths
}


proc QWIKFOLD::qwikfold {} {
    global env
	variable main_win 

	# AlphaFold must be properlly installed and user must load its conda environment before to launching VMD.
	catch {set e [exec python -c "import alphafold"]} result
	if { $result != "" } {
		tk_messageBox -message "Could not load QwikFold.\n\nPlease load an AlphaFold conda environment before launching VMD" -icon error -type ok
		return
	}
	
	# Main window
	set           main_win [ toplevel .qwikfold ]
	wm title     $main_win "QwikFold 0.8b" 
	wm resizable $main_win 0 0     ; #Not resizable

	if {[winfo exists $main_win] != 1} {
			raise $main_win

	} else {
			wm deiconify $main_win
	}

    # Source routines
	source $env(QWIKFOLDDIR)/qwikfold_menubar.tcl   ; # Menu Bar - File
	source $env(QWIKFOLDDIR)/qwikfold_settings.tcl  ; # Menu Bar - Edit
	source $env(QWIKFOLDDIR)/qwikfold_notebook.tcl  ; # Main notebook
	source $env(QWIKFOLDDIR)/qwikfold_functions.tcl	; # Functions
	source $env(QWIKFOLDDIR)/qwikfold_sanity_checks.tcl	; # Sanity checks

#    source sun-valley.tcl
#    set_theme light
#     source forest-light.tcl
#     ttk::style theme use forest-light
#     source forest-dark.tcl
#     ttk::style theme use forest-dark


}

# Launch the main window
proc qwikfold {} { return [eval QWIKFOLD::qwikfold]}
#QWIKFOLD::qwikfold

