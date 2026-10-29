# consort
A Stata command to flexibly create vertical flowcharts and CONSORT-like diagrams.

The `consort` command provides a simple way to build a vertical flowchart, or a CONSORT-like flow diagram.
All diagram nodes are added step-by-step, and the user has full control over the contents of the data presented.
The flowchart is created as a standard Stata graph, and can be exported in any format supported by Stata.
The default output can be modified by added arrows and plots (e.g. for additional textboxes).

To install the command, run the following command in Stata:
##
    net from "https://szabobarnaki.github.io/consort/"

##
Examples created using `consort`:

<img src="https://szabobarnaki.github.io/consort/crossover.jpg" alt="Minimalistic flowchart displaying a crossover trial design" width="300"/>

<img src="https://szabobarnaki.github.io/consort/rct.jpg" alt="CONSORT-flowchart for a made-up randomized trial" width="600"/>

<img src="https://szabobarnaki.github.io/consort/horse.jpg" alt="Decision pathway to determine whether you are a horse" width="600"/>
