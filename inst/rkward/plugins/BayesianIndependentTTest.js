// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

function preview(){
	
    echo("chains <- BayesFactor::posterior(bf_res, iterations = 1000, progress = FALSE)\n");
    echo("plot(chains[, \"delta\"], main=\"Posterior Distribution (Delta)\")\n");
  
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(BayesFactor)){stop(" + i18n("Preview not available, because package BayesFactor is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(BayesFactor)\n");
	}	if(is_preview) {
		echo("if(!base::require(dplyr)){stop(" + i18n("Preview not available, because package dplyr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(dplyr)\n");
	}	if(is_preview) {
		echo("if(!base::require(ggpubr)){stop(" + i18n("Preview not available, because package ggpubr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(ggpubr)\n");
	}
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
  
    var dv=getValue("b_dv"); var grp=getValue("b_grp"); var rscale=getValue("b_rscale");
    var est=getValue("b_est"); var desc=getValue("b_desc");
    var p_dv=parseVar(dv); var p_grp=parseVar(grp); var df=p_dv.df; var fmla=p_dv.raw_col+"~"+p_grp.raw_col;
    
    // 1. Calculate BF
    echo("bf_res <- BayesFactor::ttestBF(formula = " + fmla + ", data = as.data.frame(" + df + "), rscale = " + rscale + ")\n");
    
    // 2. Posterior Sampling (Effect Size)
    if (est == "1") {
        echo("chains <- BayesFactor::posterior(bf_res, iterations = 2000, progress = FALSE)\n");
        echo("post_summ <- data.frame(Parameter = \"Cohens d (Delta)\", Median = median(chains[,\"delta\"]), Lower = quantile(chains[,\"delta\"], 0.025), Upper = quantile(chains[,\"delta\"], 0.975))\n");
        echo("names(post_summ) <- c(\"Parameter\", \"Median\", \"95% CI Lower\", \"95% CI Upper\")\n");
    }
    
    // 3. Descriptives
    if (desc == "1") {
        echo("desc_tab <- " + df + " %>% group_by(" + p_grp.raw_col + ") %>% summarise(N=n(), Mean=mean(" + p_dv.raw_col + ", na.rm=T), SD=sd(" + p_dv.raw_col + ", na.rm=T))\n");
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Bayesian Independent T-Test results")).print();	
	}
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
  
    var plot_post=getValue("b_plot_post"); var plot_data=getValue("b_plot_data");
    var est=getValue("b_est"); var desc=getValue("b_desc");
    var dv=getValue("b_dv"); var grp=getValue("b_grp");
    var p_dv=parseVar(dv); var p_grp=parseVar(grp); var df=p_dv.df;

    echo("rk.header(\"Bayesian Independent T-Test\", level=3);\n");

    // Print BF Table
    echo("bf_tab <- BayesFactor::extractBF(bf_res)\n");
    echo("bf_tab <- bf_tab[, c(\"bf\", \"error\")]\n");
    echo("colnames(bf_tab) <- c(\"Bayes Factor (BF10)\", \"Error (%)\")\n");
    echo("bf_tab$Evidence <- cut(bf_tab[[1]], breaks=c(0,1,3,10,30,100,Inf), labels=c(\"Favor Null\",\"Anecdotal\",\"Moderate\",\"Strong\",\"Very Strong\",\"Extreme\"))\n");
    echo("rk.results(bf_tab)\n");

    if (desc == "1") { 
        echo("rk.header(\"Group Descriptives\", level=4);\n");
        echo("rk.results(desc_tab)\n"); 
    }

    if (est == "1") { 
        echo("rk.header(\"Posterior Effect Size Estimates\", level=4);\n");
        echo("rk.results(post_summ)\n"); 
    }

    // Plots
    if (plot_post == "1" || plot_data == "1") {
        echo("rk.graph.on()\n");
        if (plot_post == "1") {
             echo("chains_p <- BayesFactor::posterior(bf_res, iterations = 1000, progress = FALSE)\n");
             echo("plot(chains_p[, \"delta\"], main=\"Posterior Distribution (Delta)\", xlab=\"Effect Size\")\n");
        }
        if (plot_data == "1") {
             echo("print(ggpubr::ggboxplot(" + df + ", x=\"" + p_grp.raw_col + "\", y=\"" + p_dv.raw_col + "\", add=\"jitter\", fill=\"" + p_grp.raw_col + "\", title=\"Data Distribution\"))\n");
        }
        echo("rk.graph.off()\n");
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var bSave = getValue("b_save");
		var bSaveActive = getValue("b_save.active");
		var bSaveParent = getValue("b_save.parent");
		// assign object to chosen environment
		if(bSaveActive) {
			echo(".GlobalEnv$" + bSave + " <- bf_res\n");
		}	
	}

}

