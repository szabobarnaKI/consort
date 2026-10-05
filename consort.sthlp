{smcl}
{* *! version 1.1  22aug2026}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "consort##syntax"}{...}
{viewerjumpto "Description" "consort##description"}{...}
{viewerjumpto "Options" "consort##options"}{...}
{viewerjumpto "Remarks" "consort##remarks"}{...}
{viewerjumpto "Stored results" "consort##results"}{...}
{viewerjumpto "Examples" "consort##examples"}{...}
{title:Title}

{phang}
{bf:consort} {hline 2} Create a CONSORT diagram


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:consort}
{it:subcommand}
[{cmd:,} {it:...}]

{synoptset 27 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt init, }{it:init_options}}initiates a CONSORT diagram{p_end}
{synopt:{opt begin}}synonym for init{p_end}
{synopt:{opt open}}synonym for init{p_end}
{synopt:{opt start}}synonym for init{p_end}
{synopt:{opt add, }{it:add_options}}adds a new node to the diagram{p_end}
{synopt:{opt draw, }{it:draw_options}}draws the diagram as a graph{p_end}
{synoptline}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{synopthdr:suboptions}
{synoptline}
{syntab:{it:init_options}}
{synopt:{opt fr:atio(#)}}sets the mean font width-to-height ratio to # (default=0.5).{p_end}
{synopt:{opt vert:ical_distance(#)}}sets the minimal vertical gap between nodes to # units of text line height (default=2){p_end}
{synopt:{opt betw:een_col_distance(#)}}sets the minimal horizontal gap between node columns to # units of character width (default=4){p_end}
{synopt:{opt off:_node_distance(#)}}sets the minimal horizontal gap between the vertical line and off-nodes to # units of character width (default=2){p_end}

{syntab:{it:add_options}}
{synopt:{opt title(string)}}Title of the node.{p_end}
{synopt:{opt text(string)}}Text of the node.{p_end}
{synopt:{opt titles:ize(#)}}Font size of the node title (default=1).{p_end}
{synopt:{opt texts:ize(#)}}Font size of the node text (default=0.85).{p_end}
{synopt:{opt par:ent_node(#)}}The node ID for the parent node.{p_end}
{synopt:{opt margin_v(#)}}Vertical margins within the node box (default=0.2).{p_end}
{synopt:{opt margin_h(#)}}Horizontal margins within the node box (default=0.5).{p_end}
{synopt:{opt w:idth_multiplier(#)}}Multiplier for the horizontal size of the node box (default=1).{p_end}
{synopt:{opt a:lign(direction)}}Alignment of all text within the node box.{p_end}
{synopt:{cmdab:bgc:olor(}{it:{help colorstyle}}{cmd:)}}Background color of the node box.{p_end}
{synopt:{cmdab:bw:idth(}{it:{help linewidthstyle}}{cmd:)}}Node box border width.{p_end}
{synopt:{cmdab:bc:olor(}{it:{help colorstyle}}{cmd:)}}Node box line color.{p_end}
{synopt:{opt offnode}}Define the actual node as an off-node rather than a regular node.{p_end}
{synopt:{opt right}}The off-node is right-directed.{p_end}
{synopt:{opt hide}}Do not draw the node.{p_end}
{synopt:{opt hidea:rrow}}Do not draw the arrows that originate from this node.{p_end}
{synopt:{opt local(localname)}}The name of the local to store the node ID of the actually added node.{p_end}
{synopt:{opt node_id(#)}}Used only in combination with {opt replace}. The node ID of the node to be replaced.{p_end}
{synopt:{opt replace}}Used only in combination with {opt node_id(#)}. Confirms that a previously added node should be replaced.{p_end}

{syntab:{it:draw_options}}
{synopt:{opt wide}}Force wide format instead of the default narrow format.{p_end}
{synopt:{opt addplot_bg(twoway_plot)}}Additional plot to be added to the background of the CONSORT diagram.{p_end}
{synopt:{opt addplot_fg(twoway_plot)}}Additional plot to be added to the foreground of the CONSORT diagram.{p_end}
{synopt:{opt bottommargin(#)}}The relative height of the within-node margin below the text compared to above the text (default=2).{p_end}
{synopt:{opt text_gap(#)}}The size of the gap between all title and text rows (default=0).{p_end}
{synopt:{opt arrow(coords [coords [...]])}}Start and end coordinates for additional arrows.{p_end}
{synopt:{cmd:barbsize(}{help markersizestyle}{cmd:)}}The filling of the arrowheads, as specified in the {opt barbsize} option of {help twoway pcarrow}.{p_end}
{synopt:{cmd:name(}{it:{help name_option:name,...}}{cmd:)}}Name of the new graph.{p_end}
{synopt:{opt frame(newframename)}}Programmer's option to support debugging. Stores temporary data in a new, permanent frame.{p_end}
{synoptline}



{marker description}{...}
{title:Description}

{pstd}
{cmd:consort} creates a flowchart suitable for creating CONSORT diagrams as image graphs, 
that can be inserted into the output documentation without the need of any external software.

{pstd}
Each node has a node ID. The first, topmost node has node ID 1. For each added node, you can obtain the node ID either by using the {opt local(localname)} option, or from {it:r(node_id)}.{...}
Relations between the added nodes are defined by the node ID. You may add multiple regular nodes to a parent node, but only one off-node.{...}
Regular nodes are placed on the main arrow lines, while off-nodes are exit branches usually used to describe excluded subjects.


{marker options}{...}
{title:Options}

{dlgtab:init_options}

{phang}
{opt fr:atio(#)} sets the mean font width-to-height ratio to # (default=0.5) Stata does not provide exact text widths in graphs. Instead, text width is estimated using the typical width-to-height ratio of that font. This is sometimes inaccurate, especially if the font is not the default, in which case the font ratio may be manually adjusted as needed.

{phang}
{opt vert:ical_distance(#)} sets the minimal vertical gap between nodes to # units of text line height (default=2).

{phang}
{opt betw:een_col_distance(#)} sets the minimal horizontal gap between node columns to # units of character width (default=4).

{phang}
{opt off:_node_distance(#)} sets the minimal horizontal gap between the vertical line and off-nodes to # units of character width (default=2).

{dlgtab:add_options}

{phang}
{opt title(string)} Title of the node. At least one of {opt title()} and {opt text()} needs to be specified.

{phang}
{opt text(string)} Text of the node.  At least one of {opt title()} and {opt text()} needs to be specified.

{phang}
{opt titles:ize(#)} Font size of the node title (default=1).

{phang}
{opt texts:ize(#)} Font size of the node text (default=1).

{phang}
{opt par:ent_node(#)} The node ID of the parent node of the new node to be added.

{phang}
{opt margin_v(#)} Margins within the node box, over the node title and below the text, in text line height units.

{phang}
{opt margin_h(#)} Margins within the node box, on the left and right side of the title and text lines, in character width units.

{phang}
{opt w:idth_multiplier(#)} Multiplier for the horizontal size of the node box. Instead of exact text widths, in Stata the text width is estimated using typical font width-to-height factors, which may be inaccurate.{...}
In such case, you may adjust the horizontal size of each node, as needed.

{phang}
{opt a:lign(direction)} Alignment of the text within the node box. Direction may be either {it:left}, {it:right} or {it:center}.

{phang}
{cmdab:bgc:olor(}{it:{help colorstyle}}{cmd:)} Background color of the node box. If not specified, the graph scheme's default color is used.

{phang}
{cmdab:bw:idth(}{it:{help linewidthstyle}}{cmd:)} Widht of the line of the node box. If not specified, {it:vthin} is used.

{phang}
{cmdab:bc:olor(}{it:{help colorstyle}}{cmd:)} Color of the line of the node box. If not specified, {it:black} is used.

{phang}
{opt offnode} Define the actual node as an off-node rather than a regular node.

{phang}
{opt right} If the actual node is an off-node, it should be placed to the right of the main arrow line. As default, off-nodes are left-placed.

{phang}
{opt hide} Do not draw the node. May be needed if the number of decision levels differs between branches of the CONSORT diagram, but some levels need to be placed at the same row.

{phang}
{opt hidea:rrow} Do not draw the arrows that originate from this node. Arrows ending at this node are still drawn. It may be useful in cross-over design, in combination with arrows added as {it:addedplot}s.

{phang}
{opt local(localname)} The name of the local to store the node ID of the actually added node. A convenience option instead of using {it:r(node_id)}. The node ID is needed if you wish to add a node (regular or off-node) below the actual one.

{phang}
{opt node_id(#)} Used only in combination with {opt replace}. The node ID of the node to be replaced.{...}
{opt node_id} does not need to be defined for newly added nodes.

{phang}
{opt replace} Used only in combination with {opt node_id(#)}. Confirms that a previously added node should be replaced.

{dlgtab:draw_options}

{phang}
{opt wide} Force wide format instead of the default narrow format. In wide format, there is equal space allocated for all node columns, which leads to smaller text and more wasted space, but sometimes a feeling of more symmetry.

{phang}
{opt addplot_bg(twoway_plot)} Additional plot to be added to the background of the CONSORT diagram. These plots are drawn before drawing the nodes and arrows.

{phang}
{opt addplot_fg(twoway_plot)} Additional plot to be added to the foreground of the CONSORT diagram. These plots are drawn after drawing the nodes and arrows.

{phang}
{opt bottommargin(#)} The relative height of the empty within-node space below the last row of the text, compared to the space above the title. Character heights are counted from somewhat higher than the top corner of the 
drawn character image (to account for potential hyphens). Therefore nodes look weirdly asymmetric when using the same height, and more symmetric using double space. If not satisfied, you may change this multiplier 
(it works for all nodes simultaneously).

{phang}
{opt text_gap(#)} The size of the gap between all title and text rows, specified in character heights (default=0). Increase it in case the text seems vertically crowded.{p_end}

{phang}
{opt arrow(coords [coords [...]])} Start and end coordinates for additional arrows. {it:coords} is specified as bunches of 4 numbers (y1 x1 y2 x2) representing the start and end coordinates of straight arrows.{p_end}

{phang}
{cmd:barbsize(}{it:{help markersizestyle}}{cmd:)} The filling of the arrowheads connecting the nodes. Alternatives are given as in the {opt barbsize} option of {help twoway pcarrow}.

{phang}
{cmd:name(}{it:{help name_option:name,...}}{cmd:)} Name of the new graph.

{phang}
{opt frame(newframename)} Programmer's option to support debugging. Stores temporary data in a new, permanent frame.


{marker remarks}{...}
{title:Remarks}

{pstd}
The {cmd:consort} command allows {help smcl} notation in all titles and texts, with the extension that multiple line titles and texts can be added{...}
by inserting the {it:{break}} marker as line breaks. Graph specific {help smcl} markers for Greek letters and notations may also be used, as described in {help graph text}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:consort} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 19 2: Scalars}{p_end}
{synopt:{cmd:r(node_id)}}node ID of the newly added node{p_end}
{synopt:{cmd:r(text_size_unit)}}size of text (in {it:rs} units) corresponding to 1 unit in consort options{p_end}
{synoptset 25 tabbed}{...}
{p2col 5 25 19 2: Matrices}{p_end}
{synopt:{cmd:r(coordinates)}}node box coordinates, as reference for custom added plots and arrows{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{phang}{title:Example 1:} {it:Basic CONSORT flowchart for a randomized trial.}{p_end}

{phang}{cmd:. consort init}{p_end}

{phang}{cmd:. consort add, title(`"{c -(}bf:Enrolment{c )-}"') text("{c -(}&bull{c )-} 1775 patients") local(mainnode) align(center)}{p_end}

{phang}{cmd:. consort add, title(`"{c -(}bf:Randomized to{break}spironolactone{c )-}"') text("{c -(}&bull{c )-} 890 patients") parent_node(`mainnode') local(node2)}{p_end}

{phang}{cmd:. consort add, title(`"{c -(}bf:Randomized to{break}placebo{c )-}"') text("{c -(}&bull{c )-} 885 patients") parent_node(`mainnode') local(node3)}{p_end}

{phang}{cmd:. consort add, title(`"{c -(}bf:Excluded:{c )-}"') text("{c -(}&bull{c )-} 4 patients with missing data") parent_node(`node2') offnode}{p_end}

{phang}{cmd:. consort add, title(`"{c -(}bf:Excluded:{c )-}"') text("{c -(}&bull{c )-} 6 patients with missing data") parent_node(`node3') offnode right}{p_end}

{phang}{cmd:. consort add, title(`"{c -(}bf:Analysis cohort:{c )-}"') text("{c -(}&bull{c )-} 886 patients") parent_node(`node2')}{p_end}

{phang}{cmd:. consort add, title(`"{c -(}bf:Analysis cohort:{c )-}"') text("{c -(}&bull{c )-} 879 patients") parent_node(`node3')}{p_end}

{phang}{cmd:. consort draw, name(consort,replace)}{p_end}


{phang}{title:Example 2:} {it:Study design flowchart for a randomized crossover trial.}{p_end}
{phang}{cmd:. consort init}{p_end}

{phang}{cmd:. consort add, title("{bf:Enrollment}") text("") local(n1) align(center)}{p_end}

{phang}{cmd:. consort add, title("{bf:Randomization}") text("") local(n2) parent_node(`n1') align(center)}{p_end}

{phang}{cmd:. consort add, title("{bf:Drug A}") text("") local(n3) parent_node(`n2') align(center)}{p_end}

{phang}{cmd:. consort add, title("{bf:Drug B}") text("") local(n4) parent_node(`n2') align(center)}{p_end}

{phang}{cmd:. consort add, title("{bf:Washout}") text("") local(n5) parent_node(`n3') align(center) hidearrow}{p_end}

{phang}{cmd:. consort add, title("{bf:Washout}") text("") local(n6) parent_node(`n4') align(center) hidearrow}{p_end}

{phang}{cmd:. consort add, title("{bf:Drug B}") text("") local(n7) parent_node(`n5') align(center)}{p_end}

{phang}{cmd:. consort add, title("{bf:Drug A}") text("") local(n8) parent_node(`n6') align(center)}{p_end}

{phang}{cmd:. consort draw, name(crossover,replace) bottommargin(2) text_gap(0.1)}{p_end}

{phang}{cmd:. local yx1=`"`=r(coordinates)[5,"bottom"]' `=r(coordinates)[5,"right"]'"'}{p_end}

{phang}{cmd:. local yx2=`"`=r(coordinates)[8,"top"]' `=r(coordinates)[8,"left"]'"'}{p_end}

{phang}{cmd:. local yx3=`"`=r(coordinates)[6,"bottom"]' `=r(coordinates)[6,"left"]'"'}{p_end}

{phang}{cmd:. local yx4=`"`=r(coordinates)[7,"top"]' `=r(coordinates)[7,"right"]'"'}{p_end}

{phang}{cmd:. consort draw, name(crossover,replace) bottommargin(2) text_gap(0.1) arrow(`yx1' `yx2' `yx3' `yx4')}{p_end}
