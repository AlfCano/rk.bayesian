// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(BayesFactor)\n");	echo("require(dplyr)\n");
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
  
    var v1=getValue("bc_var1"); var v2=getValue("bc_var2"); var est=getValue("bc_est");
    
    echo("bf_cor <- BayesFactor::correlationBF(y = " + v1 + ", x = " + v2 + ")\n");
    
    if (est == "1") {
        echo("chains <- BayesFactor::posterior(bf_cor, iterations = 2000, progress = FALSE)\n");
        echo("post_summ <- data.frame(Parameter = \"Rho\", Median = median(chains[,\"rho\"]), Lower = quantile(chains[,\"rho\"], 0.025), Upper = quantile(chains[,\"rho\"], 0.975))\n");
        echo("names(post_summ) <- c(\"Parameter\", \"Median\", \"95% CI Lower\", \"95% CI Upper\")\n");
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Bayesian Correlation results")).print();

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
  
    var est=getValue("bc_est");
    var plot_post=getValue("bc_plot_post"); var plot_scat=getValue("bc_plot_scat");
    var v1=getValue("bc_var1"); var v2=getValue("bc_var2");

    echo("rk.header(\"Bayesian Correlation Test\", level=3);\n");

    echo("bf_tab <- BayesFactor::extractBF(bf_cor)\n");
    echo("bf_tab <- bf_tab[, c(\"bf\", \"error\")]\n");
    echo("colnames(bf_tab) <- c(\"Bayes Factor (BF10)\", \"Error (%)\")\n");
    echo("bf_tab$Evidence <- cut(bf_tab[[1]], breaks=c(0,1,3,10,30,100,Inf), labels=c(\"Favor Null\",\"Anecdotal\",\"Moderate\",\"Strong\",\"Very Strong\",\"Extreme\"))\n");
    echo("rk.results(bf_tab)\n");

    if (est == "1") {
        echo("rk.header(\"Posterior Effect Size Estimates\", level=4);\n");
        echo("rk.results(post_summ)\n");
    }

    if (plot_post == "1" || plot_scat == "1") {
        echo("rk.graph.on()\n");
        if (plot_post == "1") {
            echo("chains_p <- BayesFactor::posterior(bf_cor, iterations = 1000, progress = FALSE)\n");
            echo("plot(chains_p[, \"rho\"], main=\"Posterior Distribution (Rho)\", xlab=\"Correlation (rho)\")\n");
        }
        if (plot_scat == "1") {
            echo("plot(" + v2 + ", " + v1 + ", pch=19, col=rgb(0,0,0,0.6), main=\"Scatterplot\")\n");
            echo("abline(lm(" + v1 + " ~ " + v2 + "), col=\"red\", lwd=2)\n");
        }
        echo("rk.graph.off()\n");
    }
  
	//// save result object
	// read in saveobject variables
	var bcSave = getValue("bc_save");
	var bcSaveActive = getValue("bc_save.active");
	var bcSaveParent = getValue("bc_save.parent");
	// assign object to chosen environment
	if(bcSaveActive) {
		echo(".GlobalEnv$" + bcSave + " <- bf_cor\n");
	}

}

