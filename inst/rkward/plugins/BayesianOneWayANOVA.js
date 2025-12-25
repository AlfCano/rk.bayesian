// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(BayesFactor)\n");	echo("require(dplyr)\n");	echo("require(ggpubr)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    function parseVar(fullPath) {
        if (!fullPath) return {df: '', col: '', raw_col: ''};
        var df = '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            df = parts[0];
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/["']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            var parts = fullPath.split('$');
            df = parts[0];
            raw_col = parts[1];
        } else {
            raw_col = fullPath;
        }
        return { df: df, raw_col: raw_col };
    }
  
    var dv=getValue("ba_dv"); var fac=getValue("ba_fac"); var desc=getValue("ba_desc");
    var p_dv=parseVar(dv); var p_fac=parseVar(fac); var df=p_dv.df; var fmla=p_dv.raw_col+"~"+p_fac.raw_col;
    
    echo("bf_anova <- BayesFactor::anovaBF(formula = " + fmla + ", data = as.data.frame(" + df + "))\n");
    
    if (desc == "1") {
        echo("desc_tab <- " + df + " %>% group_by(" + p_fac.raw_col + ") %>% summarise(N=n(), Mean=mean(" + p_dv.raw_col + ", na.rm=T), SD=sd(" + p_dv.raw_col + ", na.rm=T))\n");
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Bayesian One-Way ANOVA results")).print();

    function parseVar(fullPath) {
        if (!fullPath) return {df: '', col: '', raw_col: ''};
        var df = '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            df = parts[0];
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/["']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            var parts = fullPath.split('$');
            df = parts[0];
            raw_col = parts[1];
        } else {
            raw_col = fullPath;
        }
        return { df: df, raw_col: raw_col };
    }
  
    var desc=getValue("ba_desc"); var plot=getValue("ba_plot");
    var dv=getValue("ba_dv"); var fac=getValue("ba_fac");
    var p_dv=parseVar(dv); var p_fac=parseVar(fac); var df=p_dv.df;

    echo("rk.header(\"Bayesian One-Way ANOVA (BF10)\", level=3);\n");

    echo("bf_summ <- BayesFactor::extractBF(bf_anova)\n");
    echo("res_tab <- data.frame(Model = rownames(bf_summ), BF10 = bf_summ$bf, Error_Pct = bf_summ$error * 100)\n");
    echo("res_tab$Evidence <- cut(res_tab$BF10, breaks=c(0,1,3,10,30,100,Inf), labels=c(\"Favor Null\",\"Anecdotal\",\"Moderate\",\"Strong\",\"Very Strong\",\"Extreme\"))\n");
    echo("rk.results(res_tab)\n");
    echo("rk.print.literal(\"Denominator: Intercept only\")\n");
    
    if (desc == "1") { 
        echo("rk.header(\"Group Descriptives\", level=4);\n");
        echo("rk.results(desc_tab)\n"); 
    }

    if (plot == "1") {
        echo("rk.graph.on()\n");
        echo("print(ggpubr::ggboxplot(" + df + ", x=\"" + p_fac.raw_col + "\", y=\"" + p_dv.raw_col + "\", fill=\"" + p_fac.raw_col + "\", add=\"jitter\"))\n");
        echo("rk.graph.off()\n");
    }
  
	//// save result object
	// read in saveobject variables
	var baSave = getValue("ba_save");
	var baSaveActive = getValue("ba_save.active");
	var baSaveParent = getValue("ba_save.parent");
	// assign object to chosen environment
	if(baSaveActive) {
		echo(".GlobalEnv$" + baSave + " <- bf_anova\n");
	}

}

