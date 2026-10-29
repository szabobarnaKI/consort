*! version 1.0.2  25oct2026
*! rep_options: extract the contents of a repeatable option from a string
*!
*! Syntax:  rep_options optname [, min(#) max(#) cmdline optsonly] : string
*!
*! optname follows Stata's abbreviation convention: leading capital letters
*! mark the minimum abbreviation (e.g. COVariate accepts cov ... covariate).
*! An optname written without capitals must be typed in full.

program define rep_options, rclass
    version 15

    * split "spec : string" on the first colon (done in Mata so the string
    * is never re-expanded or re-tokenized by Stata)
    mata: _repopt_split()

    local 0 `"`repspec'"'
    syntax anything(name=optspec id="option name") ///
        [, MIN(integer 0) MAX(integer -1) CMDline OPTSonly]

    if "`cmdline'" != "" & "`optsonly'" != "" {
        di as err "options cmdline and optsonly may not be combined"
        exit 184
    }
    if `min' < 0 {
        di as err "min() must be a nonnegative integer"
        exit 198
    }
    if `max' < -1 {
        di as err "max() must be a nonnegative integer (or -1 for no limit)"
        exit 198
    }
    if `max' != -1 & `max' < `min' {
        di as err "max() may not be smaller than min()"
        exit 198
    }

    local mode = cond("`cmdline'" != "", 1, cond("`optsonly'" != "", 2, 0))

    * parses repstr; results come back in locals _ro_*
    mata: _repopt_main()

    * post results (macval() keeps contents verbatim, e.g. $ or `)
    return scalar n = `_ro_n'
    forvalues k = 1/`_ro_n' {
        return local arg`k' `"`macval(_ro_arg`k')'"'
    }
    return local option    `"`_ro_option'"'
    return local list      `"`macval(_ro_list)'"'
    return local merged    `"`macval(_ro_merged)'"'
    return local otheropts `"`macval(_ro_otheropts)'"'
    return local rest      `"`macval(_ro_rest)'"'
end


version 15
mata:
mata set matastrict on

/* ---------------------------------------------------------------- */
/* split the program arguments on the first colon                   */
/* ---------------------------------------------------------------- */
void _repopt_split()
{
    string scalar z
    real scalar   p

    z = st_local("0")
    p = strpos(z, ":")
    if (p == 0) {
        errprintf("colon required\n")
        errprintf("syntax is: rep_options optname [, options] : string\n")
        exit(198)
    }
    st_local("repspec", substr(z, 1, p - 1))
    st_local("repstr",  strtrim(substr(z, p + 1, .)))
}

/* ---------------------------------------------------------------- */
/* character helpers                                                */
/* ---------------------------------------------------------------- */
real scalar _repopt_isws(string scalar c)
{
    return(c == " " | c == char(9) | c == char(10) | c == char(13))
}

real scalar _repopt_validname(string scalar s)
{
    real scalar i, a

    if (strlen(s) == 0) return(0)
    for (i = 1; i <= strlen(s); i++) {
        a = ascii(substr(s, i, 1))
        if (a >= 65 & a <= 90)  continue
        if (a >= 97 & a <= 122) continue
        if (a == 95)            continue
        if (a >= 48 & a <= 57 & i > 1) continue
        return(0)
    }
    return(1)
}

/* position of the last character of the quoted string starting at i
   (simple double quotes or nestable compound double quotes);
   returns i if no quote starts at i, strlen(s) if unterminated      */
real scalar _repopt_qend(string scalar s, real scalar i)
{
    real scalar   k, L, lev
    string scalar BT, DQ, SQ

    BT = char(96)
    DQ = char(34)
    SQ = char(39)
    L  = strlen(s)

    if (substr(s, i, 2) == BT + DQ) {
        lev = 1
        k   = i + 2
        while (k <= L) {
            if (substr(s, k, 2) == BT + DQ) {
                lev++
                k = k + 2
            }
            else if (substr(s, k, 2) == DQ + SQ) {
                lev--
                if (lev == 0) return(k + 1)
                k = k + 2
            }
            else k++
        }
        return(L)
    }
    if (substr(s, i, 1) == DQ) {
        k = strpos(substr(s, i + 1, .), DQ)
        if (k == 0) return(L)
        return(i + k)
    }
    return(i)
}

/* position of the first comma outside parentheses, brackets and quotes */
real scalar _repopt_findcomma(string scalar s)
{
    real scalar   i, L, depth
    string scalar c, BT, DQ

    BT    = char(96)
    DQ    = char(34)
    L     = strlen(s)
    depth = 0
    for (i = 1; i <= L; i++) {
        c = substr(s, i, 1)
        if (c == DQ | substr(s, i, 2) == BT + DQ) {
            i = _repopt_qend(s, i)
            continue
        }
        if (c == "(" | c == "[") depth++
        else if (c == ")" | c == "]") {
            if (depth > 0) depth--
        }
        else if (c == "," & depth == 0) return(i)
    }
    return(0)
}

/* position of the ")" matching the "(" at position i; 0 if none */
real scalar _repopt_matchparen(string scalar s, real scalar i)
{
    real scalar   k, L, depth
    string scalar c, BT, DQ

    BT    = char(96)
    DQ    = char(34)
    L     = strlen(s)
    depth = 0
    for (k = i; k <= L; k++) {
        c = substr(s, k, 1)
        if (c == DQ | substr(s, k, 2) == BT + DQ) {
            k = _repopt_qend(s, k)
            continue
        }
        if (c == "(") depth++
        else if (c == ")") {
            depth--
            if (depth == 0) return(k)
        }
    }
    return(0)
}

/* does typed name nm match option full with minimum abbreviation minlen */
real scalar _repopt_match(string scalar nm, string scalar full,
                          real scalar minlen)
{
    real scalar l

    l = strlen(nm)
    if (l < minlen | l > strlen(full)) return(0)
    return(nm == substr(full, 1, l))
}

/* ---------------------------------------------------------------- */
/* main routine                                                     */
/* ---------------------------------------------------------------- */
void _repopt_main()
{
    string scalar    s, spec, full, before, o, c, nm, content, tok
    string scalar    other, rest, lst, merged, BT, DQ, SQ
    real scalar      mode, mn, mx, p, minlen, L, i, j, e, tstart
    real scalar      n, k, hascomma
    string colvector args

    BT = char(96)
    DQ = char(34)
    SQ = char(39)

    s    = st_local("repstr")
    spec = strtrim(st_local("optspec"))
    mode = strtoreal(st_local("mode"))
    mn   = strtoreal(st_local("min"))
    mx   = strtoreal(st_local("max"))

    /* --- option specification: name, minimum abbreviation --- */
    p = strpos(spec, "(")
    if (p) spec = strtrim(substr(spec, 1, p - 1))
    if (!_repopt_validname(spec)) {
        errprintf("%s: invalid option name\n", spec)
        exit(198)
    }
    full   = strlower(spec)
    minlen = 0
    while (minlen < strlen(spec)) {
        k = ascii(substr(spec, minlen + 1, 1))
        if (k < 65 | k > 90) break
        minlen++
    }
    if (minlen == 0) minlen = strlen(full)

    /* --- isolate the options part --- */
    hascomma = 0
    p = (mode == 2 ? 0 : _repopt_findcomma(s))
    if (p > 0) {
        before   = substr(s, 1, p - 1)
        o        = substr(s, p + 1, .)
        hascomma = 1
    }
    else if (mode == 1) {
        before = s
        o      = ""
    }
    else {
        before = ""
        o      = s
    }

    /* --- scan option tokens: name[ ](contents) --- */
    args  = J(0, 1, "")
    other = ""
    L     = strlen(o)
    i     = 1
    while (i <= L) {
        while (i <= L) {
            if (!_repopt_isws(substr(o, i, 1))) break
            i++
        }
        if (i > L) break

        tstart = i
        while (i <= L) {
            c = substr(o, i, 1)
            if (_repopt_isws(c) | c == "(") break
            if (c == DQ | substr(o, i, 2) == BT + DQ) i = _repopt_qend(o, i)
            i++
        }
        nm = substr(o, tstart, i - tstart)

        /* contents only if "(" immediately follows the name:
           cov(x) has contents x; cov (x) is a bare cov plus a
           separate "(x)" token                                   */
        j = i
        content = ""
        if (j <= L) {
            if (substr(o, j, 1) == "(") {
                e = _repopt_matchparen(o, j)
                if (e == 0) {
                    errprintf("too few ')' or ']'\n")
                    exit(132)
                }
                content = substr(o, j + 1, e - j - 1)
                i = e + 1
            }
        }
        tok = substr(o, tstart, i - tstart)

        if (_repopt_match(nm, full, minlen)) args = args \ content
        else other = other + (other == "" ? "" : " ") + tok
    }
    n = rows(args)

    /* --- count restrictions --- */
    if (mn > 0 & n < mn) {
        if (mn == 1) errprintf("option %s() required\n", full)
        else errprintf("option %s() must be specified at least %g times\n",
                       full, mn)
        exit(198)
    }
    if (mx >= 0 & n > mx) {
        if (mx == 0) errprintf("option %s() not allowed\n", full)
        else errprintf("option %s() may be specified at most %g times\n",
                       full, mx)
        exit(198)
    }

    /* --- remaining string --- */
    if (hascomma) {
        if (other != "") rest = strrtrim(before) + ", " + other
        else             rest = strrtrim(before)
    }
    else if (mode == 1) rest = before
    else                rest = other
    rest = strtrim(rest)

    /* --- lists --- */
    lst    = ""
    merged = ""
    for (k = 1; k <= n; k++) {
        lst = lst + (k > 1 ? " " : "") + BT + DQ + args[k] + DQ + SQ
        if (strtrim(args[k]) != "") {
            merged = merged + (merged == "" ? "" : " ") + strtrim(args[k])
        }
    }

    /* --- hand results back to the ado as locals; the ado posts them
           with -return- (r() set directly from Mata does not survive
           the exit of an rclass program)                           --- */
    st_local("_ro_n", strofreal(n))
    for (k = 1; k <= n; k++) {
        st_local("_ro_arg" + strofreal(k), args[k])
    }
    st_local("_ro_option",    full)
    st_local("_ro_list",      lst)
    st_local("_ro_merged",    merged)
    st_local("_ro_otheropts", other)
    st_local("_ro_rest",      rest)
}

end
