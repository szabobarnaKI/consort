{smcl}
{* *! version 1.0.2  25oct2026}{...}
{title:Title}

{phang}
{bf:rep_options} {hline 2} Extract the contents of a repeatable option from a string


{title:Syntax}

{p 8 17 2}
{cmd:rep_options} {it:optname} [{cmd:,} {it:options}] {cmd::} {it:string}

{synoptset 16}{...}
{synopthdr}
{synoptline}
{synopt:{opt min(#)}}require at least {it:#} instances; default {cmd:min(0)}{p_end}
{synopt:{opt max(#)}}allow at most {it:#} instances; default {cmd:max(-1)} (no limit){p_end}
{synopt:{opt cmd:line}}{it:string} is a full command line; options exist only after a top-level comma{p_end}
{synopt:{opt opts:only}}{it:string} contains options only; commas are never treated as the options separator{p_end}
{synoptline}

{pstd}
{it:optname} follows Stata's abbreviation convention: leading capital letters
give the minimum abbreviation. {cmd:COVariate} matches {cmd:cov()} through
{cmd:covariate()}; {cmd:cov} (no capitals) matches only {cmd:cov()}. A trailing
argument description such as {cmd:COVariate(string)} is allowed and ignored.


{title:Description}

{pstd}
{cmd:rep_options} scans {it:string} {hline 1} typically a parent command's
{cmd:`0'} or its {cmd:`options'} {hline 1} for every instance of option
{it:optname} and returns the contents of each instance in {cmd:r()}, together
with the string with those instances removed. This makes it easy to support
repeatable options, which {helpb syntax} does not.

{pstd}
By default, if {it:string} contains a comma outside parentheses, brackets and
quotes, only the text after the first such comma is scanned; otherwise the whole
string is treated as options. Contents are returned verbatim, including nested
parentheses, simple and compound double quotes. {it:optname} without
parentheses (a bare flag) and {it:optname}{cmd:()} both count as instances with
empty contents. The opening parenthesis must immediately follow the name:
{cmd:cov (x)} is not {cmd:cov(x)}; it is read as a bare {cmd:cov} (an instance
with empty contents) followed by a separate {cmd:(x)} token, which is left in
{cmd:r(otheropts)} and {cmd:r(rest)}.


{title:Examples}

{pstd}Inside a parent command{p_end}
{phang2}{cmd:program define mycmd}{p_end}
{phang2}{cmd:    syntax varlist [if] [in] [, *]}{p_end}
{phang2}{cmd:    rep_options COVariate, min(1) : `options'}{p_end}
{phang2}{cmd:    local covlist `"`r(list)'"'}{p_end}
{phang2}{cmd:    local 0 `", `r(rest)'"'}{p_end}
{phang2}{cmd:    syntax [, Robust Level(cilevel)]}{p_end}
{phang2}{cmd:    foreach c of local covlist {c -(}}{p_end}
{phang2}{cmd:        display `"covariate(): `c'"'}{p_end}
{phang2}{cmd:    {c )-}}{p_end}
{phang2}{cmd:end}{p_end}

{pstd}Whole command line{p_end}
{phang2}{cmd:. rep_options cov : y x if a>1, cov(a b) cov("c, d") nolog}{p_end}
{phang2}{cmd:. return list}{p_end}

{pstd}
If the string can contain literal macro characters, pass it with
{cmd:`macval(0)'} or {cmd:`macval(options)'}.


{title:Stored results}

{pstd}
{cmd:rep_options} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(n)}}number of instances found{p_end}

{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(option)}}full (lowercase) option name{p_end}
{synopt:{cmd:r(arg}{it:#}{cmd:)}}contents of instance {it:#}, in order of appearance (not stored if empty){p_end}
{synopt:{cmd:r(list)}}all contents, each in compound double quotes; use with {cmd:foreach ... of local}{p_end}
{synopt:{cmd:r(merged)}}nonempty contents, trimmed and joined by spaces{p_end}
{synopt:{cmd:r(otheropts)}}remaining (non-matching) options{p_end}
{synopt:{cmd:r(rest)}}{it:string} with all instances removed (comma dropped if no options remain){p_end}


{title:Remarks}

{pstd}
Because {cmd:rep_options} is r-class, call it before posting your own
{cmd:r()} results and copy what you need into locals first.
