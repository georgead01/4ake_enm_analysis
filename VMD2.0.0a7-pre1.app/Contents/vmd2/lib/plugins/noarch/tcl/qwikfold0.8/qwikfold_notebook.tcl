set global_row 1
########################################################################
# LabelFrame for alphafold configuration ( .cf )
########################################################################
grid [ ttk::labelframe $main_win.job -text "Job name" -relief groove ] \
    -row ${global_row} -column 0 -padx 5 -pady 5 -sticky news

	########################################################################
	# Job ID
	########################################################################
	grid [ttk::entry $main_win.job.id_entry -textvariable QWIKFOLD::job_id ] \
		-column 0 -row 0 -padx 5 -pady 5 

########################################################################
# LabelFrame for run mode configuration ( .model_preset )
########################################################################
grid [ ttk::labelframe $main_win.model_preset -text "Model Preset" -relief groove  ] \
	-row ${global_row} -column 1 -padx 5 -pady 5 -sticky news 

	set model_preset $main_win.model_preset
	
	set opt_list [list "monomer" "monomer_ptm" "monomer_casp14" "multimer" ] 
	grid [ ttk::combobox $model_preset.opt -textvariable QWIKFOLD::model_preset -values $opt_list ] \
		-padx 5 -pady 5 ;#-sticky news 

	# Fill missing space 
	grid columnconfigure $main_win $main_win.model_preset -weight 1


########################################################################
# LabelFrame for run mode configuration ( .af_mode )
########################################################################
grid [ ttk::labelframe $main_win.af_mode -text "Database Preset" -relief groove ] \
	-row ${global_row} -column 2 -padx 5 -pady 5 -sticky nesw

	set af_mode $main_win.af_mode
	
	grid [ttk::radiobutton $af_mode.reduced  -text "Reduced" -variable QWIKFOLD::af_mode -value "reduced_dbs" ] \
		-column 0 -row 0 -padx 5 -pady 5 -sticky nesw
	
	grid [ttk::radiobutton $af_mode.complete -text "Full"    -variable QWIKFOLD::af_mode -value "full_dbs" ] \
		-column 1 -row 0 -padx 5 -pady 5 -sticky nesw

	# Fill missing space 
	#grid columnconfigure $main_win $main_win.af_mode -weight 1


########################################################################
# LabelFrame for FASTA ( .fasta )
########################################################################
incr global_row
grid [ ttk::labelframe $main_win.fasta -text "FASTA sequence" -relief groove ] \
    -row ${global_row} -column 0 -columnspan 3 -padx 5 -pady 5 -sticky news

	# Text field to input FASTA sequence
	grid [ text  $main_win.fasta.sequence -height 10 -width 50 -borderwidth 2 -relief sunken -setgrid true ] \
		-row 0 -columnspan 3 -padx 5 -pady 5 -sticky news -padx 5 -pady 5

    # User feedback was against File-> Load Fasta. Requested "Load Fasta" button
    grid [ttk::entry $main_win.fasta.path -state readonly -textvariable QWIKFOLD::fasta_file ] \
		-row 1 -column 1 -sticky news -padx 5 -pady 5


    grid [ttk::button $main_win.fasta.button -text "FASTA file" -command {QWIKFOLD::load_fasta} -width 10 ] \
		-row 1 -column 0 -sticky ne -padx 5 -pady 5

	# Fill missing space 
	grid columnconfigure $main_win.fasta $main_win.fasta.path -weight 1



########################################################################
# Path to alphaFold2 "cloned" github 
########################################################################
incr global_row
grid [ ttk::labelframe $main_win.af -text "AlphaFold path" -relief groove ] \
	-row ${global_row} -columnspan 3 -padx 5 -pady 5 -sticky nsew

	grid [ttk::entry     $main_win.af.path_entry -state readonly -width 50 -textvariable QWIKFOLD::alphafold_path -validate focus -validatecommand {
			if {[%W get] == "Path to AlphaFold cloned from github"} {
				%W delete 0 end
			} elseif {[%W get] == ""} {
				set QWIKFOLD::alphafold_path "Path to AlphaFold cloned from github"
			}
			return 1
			}] -column 0 -row 0 -padx 5 -pady 5 -sticky nsew

	grid [ttk::button $main_win.af.path_button -text "Browse" -command {
		set dir [tk_chooseDirectory -parent .qwikfold -initialdir [pwd] -title "AlphaFold github path"]
		if {$dir != ""} {
			set QWIKFOLD::alphafold_path $dir}
			}] -column 1 -row 0 -padx 5 -pady 5 

	# Fill missing space 
	grid columnconfigure $main_win.af $main_win.af.path_entry -weight 1

########################################################################
# Base path to alphaFold2 databases 
########################################################################
incr global_row
grid [ ttk::labelframe $main_win.dbs -text "AlphaFold Genetic Databases" -relief groove ] \
    -row ${global_row} -columnspan 3 -padx 5 -pady 5 -sticky nsew

	grid [ttk::entry $main_win.dbs.data_entry -state readonly -width 50 -textvariable QWIKFOLD::alphafold_data -validate focus -validatecommand {
			if {[%W get] == "AlphaFold databases"} {
				%W delete 0 end
			} elseif {[%W get] == ""} {
				set QWIKFOLD::alphafold_data "Path to AlphaFold Genetic Databases"
			}
			return 1
			}] -column 0 -row 0 -padx 5 -pady 5 -sticky nsew

	grid [ttk::button $main_win.dbs.data_button -text "Browse" -command {
		set dir [tk_chooseDirectory -parent .qwikfold -initialdir ~ -title "AlphaFold databases path" ]
		if {$dir != ""} {
			set QWIKFOLD::alphafold_data $dir
			::QWIKFOLD::set_dbs }
			}] -row 0 -column 1 -padx 5 -pady 5 -sticky nsew

	# Fill missing space 
	grid columnconfigure $main_win.dbs $main_win.dbs.data_entry -weight 1


########################################################################
# Path to OUTPUT files
########################################################################
incr global_row
grid [ttk::labelframe $main_win.out -text "Output folder" -relief groove  ] \
	-row ${global_row} -column 0 -columnspan 3 -padx 5 -pady 5 -sticky news

	grid [ttk::entry $main_win.out.entry -state readonly -textvariable QWIKFOLD::output_path ] \
		-row 0 -column 0 -padx 5 -pady 5 -sticky nsew

	grid [ttk::button $main_win.out.button -text "Browse" -command {
		set dir [tk_chooseDirectory -parent .qwikfold -initialdir [pwd] -title "Output folder"]
		if {$dir != ""} {
			set QWIKFOLD::output_path $dir}
			}] -row 0 -column 1 -padx 5 -pady 5 -sticky nsew

	# Fill missing space 
	grid columnconfigure $main_win.out $main_win.out.entry -weight 1


########################################################################
# Load/View results
########################################################################
incr global_row
grid [ ttk::labelframe $main_win.results -text "Analysis" -relief groove ] \
    -row ${global_row} -columnspan 2 -padx 5 -pady 5 -sticky news

	grid [ttk::button $main_win.results.open_folder   -text "Load Results" \
		-command {QWIKFOLD::load_models}  ] -row 0 -column 0 -padx 5 -pady 5 ;#-sticky news
		#MUST ALSO LOAD MODELS!

#	grid [ttk::button $main_win.results.load_models   -text "Read Models" \
#		-command {QWIKFOLD::load_models}  ]  -row 0 -column 1 -padx 5 -pady 5 ;#-sticky news
	
	grid [ttk::button $main_win.results.align_models  -text "Align Models" \
		-command {QWIKFOLD::align_models}  ] -row 0 -column 1 -padx 5 -pady 5 ;#-sticky news

# PAE is only available when _ptm or multimer mode is used.
	grid [ttk::button $main_win.results.load_pae      -text "Prediction Error" \
		-command {QWIKFOLD::load_pae}  ]     -row 0 -column 2 -padx 5 -pady 5 ;#-sticky news


# lDDT should be the main analysis not the last one.
	grid [ttk::button $main_win.results.lddt   -text "pLDDT plot" \
		-command {QWIKFOLD::load_lddt}  ]  -row 1 -column 0 -padx 5 -pady 5 ;#-sticky news


	grid [ttk::button $main_win.results.load_contactmap   -text "Contact Map" \
		-command {QWIKFOLD::load_contacts}  ]  -row 1 -column 1 -padx 5 -pady 5 -sticky news	

# Alignment coverage fails in multimer mode.
#   I should check if Monomer and Multimer mode is selected because output organization changes.
#     Also, there can be missing .sto or .a3m files !
#       What I've done bellow did not work... YET !
	grid [ttk::button $main_win.results.load_coverage   -text "Alignment range" \
		-command {
			if { $QWIKFOLD::model_preset == "multimer" } {
				QWIKFOLD::load_coverage_multimer
				} else {
					QWIKFOLD::load_coverage
				}
		}  ]    -row 1 -column 2 -padx 5 -pady 5 -sticky news



# Model confidence (copied from EMBO)
grid [ ttk::label $main_win.confidence ] \
	-row ${global_row} -column 2 -padx 5 -pady 5 -sticky news

	image create photo imgobj -file "model_confidence.gif" 
	$main_win.confidence configure -image imgobj




########################################################################
# Submit AlphaFold
########################################################################
incr global_row
grid [ ttk::labelframe $main_win.run -text "Review and Submit" -relief groove ] \
    -row ${global_row} -column 0 -columnspan 3 -padx 5 -pady 5 -sticky nswe
	
	grid [ttk::checkbutton $main_win.run.msa -text "Precomputed MSA" -onvalue "yes" -offvalue "no" -variable QWIKFOLD::use_msa ] \
		-row 0 -column 0  -padx 5 -pady 5 -sticky nsew

	grid [ttk::checkbutton $main_win.run.gpy -text "Minimize on GPU" -onvalue "True" -offvalue "False" -variable QWIKFOLD::use_gpu ]  \
		-row 0 -column 1  -padx 5 -pady 5 -sticky nsew

    grid [ttk::button $main_win.run.save -text "Save" -command {QWIKFOLD::save_project} ] \
        -row 0 -column 2 -padx 5 -pady 5 -sticky nsew

    grid [ttk::button $main_win.run.submit -text "Submit" -command {QWIKFOLD::submit} ] \
		-row 0 -column 3 -padx 5 -pady 5 -sticky nsew

	grid [ttk::button $main_win.run.close -text "Close" -command {
      grab release .qwikfold 
      after idle destroy  .qwikfold 
	  	}] \
		-row 0 -column 4 -padx 5 -pady 5 -sticky nsew

	
# Fill missing space 
	grid columnconfigure $main_win $main_win.run -weight 1



########################################################################
# TK Tooltips for guidance
########################################################################

::TKTOOLTIP::balloon $main_win.job "Enter a job name, without spaces.\
\nA \".qwikfold\" extension will be added if not provided."

::TKTOOLTIP::balloon $main_win.model_preset "Model presets define how AlphaFold will run.\
\nAll but \"monomer\" produce a prediction error"

::TKTOOLTIP::balloon $main_win.fasta "Paste or load the aminoacid sequence(s) in FASTA format.\
\nFor MONOMERS, provide just one sequence\
\nAnd multiple sequences for \"multimer\""

::TKTOOLTIP::balloon $main_win.af "Path you the alphafold folder downloaded from github.\
\nIt contains the \"run_alphafold.py\" script and several other required files."

::TKTOOLTIP::balloon $main_win.dbs "Base path you the databases required to run AlphaFold.\
\nThis will autofill the paths for several folders/files required to run.\
\nPlease review install instructions for further information.\
\nOne may customize each of them using \"Settings\" in the menubar"

::TKTOOLTIP::balloon $main_win.out "Browse an output folder for AlphaFold results.\
\nThe results will be named after \"Job Name\" with a \".qwikfold\" extension.
\nThe input sequence(s) will be placed there along with model predictions and quality metrics"

::TKTOOLTIP::balloon $main_win.results "One can load the results from a complete run\
\nUse \"Load results\" to open a .qwickfold project and analyse predictions"

::TKTOOLTIP::balloon $main_win.results.align_models "Align structures of best prediction (ranked_0.pdb)"

::TKTOOLTIP::balloon $main_win.results.load_pae "Plot the Prediction Error Analysis"

::TKTOOLTIP::balloon $main_win.results.lddt "Per-residue confidence score (pLDDT) between 0 and 100.\
\nModel confidence ranges are generally set to:\
\nVery high (pLDDT >90)\
\nConfident (90 > pLDDT > 70)\
\nLow (70 > pLDDT > 50)\
\nVery low (pLDDT < 50)"


# Distogram is actually not quite useable. I'm keeping Contact Map only.
#		grid [ttk::button $main_win.run.results.load_distogram   -text "Distogram" \
#			-command {QWIKFOLD::load_distogram}  ]  -row 1 -column 1 -padx 5 -pady 3 -sticky news

# # MSA using MultiSeq is impractical
# # Simple molecules such as Ubiquitin render about 30K sequences.
# #		grid [ttk::button $main_win.run.an.load_msa   -text "MSA" \
# #			-command {QWIKFOLD::load_msa}  ]       -row 1 -column 0 -padx 5 -pady 5 -sticky news
	


# ########################################################################
# # LabelFrame for alphafold configuration ( .cf )
# ########################################################################
# grid [ ttk::labelframe $main_win.cf -text "Configure" -relief groove ] \
#     -row 0 -column 0 -columnspan 2 -padx 5 -pady 5 -sticky news

# 	########################################################################
# 	# Job ID
# 	########################################################################
# 	grid [ttk::label $main_win.cf.id_label -text "Job name" ] \
#         -column 0 -row 0

# 	grid [ttk::entry $main_win.cf.id_entry -textvariable QWIKFOLD::job_id -validate focus -validatecommand {
# 			if {[%W get] == "myjob"} {
# 				%W delete 0 end
# 			} elseif {[%W get] == ""} {
# 				set QWIKFOLD::job_id "myjob"
# 			}
# 			return 1
# 			}] -column 1 -columnspan 2 -row 0 -sticky news


# 	########################################################################
# 	# Path to OUTPUT files
# 	########################################################################
# 	grid [ttk::label $main_win.cf.output_label -text "Results" ] \
#         -column 0 -row 1
#     grid [ttk::entry $main_win.cf.output_entry -state readonly -textvariable QWIKFOLD::output_path ] \
#         -column 1 -row 1 -sticky news -padx 5 -pady 5

# 	grid [ttk::button $main_win.cf.output_button -text "Browse" -command {
# 		set dir [tk_chooseDirectory -parent .qwikfold -initialdir [pwd] -title "Output folder"]
# 		if {$dir != ""} {
# 			set QWIKFOLD::output_path $dir}
# 			}] -row 1 -column 2 -sticky news -padx 5
