// consort ado
//# Main command
*! version 1.1 (Barna Szabó-Söderberg 2026.08.22)
program consort, rclass
	version 19.0
	gettoken subcommand 0 : 0 , parse(", ")
	local unrecognized=1
	if inlist(`"`subcommand'"',"init","begin","open","start") {
		// initialize a consort class
		consort_init `0'
		local unrecognized=0
	}
	if `"`subcommand'"'=="add" {
		// add new node
		consort_add `0'
		syntax [anything], [local(string asis)] [*]
		if `"`local'"'!="" c_local `local'=r(node_id)
		local unrecognized=0
	}
	if `"`subcommand'"'=="draw" {
		// draw the graph
		consort_draw `0'
		local unrecognized=0
	}
	if `unrecognized'==1 error 199
	return add
end

//# Check existence of a consort class
program check_existence, rclass
	version 19.0
	quietly classutil dir .Consort
	if "`r(list)'"=="" {
		return scalar exists=0
	}
	else {
		if `.Consort.node_list.arrnels'>0 return scalar exists=1
		else return scalar exists=0
	}
end

//# Init
program consort_init
	version 19.0
	syntax , [FRatio(real 0.5) VERTical_distance(real 2) OFF_node_distance(real 2) BETWeen_col_distance(real 4)]
	capture classutil drop .Consort
	.Consort=.ConsortClass.new
	if `fratio'>0 .Consort.font_ratio=`fratio'
	if `vertical_distance'>0 .Consort.vertical_distance=`vertical_distance'
	if `off_node_distance'>0 .Consort.off_node_distance=`off_node_distance'
	if `between_col_distance'>0 .Consort.between_col_distance=`between_col_distance'
end

//# Add
program consort_add, rclass
	version 19.0
	capture syntax , title(string) [text(string)] [PARent_node(integer 0) OFFNode right ///
		hide HIDEArrow TITLESize(real 1) ///
		TEXTSize(real 0.85) margin_v(real 0.2) margin_h(real 0.5) ///
		BGColor(string asis) BWidth(string asis) BColor(string asis) Align(string asis) ///
		replace node_id(integer 0) local(string asis) ///
		Width_multiplier(real 1)]
	if _rc!=0 {
		syntax , [title(string)] text(string) [PARent_node(integer 0) OFFNode right ///
		hide HIDEArrow TITLESize(real 1) ///
		TEXTSize(real 0.85) margin_v(real 0.2) margin_h(real 0.5) ///
		BGColor(string asis) BWidth(string asis) BColor(string asis) Align(string asis) ///
		replace node_id(integer 0) local(string asis) ///
		Width_multiplier(real 1)]
	}

	if (`parent_node'==0 & `.Consort.node_list.arrnels'!=0) & ("`replace'"=="" | `node_id'==0) {
		noisily di as error "Either parent_node or the combination of replace and node_id needs to be specified."
		error 198
	}
	if (`node_id'!=0) & ("`replace'"=="replace") {
		local node_opt="node_id(`node_id')"
	}
	else if (`node_id'!=0) & (`"`replace'"'=="") {
		noisily di as error "To replace the node with node ID `node_id' you have to specify the replace option as well."
		error 198
	}
	if `node_id'>`.Consort.node_list.arrnels' {
		noisily di as error "The node ID `node_id' is not yet specified, thus it cannot be replaced."
		error 198
	} 
	if `"`bgcolor'"'=="" local bgcolor="bg"
	if `"`bcolor'"'=="" local bcolor="black"
	if `"`bwidth'"'=="" local bwidth="vthin"
	if `"`align'"'=="" local align="left"
	local direction=("`right'"=="right")
	.Consort.Add, parent_node(`parent_node') title(`"`title'"') text(`"`text'"') ///
		`offnode' `hide' `hidearrow' direction(`direction') titlesize(`titlesize') textsize(`textsize') ///
		margin_v(`margin_v') margin_h(`margin_h') bgcolor(`"`bgcolor'"') bwidth(`"`bwidth'"') bcolor(`"`bcolor'"') ///
		align(`"`align'"') `replace' `node_opt' width_multiplier(`width_multiplier')
	return scalar node_id=r(node_id)
end

//# Draw
program consort_draw, rclass
	version 19.0
	// the barely documented frame() option allows debugging
	syntax, [wide addplot_bg(string asis) addplot_fg(string asis) name(string asis) frame(string) bottommargin(real 2) barbsize(string asis) text_gap(real 0) arrow(numlist)*]
	check_existence
	if r(exists)==0 {
		noisily di as error "No consort diagram is defined yet."
		error 199
	}
	// assert `arrow' contains correct number of coordinates
	if "`arrow'"!="" {
		capture assert mod(`: word count `arrow'',4)==0
		if _rc!=0 {
			noisily di as error "Number of arrow coordinates is incorrect."
			error 199
		}
	}
	if "`barbsize'"=="" local barbsize="medsmall"
	if `"`frame'"'=="" {
		tempname draw_frame
	}
	else {
		capture frame drop `frame'
		local draw_frame=`"`frame'"'
	}
	frame create `draw_frame'
	frame `draw_frame': {
		quietly .Consort.ToDataset, frame(`draw_frame')
		 
		// collect row numbers
		quietly generate int rownum=.
		quietly replace rownum=1 if parent_node==0
		sort parent_node node_id
		forvalues i=1/`=_N' {
			if rownum[`i']==. & off_node[`i']==0 {
				quietly summarize rownum if node_id==parent_node[`i'], meanonly
				quietly replace rownum=r(mean)+1 in `i'
			}
			if off_node[`i']==1 {
				quietly summarize rownum if node_id==parent_node[`i'], meanonly
				quietly replace rownum=r(mean) in `i'
			}
		}
		
		// complete with nonvisible nodes if not all paths reach the last row
		// collect if child node exists
		quietly generate byte haschildren=.
		forvalues i=1/`=_N' {
			if off_node[`i']==0 {
				quietly count if parent_node==node_id[`i'] & off_node==0
				quietly replace haschildren=(r(N)>0) in `i'
			}
		}		
		// if there are some end nodes not in end row, complete it
		quietly summarize rownum, meanonly
		local maxrows=r(max)
		quietly levelsof node_id if rownum<`maxrows' & haschild==0, local(node_list)
		foreach i of local node_list {
			local last_node_id=`i'
			quietly summarize rownum if node_id==`i', meanonly
			local endrow=r(mean)
			quietly summarize node_id, meanonly
			local max_node_id=r(max)
			// needed invisible nodes== maxrows-endrow
			local index=_N
			quietly set obs `=_N+`maxrows'-`endrow''
			forvalues j=`=`index'+1'/`=_N' {
				quietly replace node_id=`max_node_id++'+1 in `j'
				quietly replace parent_node=`last_node_id' in `j'
				quietly replace off_node=0 in `j'
				quietly replace off_node_direction=0 in `j'
				quietly replace visible=0 in `j'
				quietly replace hidearrow=1 in `j'
				quietly replace title_size=1 in `j'
				quietly replace text_size=0.85 in `j'
				quietly replace margin_vertical=0.2 in `j'
				quietly replace margin_horizontal=0.5 in `j'
				quietly replace rownum=`endrow++'+1 in `j'
				local last_node_id=`max_node_id'
			}
		}
		
		// add node widths and heights (in characters, the title font line height is 1 unit)
		quietly generate double node_width=0
		quietly generate double node_height=0
		forvalues i=1/`=_N' {
			string_dimensions "`=node_title[`i']'"
			if "`=node_title[`i']'"!=""	quietly replace node_height=node_height[`i']+r(lines)*title_size[`i']+(r(lines)-1)*title_size[`i']*`text_gap' in `i'
			quietly replace node_width=r(width)*title_size[`i']+margin_horizontal[`i']*2 in `i'
			string_dimensions "`=node_text[`i']'"
			if "`=node_text[`i']'"!="" quietly replace node_height=node_height[`i']+r(lines)*text_size[`i']+(r(lines)-1)*text_size[`i']*`text_gap' in `i'
			quietly replace node_width=r(width)*text_size[`i']+margin_horizontal[`i']*2 if node_width<r(width)*text_size[`i']+margin_horizontal[`i']*2 in `i'
			if "`=node_title[`i']'"!="" | "`=node_text[`i']'"!="" quietly replace node_height=node_height[`i']+margin_vertical[`i']*(1+`bottommargin') in `i'
			if "`=node_title[`i']'"!="" & "`=node_text[`i']'"!="" quietly replace node_height=node_height[`i']+`.Consort.title_text_distance'+title_size[`i']*`text_gap' in `i'
		}
		quietly replace node_width=node_width*width_multiplier
		quietly generate double node_width_left=0
		quietly generate double node_width_right=0
		quietly {
			replace node_width_left=node_width/2 if off_node==0
			replace node_width_right=node_width/2 if off_node==0
			replace node_width_left=node_width+`.Consort.off_node_distance' if off_node==1 & off_node_direction==0
			replace node_width_right=node_width+`.Consort.off_node_distance' if off_node==1 & off_node_direction==1
		}
		// node widths are calculated in actual characters

		// find column number for each node
		// note that node_id increases always up to down, and left to right
		sort parent_node node_id
		quietly generate int colnum=1
		quietly replace colnum=. if off_node==1
		sort colnum parent_node node_id
		// do this row by row and correct colnumber each time according to the parent node's colnumber
		quietly generate int parent_col=.
		quietly summarize rownum, meanonly
		forvalues i=1/`=r(max)' {
			quietly levelsof node_id if rownum==`i' & off_node==0, local(nlist)
			foreach j of local nlist {
				quietly summarize parent_node if node_id==`j'
				get_parent_col `=r(mean)', local(parcol)
				quietly replace parent_col=`parcol' if node_id==`j'
			}
			sort rownum parent_col node_id
			quietly replace colnum=colnum[_n-1]+1 if rownum==`i' & rownum==rownum[_n-1] & off_node==0
			quietly replace colnum=1 if rownum==1 & colnum==.
		}
		forvalues i=1/`=_N' {
			if off_node[`i']==1 {
				quietly summarize colnum if node_id==parent_node[`i'], meanonly
				quietly replace colnum=r(mean) in `i'
			}
		}
				
		// calculate mid point for each column
		quietly generate double midline=.
		quietly summarize rownum, meanonly
		local maxrows=r(max)
		quietly summarize colnum if rownum==`maxrows', meanonly
		quietly replace midline=100/r(max)*(colnum-0.5) if rownum==`maxrows' & off_node==0
		forvalues i=`=`maxrows'-1'(-1)1 {
			// calculate midpoint of all children for each column
			quietly summarize colnum if rownum==`i', meanonly
			local maxcol=r(max)
			forvalues j=1/`maxcol' {
				quietly summarize node_id if rownum==`i' & colnum==`j' & off_node==0, meanonly
				local node=r(mean)
				quietly summarize midline if parent_node==`node' & off_node==0, meanonly
				quietly replace midline=(r(max)+r(min))/2 if node_id==`node'
			}
		}
		// copy midlines of parent node for all off-nodes
		forvalues i=1/`=_N' {
			if off_node[`i']==1 {
				quietly summarize midline if node_id==parent_node[`i'], meanonly
				quietly replace midline=r(mean) in `i'
			}
		}

		// calculate xscale based on allocated space per respective width
		if "`wide'"=="wide" { // wide format requested
			local xscale=0
			quietly summarize rownum, meanonly
			local maxrows=r(max)
			forvalues i=1/`maxrows' {
				// calculate node coverage per allocated spaces for each midline to midline or border to midline
				quietly levelsof midline if rownum==`i', local(midlines)
				foreach j of local midlines {
					// check allocated width to the left from actual midline
					quietly summarize midline if rownum==`i' & midline<`j'
					local leftline=cond("`r(max)'"=="",0,r(max))
					quietly summarize node_width_right if rownum==`i' & midline==`leftline'
					if "`r(max)'"!="" local segment_width=r(max)
						else local segment_width=0
					quietly summarize node_width_left if rownum==`i' & midline==`j'
					local segment_width=`segment_width'+r(max)
					if `leftline'!=0 local segment_width=`segment_width'+`.Consort.between_col_distance'
					local xscale=max(`xscale',`segment_width'/(`j'-`leftline'))
				}
				
				// same for right from the last midline
				quietly summarize midline if rownum==`i', meanonly
				local j=r(max)
				quietly summarize node_width_right if rownum==`i' & midline==`j'
				local segment_width=r(max)
				local xscale=max(`xscale',`segment_width'/(100-`j'))
			}
			local xscale=1/`xscale'
			// xscale is now the percent width per character horizontally that is needed to avoid overlaps
		}
		else { // narrow format requested
			local xscale=0
			tempname calc_mat
			quietly summarize rownum, meanonly
			local maxrows=r(max)
			quietly summarize colnum if rownum==`maxrows', meanonly
			local maxcol=r(max)
			matrix `calc_mat'=J(5,`=`maxcol'+1',.) // to collect last row space allocation
			matrix rownames `calc_mat'="midline_l" "midline_r" "segment_width" "cumulative" "new_midline"

			// collect last row distribution (assuming that the widths after the last split represent the widest ones)
			tempname midlines
			quietly levelsof midline if rownum==`maxrows', matrow(`midlines')
			local x=r(r)+1
			forvalues j=1/`x' {
				if `j'>1 {
					matrix `calc_mat'[1,`j']=`midlines'[`=`j'-1',1]
				} 
				if `j'<`x' {
					matrix `calc_mat'[2,`j']=`midlines'[`j',1]
				}
			}
			matrix `calc_mat'[1,1]=0
			matrix `calc_mat'[2,`:colsof `calc_mat'']=100
			tempname segment_width
			forvalues i=1/`=`maxcol'+1' {
				// check allocated width to the left from actual midline
				quietly summarize node_width_right if midline==`calc_mat'[1,`i']
				if "`r(max)'"!="" scalar `segment_width'=r(max)
					else scalar `segment_width'=0
				quietly summarize node_width_left if midline==`calc_mat'[2,`i']
				if "`r(max)'"!="" scalar `segment_width'=`segment_width'+r(max)
				if `calc_mat'[1,`i']!=0 & `calc_mat'[2,`i']!=100 scalar `segment_width'=`segment_width'+`.Consort.between_col_distance'
				matrix `calc_mat'[3,`i']=`segment_width'	
			}

			// rearrange midlines for the last row, then adjust midlines upwards
			matrix `calc_mat'[4,1]=`calc_mat'[3,1]
			forvalues i=2/`=`maxcol'+1' {
				matrix `calc_mat'[4,`i']=`calc_mat'[4,`=`i'-1']+`calc_mat'[3,`i']
			}
			forvalues i=1/`=`maxcol'+1' {
				matrix `calc_mat'[5,`i']=`calc_mat'[4,`i']/`calc_mat'[4,`:colsof `calc_mat'']*100
			}
			quietly generate double newmidline=.
			forvalues i=1/`=`maxcol'+1' {
				quietly replace newmidline=`calc_mat'[5,`i'] if midline==`calc_mat'[2,`i']
			}
			quietly replace midline=newmidline if rownum==`maxrows'
			capture drop newmidline
			// adjust midlines upwards
			forvalues i=`=`maxrows'-1'(-1)1 {
				// calculate midpoint of all children for each column
				quietly summarize colnum if rownum==`i', meanonly
				local maxcol=r(max)
				forvalues j=1/`maxcol' {
					quietly summarize node_id if rownum==`i' & colnum==`j' & off_node==0, meanonly
					local node=r(mean)
					quietly summarize midline if parent_node==`node' & off_node==0, meanonly
					quietly replace midline=(r(max)+r(min))/2 if node_id==`node'
				}
			}
			// copy midlines of parent node for all off-nodes
			forvalues i=1/`=_N' {
				if off_node[`i']==1 {
					quietly summarize midline if node_id==parent_node[`i'], meanonly
					quietly replace midline=r(mean) in `i'
				}
			}

			// calculate xscale
			local xscale=100/`calc_mat'[4,`:colsof `calc_mat'']
			// xscale is now the percent width per character horizontally that is needed to avoid overlaps
		}
		
		// calculate yscale from total height
		local total_height=0
		quietly summarize rownum, meanonly
		local maxrows=r(max)
		forvalues i=1/`maxrows' {
			quietly summarize node_height if rownum==`i' & visible==1 & off_node==0, meanonly
			if "`r(max)'"!="" local total_height=`total_height'+r(max)
			if `i'!=`maxrows' local total_height=`total_height'+`.Consort.vertical_distance'
			quietly summarize node_height if rownum==`i' & visible==1 & off_node==1, meanonly
			if "`r(max)'"!="" local total_height=`total_height'+`.Consort.vertical_distance'+r(max)
		}
		local yscale=100/`total_height'
		// yscale is the percent height of a single row (==1 unit text height)
		
		// calculate node box positions
		quietly generate double c_top=.
		quietly generate double c_bottom=.
		quietly generate double c_left=.
		quietly generate double c_right=.
		quietly summarize rownum, meanonly
		local maxrows=r(max)
		quietly replace c_top=100 if rownum==1 & off_node==0
		quietly replace c_bottom=c_top-node_height*`yscale' if rownum==1 & off_node==0
		quietly count if off_node==1 & parent_node==1
		if r(N)!=0 {
			// eventual top-level off-node
			quietly summarize c_bottom if rownum==1, meanonly
			quietly replace c_top=r(min)-`.Consort.vertical_distance'*`yscale' if rownum==1 & off_node==1 & visible==1
			quietly replace c_bottom=c_top-node_height*`yscale' if rownum==1 & off_node==1 & visible==1
		}
		
		forvalues i=2/`maxrows' {
			quietly summarize c_bottom if rownum<`i', meanonly
			quietly replace c_top=r(min)-`.Consort.vertical_distance'*`yscale' if rownum==`i' & off_node==0 & visible==1
			quietly replace c_bottom=c_top-node_height*`yscale' if rownum==`i' & off_node==0 & visible==1
			// eventual off-node
			quietly summarize c_bottom if rownum==`i', meanonly
			quietly replace c_top=r(min)-`.Consort.vertical_distance'*`yscale' if rownum==`i' & off_node==1 & visible==1
			quietly replace c_bottom=c_top-node_height*`yscale' if rownum==`i' & off_node==1 & visible==1
		}
		
		quietly replace c_left=midline-node_width_left*`xscale' if off_node==0 & visible==1
		quietly replace c_right=midline+node_width_right*`xscale' if off_node==0 & visible==1
		
		quietly replace c_left=midline-(node_width+`.Consort.off_node_distance')*`xscale' if off_node==1 & off_node_direction==0
		quietly replace c_right=midline-`.Consort.off_node_distance'*`xscale' if off_node==1 & off_node_direction==0

		quietly replace c_left=midline+`.Consort.off_node_distance'*`xscale' if off_node==1 & off_node_direction==1
		quietly replace c_right=midline+(node_width+`.Consort.off_node_distance')*`xscale' if off_node==1 & off_node_direction==1

		
		// calculate graph dimensions
		// xscale is now the percent width per character horizontally
		// yscale is the percent height of a single row (==1 unit text height)
		local ysize=10
		local xsize=`ysize'*`yscale'/`xscale'*`.Consort.font_ratio'
		if `xsize'<`ysize' {
			local rs_scale=`yscale'
		}
		else {
			local rs_scale=`yscale'
		}
		if `xsize'>100 {
			local ysize=`ysize'*100/`xsize'
			local xsize=100
		}

		// put the twoway command together
		local extras=" graphregion(margin(medium)) plotregion(margin(zero)) xscale(off range(0 100)) xlabel(,nogrid) yscale(off range(0 100)) ylabel(,nogrid) legend(off) "
		local extras_bg=" msymbol(none) lcolor(black) lwidth(vthin) "
		local extras_line=" msymbol(none) lcolor(black) legend(off) "

		// all nodes are added as separate plots for background and border for each node, to allow individual styles
		local boxes=""
		// add box backgrounds
		forvalues i=1/`=_N' {
			if visible[`i']==1 {
				local boxes=`"`boxes' (scatteri `=c_top[`i']' `=c_left[`i']' `=c_top[`i']' `=c_right[`i']' `=c_bottom[`i']' `=c_right[`i']' `=c_bottom[`i']' `=c_left[`i']', `extras_bg' nodropbase fcolor(`=background_color[`i']') recast(area))"'
			}
		}
		// add box borders
		forvalues i=1/`=_N' {
			if visible[`i']==1 {
				local boxes=`"`boxes' (scatteri `=c_top[`i']' `=c_left[`i']' `=c_top[`i']' `=c_right[`i']' `=c_bottom[`i']' `=c_right[`i']' `=c_bottom[`i']' `=c_left[`i']' `=c_top[`i']' `=c_left[`i']', msymbol(none) lcolor(`=border_color[`i']') lwidth(`=border_width[`i']') recast(connected))"'
			}
		}
		
		// add text
		// all titles and texts are split into rows and added as separate "text(...)" options per row
		local text_yx=""
		forvalues i=1/`=_N' {
			if visible[`i']==1 {
				// add title row
				local title=node_title[`i']
				local text=node_text[`i']
				if `"`title'"'!="" {
					if align[`i']=="left" {
						local hpos=c_left[`i']+margin_horizontal[`i']*`xscale'
						local clck="(3)"
						local rowmid=c_top[`i']-0.5*`rs_scale'*title_size[`i']-margin_vertical[`i']*`rs_scale'
					}
					if align[`i']=="right" {
						local hpos=c_right[`i']-margin_horizontal[`i']*`xscale'
						local clck="(9)"
						local rowmid=c_top[`i']-0.5*`rs_scale'*title_size[`i']-margin_vertical[`i']*`rs_scale'
					}
					if align[`i']=="center" {
						local hpos=(c_left[`i']+c_right[`i'])/2
						local clck="(6)"
						local rowmid=c_top[`i']-margin_vertical[`i']*`rs_scale'
					}
					while `"`title'"'!="" {
						// get first row
						local pos=strpos(`"`title'"',"{break}")
						if `pos'==0 {
							local rowtext=`"`title'"'
							local title=""
						}
						else {
							local rowtext=substr(`"`title'"',1,`=`pos'-1')
							local title=substr(`"`title'"',`=`pos'+7',`=strlen(`"`title'"')-`pos'-6')
						}
						local text_yx=`"`text_yx' text(`rowmid' `hpos' `"`rowtext'"', placement`clck' size(`=title_size[`i']*`rs_scale''rs) justification(`=align[`i']'))"'
						local rowmid=`rowmid'-title_size[`i']*`rs_scale'
						if "`title'"!="" local rowmid=`rowmid'-title_size[`i']*`text_gap'*`rs_scale'
					}
					// correct rowmid for different character heights in title and text
					if align[`i']!="center" {
						local rowmid=`rowmid'+(title_size[`i']*`rs_scale')/2
						local rowmid=`rowmid'-(text_size[`i']*`rs_scale')/2
					}
					local rowmid=`rowmid'-(title_size[`i']*`rs_scale'*`.Consort.title_text_distance')-(title_size[`i']*`rs_scale'*`text_gap')
				}
				else { // no title specified
					if align[`i']=="left" {
						local hpos=c_left[`i']+margin_horizontal[`i']*`xscale'
						local clck="(3)"
						local rowmid=c_top[`i']-0.5*`rs_scale'*text_size[`i']-margin_vertical[`i']*`rs_scale'
					}
					if align[`i']=="right" {
						local hpos=c_right[`i']-margin_horizontal[`i']*`xscale'
						local clck="(9)"
						local rowmid=c_top[`i']-0.5*`rs_scale'*text_size[`i']-margin_vertical[`i']*`rs_scale'
					}
					if align[`i']=="center" {
						local hpos=(c_left[`i']+c_right[`i'])/2
						local clck="(6)"
						local rowmid=c_top[`i']-margin_vertical[`i']*`rs_scale'
					}
				}
				
				// add text rows
				while `"`text'"'!="" {
					// get first row
					local pos=strpos(`"`text'"',"{break}")
					if `pos'==0 {
						local rowtext=`"`text'"'
						local text=""
					}
					else {
						local rowtext=substr(`"`text'"',1,`=`pos'-1')
						local text=substr(`"`text'"',`=`pos'+7',`=strlen(`"`text'"')-`pos'-6')
					}
					local text_yx=`"`text_yx' text(`rowmid' `hpos' `"`rowtext'"', placement`clck' size(`=text_size[`i']*`rs_scale''rs) justification(`=align[`i']'))"'
					local rowmid=`rowmid'-(text_size[`i']*`rs_scale')
					if "`text'"!="" local rowmid=`rowmid'-(text_size[`i']*`text_gap'*`rs_scale')
				}
			}
		}
		// add connecting lines and arrows
		// these are built from line segments without arrowhead, and the last line segment with arrowhead
		local lines_yx=""
		local arrow_yx=""
		forvalues i=1/`=_N' {
			quietly summarize visible if node_id==parent_node[`i'], meanonly
			local vis=(visible[`i']==1) & (r(mean)==1)
			quietly summarize hidearrow if node_id==parent_node[`i'], meanonly
			local vis=`vis' & (r(mean)==0)
			if `vis'==1 {
				// add arrow from parent to this
				// first, find the bottom of all nodes in parent node's row
				// then find half distance to this node
				// split the line into parts depending on the type of this node

				if off_node[`i']==0 {
					// this is not an off_node
					// parent node bottom middle:
					quietly summarize c_bottom if node_id==parent_node[`i'], meanonly
					local start_y=r(mean)
					quietly summarize c_left if node_id==parent_node[`i'], meanonly
					local start_x=r(mean)
					quietly summarize c_right if node_id==parent_node[`i'], meanonly
					local start_x=(`start_x'+r(mean))/2

					// bend point below parent node
					quietly summarize rownum if node_id==parent_node[`i'], meanonly
					quietly summarize c_bottom if rownum==r(mean), meanonly
					local bend1_y=(r(min)+c_top[`i'])/2
					local bend1_x=`start_x'
					
					// bend point above this node
					local bend2_y=`bend1_y'
					local bend2_x=(c_left[`i']+c_right[`i'])/2

					// this node top middle
					local stop_y=c_top[`i']
					local stop_x=`bend2_x'

					local lines_yx="`lines_yx' `start_y' `start_x' `bend1_y' `bend1_x' `bend1_y' `bend1_x' `bend2_y' `bend2_x'"
					local arrow_yx="`arrow_yx' `bend2_y' `bend2_x' `stop_y' `stop_x'"
				}
				else {
					// this is an off_node
					// parent node bottom middle:
					quietly summarize c_bottom if node_id==parent_node[`i'], meanonly
					local start_y=r(mean)
					quietly summarize c_left if node_id==parent_node[`i'], meanonly
					local start_x=r(mean)
					quietly summarize c_right if node_id==parent_node[`i'], meanonly
					local start_x=(`start_x'+r(mean))/2

					// bend point below parent node
					local bend1_y=(c_top[`i']+c_bottom[`i'])/2
					local bend1_x=`start_x'
					
					// this node side middle
					local stop_y=`bend1_y'
					if off_node_direction[`i']==0 {
						// left directed off_node
						local stop_x=c_right[`i']
					}
					else {
						// right directed off_node
						local stop_x=c_left[`i']
					}
						
					local lines_yx="`lines_yx' `start_y' `start_x' `bend1_y' `bend1_x'"
					local arrow_yx="`arrow_yx' `bend1_y' `bend1_x' `stop_y' `stop_x'"
				}
				
			}
		}
		if "`lines_yx'"!="" {
			local line_plots=`"(pci `lines_yx', `extras_line' lwidth(`.Consort.arrowwidth'))"'
		}
		if "`arrow_yx'"!="" {
			local arrow_plots=`"(pci `arrow_yx' `arrow', msize(`=`.Consort.arrowsize'*`rs_scale'') mcolor(black) lcolor(black) lwidth(`.Consort.arrowwidth') barbsize(`barbsize') recast(pcarrow))"'
		}

		// draw all
		twoway `addplot_bg' `boxes' `line_plots' `arrow_plots' `addplot_fg' , `extras' `text_yx' ysize(`ysize') xsize(`xsize') name(`name')

		// return coordinates and text size
		return clear
		return scalar text_size_unit=`rs_scale'
		tempname ret_matrix
		matrix `ret_matrix'=J(`=_N',5,.)
		matrix colnames `ret_matrix'="node_id" "left" "right" "top" "bottom" 
		forvalues i=1/`=_N' {
			matrix `ret_matrix'[`i',1]=node_id[`i']
			matrix `ret_matrix'[`i',2]=c_left[`i']
			matrix `ret_matrix'[`i',3]=c_right[`i']
			matrix `ret_matrix'[`i',4]=c_top[`i']
			matrix `ret_matrix'[`i',5]=c_bottom[`i']
		}
		return matrix coordinates=`ret_matrix'
	}
end

program define get_parent_col
	version 19.0
	syntax anything, local(string asis)
	quietly summarize colnum if node_id==`anything', meanonly
	c_local `local'=r(mean)
end

//# String dimensions 
program define string_dimensions, rclass
	version 19.0
	syntax anything, [feedback]
	if "`feedback'"=="feedback" noisily di as result _asis `"`anything'"'
	local rowcount=0
	local stringwidth=0
	local string_in=ustrto(`anything',"ascii",1)
	if strpos(`"`string_in'"',"{&")!=0 {
		// graph specific notations are present (if correctly specified), that are drawn as a single character and thus should be counted as 1 character
		local notation_list="Alpha Beta Gamma Delta Epsilon Zeta Eta Theta Iota Kappa Lambda "
		local notation_list="`notation_list' Mu Nu Xi Omicron Pi Rho Sigma Tau Upsilon Phi Chi Psi Omega "
		local notation_list="`notation_list' alpha beta gamma delta epsilon zeta eta theta thetasym iota kappa lambda "
		local notation_list="`notation_list' mu nu xi omicron pi piv rho sigma sigmaf tau upsilon upsih phi chi psi omega "
		local notation_list="`notation_list' weierp image imaginary real alefsym amp lt gt le ge ne fnof function forall part exist empty nabla isin "
		local notation_list="`notation_list' element notin prod sum minus plusmn plusminus lowast radic sqrt prop infin infinity ang angle and or cap "
		local notation_list="`notation_list' intersect cup union int integral there4 therefore sim cong asymp equiv sub subset sup superset nsub nsubset sube supersete oplus "
		local notation_list="`notation_list' otimes perp orthog sdot dot prime Prime frasl larr uarr rarr darr harr crarr lArr uArr rArr dArr hArr "
		local notation_list="`notation_list' trade trademark reg copy copyright bull bullet hellip ellipsis loz lozenge diamond spades clubs hearts diams diamonds degree"
		foreach notation of local notation_list {
			local string_in=subinstr(`"`string_in'"',"{&`notation'}","a",.)
		}
	}
	
	quietly {
		tempname myfile 
		tempfile file_smcl file_txt
		file open `myfile' using `file_smcl', write text replace
		file write `myfile' `"`string_in'"' _n
		file close `myfile'
		translate `file_smcl' `file_txt', replace translator(smcl2txt) header(off) logo(off) cmdnumber(off) lmargin(0)

		file open `myfile' using `file_txt', read text
		forvalues i=1/100 { // max 100 rows for safety reasons
			file read `myfile' s
			if !(r(eof)==1 & strlen(`"`s'"')==0) { // valid row
				local stringwidth=max(strlen(`"`s'"'),`stringwidth')
				local rowcount=`rowcount'+1
			}
			if r(eof)==1 {
				continue, break
			}
		}

		file close `myfile'
	}
	return scalar width=`stringwidth'
	return scalar lines=`rowcount'
end
