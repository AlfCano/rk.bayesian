local({
  # =========================================================================================
  # 1. Package Definition and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.bayesian",
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "An RKWard plugin for Psychology/Social Sciences (Bayesian Suite). Features 'Jamovi-style' output with Bayes Factors, Posterior Effect Sizes, Descriptives, and Plots.",
      version = "0.0.1", # Frozen
      url = "https://github.com/AlfCano/rk.bayesian",
      license = "GPL (>= 3)"
    )
  )

  # Menu Hierarchy
  h_bayes <- list("analysis", "Psychology / Social Science", "Bayesian")

  # =========================================================================================
  # JS Helper
  # =========================================================================================
  js_parse_helper <- "
    function parseVar(fullPath) {
        if (!fullPath) return {df: '', col: '', raw_col: ''};
        var df = '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            df = parts[0];
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/[\"']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            var parts = fullPath.split('$');
            df = parts[0];
            raw_col = parts[1];
        } else {
            raw_col = fullPath;
        }
        return { df: df, raw_col: raw_col };
    }
  "

  # Shared Variable Selector
  var_selector <- rk.XML.varselector(id.name = "var_selector")

  # =========================================================================================
  # COMPONENT 1: Bayesian Independent T-Test
  # =========================================================================================

  help_bayes <- rk.rkh.doc(
    title = rk.rkh.title(text = "Bayesian Independent T-Test"),
    summary = rk.rkh.summary(text = "Calculate Bayes Factor (BF10) and Posterior Effect Size (Delta)."),
    usage = rk.rkh.usage(text = "Select Dependent Variable and Grouping Variable.")
  )

  b_dv <- rk.XML.varslot(label = "Dependent Variable", source = "var_selector", classes = "numeric", required = TRUE, id.name = "b_dv")
  b_grp <- rk.XML.varslot(label = "Grouping Variable", source = "var_selector", required = TRUE, id.name = "b_grp")

  b_opts <- rk.XML.frame(
      rk.XML.spinbox(label = "Prior Scale (Cauchy r)", min=0.1, max=2.0, initial=0.707, id.name = "b_rscale"),
      rk.XML.cbox(label = "Posterior Effect Size (Median Delta + 95% CI)", value = "1", chk = TRUE, id.name = "b_est"),
      rk.XML.cbox(label = "Descriptives (Mean/SD)", value = "1", chk = TRUE, id.name = "b_desc"),
      label = "Analysis Options"
  )

  b_plots <- rk.XML.frame(
      rk.XML.cbox(label = "Plot Posterior Density", value = "1", chk = TRUE, id.name = "b_plot_post"),
      rk.XML.cbox(label = "Plot Data (Boxplot + Jitter)", value = "1", chk = TRUE, id.name = "b_plot_data"),
      label = "Plots"
  )

  b_save <- rk.XML.saveobj(label = "Save BF Object", chk = TRUE, initial = "bf_res", id.name = "b_save")
  b_preview <- rk.XML.preview(mode = "plot")

  dialog_bayes <- rk.XML.dialog(
    label = "Bayesian Independent T-Test",
    child = rk.XML.row(var_selector, rk.XML.col(b_dv, b_grp, b_opts, b_plots, b_save, b_preview))
  )

  js_bayes_calc <- paste0(js_parse_helper, '
    var dv=getValue("b_dv"); var grp=getValue("b_grp"); var rscale=getValue("b_rscale");
    var est=getValue("b_est"); var desc=getValue("b_desc");
    var p_dv=parseVar(dv); var p_grp=parseVar(grp); var df=p_dv.df; var fmla=p_dv.raw_col+"~"+p_grp.raw_col;

    // 1. Calculate BF
    echo("bf_res <- BayesFactor::ttestBF(formula = " + fmla + ", data = as.data.frame(" + df + "), rscale = " + rscale + ")\\n");

    // 2. Posterior Sampling (Effect Size)
    if (est == "1") {
        echo("chains <- BayesFactor::posterior(bf_res, iterations = 2000, progress = FALSE)\\n");
        echo("post_summ <- data.frame(Parameter = \\"Cohens d (Delta)\\", Median = median(chains[,\\"delta\\"]), Lower = quantile(chains[,\\"delta\\"], 0.025), Upper = quantile(chains[,\\"delta\\"], 0.975))\\n");
        echo("names(post_summ) <- c(\\"Parameter\\", \\"Median\\", \\"95% CI Lower\\", \\"95% CI Upper\\")\\n");
    }

    // 3. Descriptives
    if (desc == "1") {
        echo("desc_tab <- " + df + " %>% group_by(" + p_grp.raw_col + ") %>% summarise(N=n(), Mean=mean(" + p_dv.raw_col + ", na.rm=T), SD=sd(" + p_dv.raw_col + ", na.rm=T))\\n");
    }
  ')

  js_bayes_print <- paste0(js_parse_helper, '
    var plot_post=getValue("b_plot_post"); var plot_data=getValue("b_plot_data");
    var est=getValue("b_est"); var desc=getValue("b_desc");
    var dv=getValue("b_dv"); var grp=getValue("b_grp");
    var p_dv=parseVar(dv); var p_grp=parseVar(grp); var df=p_dv.df;

    echo("rk.header(\\"Bayesian Independent T-Test\\", level=3);\\n");

    // Print BF Table
    echo("bf_tab <- BayesFactor::extractBF(bf_res)\\n");
    echo("bf_tab <- bf_tab[, c(\\"bf\\", \\"error\\")]\\n");
    echo("colnames(bf_tab) <- c(\\"Bayes Factor (BF10)\\", \\"Error (%)\\")\\n");
    echo("bf_tab$Evidence <- cut(bf_tab[[1]], breaks=c(0,1,3,10,30,100,Inf), labels=c(\\"Favor Null\\",\\"Anecdotal\\",\\"Moderate\\",\\"Strong\\",\\"Very Strong\\",\\"Extreme\\"))\\n");
    echo("rk.results(bf_tab)\\n");

    if (desc == "1") {
        echo("rk.header(\\"Group Descriptives\\", level=4);\\n");
        echo("rk.results(desc_tab)\\n");
    }

    if (est == "1") {
        echo("rk.header(\\"Posterior Effect Size Estimates\\", level=4);\\n");
        echo("rk.results(post_summ)\\n");
    }

    // Plots
    if (plot_post == "1" || plot_data == "1") {
        echo("rk.graph.on()\\n");
        if (plot_post == "1") {
             echo("chains_p <- BayesFactor::posterior(bf_res, iterations = 1000, progress = FALSE)\\n");
             echo("plot(chains_p[, \\"delta\\"], main=\\"Posterior Distribution (Delta)\\", xlab=\\"Effect Size\\")\\n");
        }
        if (plot_data == "1") {
             echo("print(ggpubr::ggboxplot(" + df + ", x=\\"" + p_grp.raw_col + "\\", y=\\"" + p_dv.raw_col + "\\", add=\\"jitter\\", fill=\\"" + p_grp.raw_col + "\\", title=\\"Data Distribution\\"))\\n");
        }
        echo("rk.graph.off()\\n");
    }
  ')

  js_bayes_prev <- '
    echo("chains <- BayesFactor::posterior(bf_res, iterations = 1000, progress = FALSE)\\n");
    echo("plot(chains[, \\"delta\\"], main=\\"Posterior Distribution (Delta)\\")\\n");
  '

  comp_bayes <- rk.plugin.component("Bayesian Independent T-Test", xml=list(dialog=dialog_bayes), js=list(require=c("BayesFactor", "dplyr", "ggpubr"), calculate=js_bayes_calc, printout=js_bayes_print, preview=js_bayes_prev), hierarchy=h_bayes, rkh=list(help=help_bayes))

  # =========================================================================================
  # COMPONENT 2: Bayesian One-Way ANOVA
  # =========================================================================================

  help_banova <- rk.rkh.doc(
    title = rk.rkh.title(text = "Bayesian One-Way ANOVA"),
    summary = rk.rkh.summary(text = "Calculate BF10 for ANOVA models."),
    usage = rk.rkh.usage(text = "Select Dependent Variable and Factor.")
  )

  ba_dv <- rk.XML.varslot(label = "Dependent Variable", source = "var_selector", classes = "numeric", required = TRUE, id.name = "ba_dv")
  ba_fac <- rk.XML.varslot(label = "Factor", source = "var_selector", required = TRUE, id.name = "ba_fac")
  ba_desc <- rk.XML.cbox(label = "Descriptives", value = "1", chk = TRUE, id.name = "ba_desc")
  ba_plot <- rk.XML.cbox(label = "Plot Data (Boxplot)", value = "1", chk = TRUE, id.name = "ba_plot")
  ba_save <- rk.XML.saveobj(label = "Save BF Object", chk = TRUE, initial = "bf_anova", id.name = "ba_save")

  dialog_banova <- rk.XML.dialog(label = "Bayesian One-Way ANOVA", child = rk.XML.row(var_selector, rk.XML.col(ba_dv, ba_fac, ba_desc, ba_plot, ba_save)))

  js_banova_calc <- paste0(js_parse_helper, '
    var dv=getValue("ba_dv"); var fac=getValue("ba_fac"); var desc=getValue("ba_desc");
    var p_dv=parseVar(dv); var p_fac=parseVar(fac); var df=p_dv.df; var fmla=p_dv.raw_col+"~"+p_fac.raw_col;

    echo("bf_anova <- BayesFactor::anovaBF(formula = " + fmla + ", data = as.data.frame(" + df + "))\\n");

    if (desc == "1") {
        echo("desc_tab <- " + df + " %>% group_by(" + p_fac.raw_col + ") %>% summarise(N=n(), Mean=mean(" + p_dv.raw_col + ", na.rm=T), SD=sd(" + p_dv.raw_col + ", na.rm=T))\\n");
    }
  ')

  js_banova_print <- paste0(js_parse_helper, '
    var desc=getValue("ba_desc"); var plot=getValue("ba_plot");
    var dv=getValue("ba_dv"); var fac=getValue("ba_fac");
    var p_dv=parseVar(dv); var p_fac=parseVar(fac); var df=p_dv.df;

    echo("rk.header(\\"Bayesian One-Way ANOVA (BF10)\\", level=3);\\n");

    echo("bf_summ <- BayesFactor::extractBF(bf_anova)\\n");
    echo("res_tab <- data.frame(Model = rownames(bf_summ), BF10 = bf_summ$bf, Error_Pct = bf_summ$error * 100)\\n");
    echo("res_tab$Evidence <- cut(res_tab$BF10, breaks=c(0,1,3,10,30,100,Inf), labels=c(\\"Favor Null\\",\\"Anecdotal\\",\\"Moderate\\",\\"Strong\\",\\"Very Strong\\",\\"Extreme\\"))\\n");
    echo("rk.results(res_tab)\\n");
    echo("rk.print.literal(\\"Denominator: Intercept only\\")\\n");

    if (desc == "1") {
        echo("rk.header(\\"Group Descriptives\\", level=4);\\n");
        echo("rk.results(desc_tab)\\n");
    }

    if (plot == "1") {
        echo("rk.graph.on()\\n");
        echo("print(ggpubr::ggboxplot(" + df + ", x=\\"" + p_fac.raw_col + "\\", y=\\"" + p_dv.raw_col + "\\", fill=\\"" + p_fac.raw_col + "\\", add=\\"jitter\\"))\\n");
        echo("rk.graph.off()\\n");
    }
  ')

  comp_banova <- rk.plugin.component("Bayesian One-Way ANOVA", xml=list(dialog=dialog_banova), js=list(require=c("BayesFactor", "dplyr", "ggpubr"), calculate=js_banova_calc, printout=js_banova_print), hierarchy=h_bayes, rkh=list(help=help_banova))

  # =========================================================================================
  # COMPONENT 3: Bayesian Correlation
  # =========================================================================================

  help_bcor <- rk.rkh.doc(
    title = rk.rkh.title(text = "Bayesian Correlation"),
    summary = rk.rkh.summary(text = "Bayes Factor and Posterior Rho."),
    usage = rk.rkh.usage(text = "Select 2 numeric variables.")
  )

  bc_var1 <- rk.XML.varslot(label = "Variable 1", source = "var_selector", classes = "numeric", required = TRUE, id.name = "bc_var1")
  bc_var2 <- rk.XML.varslot(label = "Variable 2", source = "var_selector", classes = "numeric", required = TRUE, id.name = "bc_var2")

  bc_opts <- rk.XML.frame(
      rk.XML.cbox(label = "Posterior Effect Size (Median Rho + 95% CI)", value = "1", chk = TRUE, id.name = "bc_est"),
      rk.XML.cbox(label = "Plot Posterior Density", value = "1", chk = TRUE, id.name = "bc_plot_post"),
      rk.XML.cbox(label = "Plot Scatterplot", value = "1", chk = TRUE, id.name = "bc_plot_scat"),
      label = "Options"
  )
  bc_save <- rk.XML.saveobj(label = "Save BF Object", chk = TRUE, initial = "bf_cor", id.name = "bc_save")

  dialog_bcor <- rk.XML.dialog(label = "Bayesian Correlation", child = rk.XML.row(var_selector, rk.XML.col(bc_var1, bc_var2, bc_opts, bc_save)))

  js_bcor_calc <- paste0(js_parse_helper, '
    var v1=getValue("bc_var1"); var v2=getValue("bc_var2"); var est=getValue("bc_est");

    echo("bf_cor <- BayesFactor::correlationBF(y = " + v1 + ", x = " + v2 + ")\\n");

    if (est == "1") {
        echo("chains <- BayesFactor::posterior(bf_cor, iterations = 2000, progress = FALSE)\\n");
        echo("post_summ <- data.frame(Parameter = \\"Rho\\", Median = median(chains[,\\"rho\\"]), Lower = quantile(chains[,\\"rho\\"], 0.025), Upper = quantile(chains[,\\"rho\\"], 0.975))\\n");
        echo("names(post_summ) <- c(\\"Parameter\\", \\"Median\\", \\"95% CI Lower\\", \\"95% CI Upper\\")\\n");
    }
  ')

  js_bcor_print <- paste0(js_parse_helper, '
    var est=getValue("bc_est");
    var plot_post=getValue("bc_plot_post"); var plot_scat=getValue("bc_plot_scat");
    var v1=getValue("bc_var1"); var v2=getValue("bc_var2");

    echo("rk.header(\\"Bayesian Correlation Test\\", level=3);\\n");

    echo("bf_tab <- BayesFactor::extractBF(bf_cor)\\n");
    echo("bf_tab <- bf_tab[, c(\\"bf\\", \\"error\\")]\\n");
    echo("colnames(bf_tab) <- c(\\"Bayes Factor (BF10)\\", \\"Error (%)\\")\\n");
    echo("bf_tab$Evidence <- cut(bf_tab[[1]], breaks=c(0,1,3,10,30,100,Inf), labels=c(\\"Favor Null\\",\\"Anecdotal\\",\\"Moderate\\",\\"Strong\\",\\"Very Strong\\",\\"Extreme\\"))\\n");
    echo("rk.results(bf_tab)\\n");

    if (est == "1") {
        echo("rk.header(\\"Posterior Effect Size Estimates\\", level=4);\\n");
        echo("rk.results(post_summ)\\n");
    }

    if (plot_post == "1" || plot_scat == "1") {
        echo("rk.graph.on()\\n");
        if (plot_post == "1") {
            echo("chains_p <- BayesFactor::posterior(bf_cor, iterations = 1000, progress = FALSE)\\n");
            echo("plot(chains_p[, \\"rho\\"], main=\\"Posterior Distribution (Rho)\\", xlab=\\"Correlation (rho)\\")\\n");
        }
        if (plot_scat == "1") {
            echo("plot(" + v2 + ", " + v1 + ", pch=19, col=rgb(0,0,0,0.6), main=\\"Scatterplot\\")\\n");
            echo("abline(lm(" + v1 + " ~ " + v2 + "), col=\\"red\\", lwd=2)\\n");
        }
        echo("rk.graph.off()\\n");
    }
  ')

  comp_bcor <- rk.plugin.component("Bayesian Correlation", xml=list(dialog=dialog_bcor), js=list(require=c("BayesFactor", "dplyr"), calculate=js_bcor_calc, printout=js_bcor_print), hierarchy=h_bayes, rkh=list(help=help_bcor))

  # =========================================================================================
  # COMPONENT 4: Bayesian Contingency Table
  # =========================================================================================

  help_bct <- rk.rkh.doc(
    title = rk.rkh.title(text = "Bayesian Contingency"),
    summary = rk.rkh.summary(text = "Calculate BF10 for a contingency table."),
    usage = rk.rkh.usage(text = "Select a table/matrix object.")
  )

  bct_tab <- rk.XML.varslot(label = "Contingency Table (Matrix)", source = "var_selector", required = TRUE, id.name = "bct_tab")
  bct_sample <- rk.XML.dropdown(label = "Sampling Type", options = list("Independent (Poisson)" = list(val = "indepMulti", chk = TRUE), "Joint Multinomial" = list(val = "jointMulti")), id.name = "bct_sample")
  bct_save <- rk.XML.saveobj(label = "Save BF Object", chk = TRUE, initial = "bf_ct", id.name = "bct_save")

  dialog_bct <- rk.XML.dialog(label = "Bayesian Contingency Table", child = rk.XML.row(var_selector, rk.XML.col(bct_tab, bct_sample, bct_save)))

  js_bct_calc <- '
    var tab = getValue("bct_tab");
    var sample = getValue("bct_sample");
    echo("bf_ct <- BayesFactor::contingencyTableBF(" + tab + ", sampleType = \\"" + sample + "\\")\\n");
  '

  js_bct_print <- '
    echo("rk.header(\\"Bayesian Contingency Table Test\\", level=3);\\n");

    echo("bf_tab <- BayesFactor::extractBF(bf_ct)\\n");
    echo("bf_tab <- bf_tab[, c(\\"bf\\", \\"error\\")]\\n");
    echo("colnames(bf_tab) <- c(\\"Bayes Factor (BF10)\\", \\"Error (%)\\")\\n");
    echo("bf_tab$Evidence <- cut(bf_tab[[1]], breaks=c(0,1,3,10,30,100,Inf), labels=c(\\"Favor Null\\",\\"Anecdotal\\",\\"Moderate\\",\\"Strong\\",\\"Very Strong\\",\\"Extreme\\"))\\n");
    echo("rk.results(bf_tab)\\n");
  '

  comp_bct <- rk.plugin.component("Bayesian Contingency Table", xml=list(dialog=dialog_bct), js=list(require=c("BayesFactor"), calculate=js_bct_calc, printout=js_bct_print), hierarchy=h_bayes, rkh=list(help=help_bct))

  # =========================================================================================
  # BUILD SKELETON
  # =========================================================================================

  rk.plugin.skeleton(
    about = package_about,
    path = ".",

    xml = list(dialog = dialog_bayes),
    js = list(require=c("BayesFactor", "dplyr", "ggpubr"), calculate=js_bayes_calc, printout=js_bayes_print, preview=js_bayes_prev),
    rkh = list(help = help_bayes),

    components = list(comp_banova, comp_bcor, comp_bct),

    pluginmap = list(
        name = "Bayesian Independent T-Test",
        hierarchy = h_bayes
    ),

    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE,
    overwrite = TRUE,
    show = FALSE
  )

  cat("\nPlugin package 'rk.bayesian' (v0.0.1) generated successfully.\n")
  cat("To complete installation:\n")
  cat("  1. rk.updatePluginMessages(path=\".\")\n")
  cat("  2. devtools::install(\".\")\n")
})
