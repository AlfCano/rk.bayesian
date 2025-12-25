// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(BayesFactor)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var tab = getValue("bct_tab");
    var sample = getValue("bct_sample");
    echo("bf_ct <- BayesFactor::contingencyTableBF(" + tab + ", sampleType = \"" + sample + "\")\n");
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Bayesian Contingency Table results")).print();

    echo("rk.header(\"Bayesian Contingency Table Test\", level=3);\n");

    echo("bf_tab <- BayesFactor::extractBF(bf_ct)\n");
    echo("bf_tab <- bf_tab[, c(\"bf\", \"error\")]\n");
    echo("colnames(bf_tab) <- c(\"Bayes Factor (BF10)\", \"Error (%)\")\n");
    echo("bf_tab$Evidence <- cut(bf_tab[[1]], breaks=c(0,1,3,10,30,100,Inf), labels=c(\"Favor Null\",\"Anecdotal\",\"Moderate\",\"Strong\",\"Very Strong\",\"Extreme\"))\n");
    echo("rk.results(bf_tab)\n");
  
	//// save result object
	// read in saveobject variables
	var bctSave = getValue("bct_save");
	var bctSaveActive = getValue("bct_save.active");
	var bctSaveParent = getValue("bct_save.parent");
	// assign object to chosen environment
	if(bctSaveActive) {
		echo(".GlobalEnv$" + bctSave + " <- bf_ct\n");
	}

}

