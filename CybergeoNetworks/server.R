##############################
# Shiny App: Cybergeo20
# Server
##############################



# set server ----

shinyServer(function(input, output, session) {
  

  
  yearValues <- reactiveValues(years= NULL)
  
  observe({
    if (length(input$dateRange) == 1) {
      yearValues$years = input$dateRange
    } else {
      dates = input$dateRange
      yearValues$years = dates[[1]] : dates[[length(dates)]]
    }
  })

  themeNames <- reactiveValues(listThemes = NULL)
  
  observe({
    if (input$semanticMethod == "Citations")  themeNames$listThemes = colnames(terms1)[2:13]
    if (input$semanticMethod == "Keywords")  themeNames$listThemes = colnames(hadriTerms)[2:11]
    if (input$semanticMethod == "Semantic")  themeNames$listThemes = nameThemes
    })
    
 
    subsetArticles <- reactive({
    allArticles <- cyberData$ARTICLES
    years = yearValues$years
    articles = allArticles[substr(allArticles$date.1, 1, 4) %in% as.character(years),]
    articles = merge(articles, files, by = "id" , all.x = T, all.y = F)
    return(articles)   
  })
  
  mappingData <- reactive({
    selectedArticles <- subsetArticles()
    Studied = colSums(selectedArticles[,studies])
    Authoring = colSums(selectedArticles[,authors])
    SelfStudied = colSums(selectedArticles[,locals])
    countryBase = data.frame(countries, Studied, Authoring, SelfStudied)
    return(countryBase)   
  })
  
   output$statArticles = renderDataTable({
    tab = data.frame()
    articlesDF = subsetArticles()
    nPapers = dim(articlesDF)[1]
    
    tab[1,1] = "Number of scientific articles"
    tab[1,2] = nPapers
    
    articlesDF$authorsLists = strsplit(articlesDF$authors, split = ",")
    for (i in 1:dim(articlesDF)[1]) {
      articlesDF[i,"Nauthors"] = ifelse(is.na(articlesDF[i,"authorsLists"]), 1, length(articlesDF[i,"authorsLists"][[1]]))
    }
    Nauthors = sum(articlesDF$Nauthors)
    
    tab[2,1] = "Number of authors"
    tab[2,2] = Nauthors
    
     cols = colnames(articlesDF)
    authoring = cols[substr(cols,1, 2) == "A_"]
    sumsAByCountry = colSums(articlesDF[,authoring])
    authoringCountries = sumsAByCountry[sumsAByCountry>0]
    nAuthoringCountries = length(authoringCountries)
    
    tab[3,1] = "Number of countries authoring"
    tab[3,2] = nAuthoringCountries
    
    names(authoringCountries) = substr(names(authoringCountries), 3, 4)
    AC = sort(authoringCountries, decreasing = T)
    AC5 = paste0(names(AC[1]), " (", AC[1], "), ", names(AC[2]), " (",  AC[2], "), ", 
                 names(AC[3]), " (", AC[3], "), ", names(AC[4]), " (",  AC[4], "), ", 
                 names(AC[5]), " (", AC[5], ")")
    
    tab[4,1] = "Top countries authoring"
    tab[4,2] = AC5
    
    studied = cols[substr(cols,1, 2) == "S_"]
    sumsSByCountry = colSums(articlesDF[,studied])
    studiedCountries = sumsSByCountry[sumsSByCountry>0]
    nStudiedCountries = length(studiedCountries)
    
    tab[5,1] = "Number of countries studied"
    tab[5,2] = nStudiedCountries
    
    names(studiedCountries) = substr(names(studiedCountries), 3, 4)
    SC = sort(studiedCountries, decreasing = T)
    SC5 = paste0(names(SC[1]), " (", SC[1], "), ", names(SC[2]), " (",  SC[2], "), ", 
                 names(SC[3]), " (", SC[3], "), ", names(SC[4]), " (",  SC[4], "), ", 
                 names(SC[5]), " (", SC[5], ")")
    
    tab[6,1] = "Top countries studied"
    tab[6,2] = SC5
    
    sumsCitations = colSums(articlesDF[,c("citedby", "citing")], na.rm = T)
    
    tab[7,1] = "Number of citations from other articles"
    tab[7,2] = as.numeric(sumsCitations[1])
    tab[8,1] = "Number of citations of other articles"
    tab[8,2] = as.numeric(sumsCitations[2])

    colnames(tab) = c("Indicator", "Value")
    
    return(tab)
  }, options = list(paging = FALSE, searching = FALSE))
   
  output$cybMap = renderPlot({
    countryBase = mappingData()
    REG = world
    REG@data = data.frame(REG@data, countryBase[match(REG@data$CNTR_ID,countryBase$countries), ])

    REG@data$StudiedAtAll = ifelse(REG@data$Studied >= 1, "#1C6F91", "lightgrey")
    REG@data$AuthoringAtAll = ifelse(REG@data$Authoring >= 1, "orange", "lightgrey")
    REG@data$SelfStudiedAtAll = ifelse(REG@data$SelfStudied >= 1,  "#df691a", "lightgrey")  
    years = input$dateRange
    if(length(years) == 1) {
      Year = years
      } else {
        Year = paste0(years[1], " - ", years[length(years)])
      }
    
    par(mfrow=c(1,1), mar = c(0,0,1,0), bg="#2b3e50")
    
    if (input$whatMapped == "A"){
    plot(REG, col=REG@data$AuthoringAtAll, border="white", lwd=0.7)
    title(paste0("Countries authoring Cybergeo articles | ", Year), col.main = "white")
    }
    if (input$whatMapped == "S"){
      plot(REG, col=REG@data$StudiedAtAll, border="white", lwd=0.7)
      title(paste0("Countries studied in Cybergeo articles | ", Year), col.main = "white")
    }
    if (input$whatMapped == "L"){
      plot(REG, col=REG@data$SelfStudiedAtAll, border="white", lwd=0.7)
        title(paste0("Countries studied by locals in Cybergeo articles | ", Year), col.main = "white") }
   })
  
  
  
  
  clusterCountries <- reactive({
    termsMethod = input$semanticMethod
    themeNames = themeNames$listThemes
    groupsOfCountries = input$nClassifGroups 
    termCountryRelation = input$aggregationMethod
    articles = cyberData$ARTICLES
    
     if(termCountryRelation == "Authoring") tcr = authors
    if(termCountryRelation ==  "Studied") tcr = studies
    if (termsMethod == "Citations"){
      cybterms = terms1[terms1$CYBERGEOID != 0,]
      cybterms$idterm = rownames(cybterms)
      cybterms2 = data.frame(cybterms, articles[match(cybterms$CYBERGEOID,articles$id), ])
    }
    if (termsMethod == "Keywords"){
      cybterms = hadriTerms
      cybterms2 = data.frame(cybterms, articles[match(cybterms$ID,articles$id), ])
      }
    if (termsMethod == "Semantic"){
      articlesWithThemes = data.frame(articles, files[match(articles$id,files$id), ])
      cybterms = articlesWithThemes[,c("id",themeNames)]
      cybtermsbis = cybterms[complete.cases(cybterms[,themeNames]),]
      cybterms2 = data.frame(cybtermsbis, articles[match(cybtermsbis$id,articles$id), ])
     }
    
    cybterms3 = data.frame(cybterms2, lookup[match(cybterms2$firstauthor,lookup$countries), ])
    cybterms4 = cybterms3[complete.cases(cybterms3$id.1),]
    
    themes_By_country_bf = aggregateCountriesBasedOnTerms(themesFile = cybterms4, themes = themeNames, countries_to_aggregate = tcr)
   
    return(themes_By_country_bf)   
  })
  
  cahCountries <- reactive({
    groupsOfCountries = input$nClassifGroups 
    themeNames = themeNames$listThemes
    themes_By_country_bf = clusterCountries()
    cahRes = cahCountriesBasedOnTerms(themes_By_country_bf = themes_By_country_bf, numberOfGroups = groupsOfCountries, themes = themeNames)
    cahResDF = data.frame("ID" = themes_By_country_bf[,1], "group" = cahRes)
    return(cahResDF)   
  })
  
  legCahCountries <- reactive({
    groupsOfCountries = input$nClassifGroups 
    themeNames = themeNames$listThemes
    themes_By_country_bf = clusterCountries()
    countriesDF = themes_By_country_bf[,themeNames]
    rownames(countriesDF) = themes_By_country_bf[,1]
    legcahRes = cahCountriesBasedOnTerms(themes_By_country_bf = themes_By_country_bf, numberOfGroups = groupsOfCountries, themes = themeNames)
    leg = sapply(countriesDF, stat.comp,y=legcahRes)
    return(leg)   
  })
  
  output$termsXCountriesMap = renderPlot({
    groupsOfCountries = input$nClassifGroups 
    themeNames = themeNames$listThemes
    
      cahRes = cahCountries()
     cahRes$groupColour = as.character(cut(cahRes$group, breaks = c(1:groupsOfCountries, groupsOfCountries+1),
                      labels = paletteCybergeo[1:groupsOfCountries],include.lowest = TRUE,right = FALSE))
    REG=world
    REG@data = data.frame(REG@data, cahRes[match(REG@data$CNTR_ID,cahRes$ID), ])
    par(mfrow=c(1,1), mar = c(0,0,1,0), bg="#2b3e50")
    plot(REG, col=REG@data$groupColour, border="white", lwd=0.7)
    title("Groups of countries based on semantic networks", col.main = "white") 
})
  
   output$termsXCountriesLegend = renderPlot({
     groupsOfCountries = input$nClassifGroups 
     themeNames = themeNames$listThemes
     leg = legCahCountries()
       if(groupsOfCountries %% 2 == 0) window = c(groupsOfCountries/2,2)
       if(groupsOfCountries %% 2 == 1) window = c(groupsOfCountries/2 + 0.5,2)
     termsMethod = input$semanticMethod
     themes_By_country_bf = clusterCountries()
     themes_By_country_bf$group =  cahCountriesBasedOnTerms(themes_By_country_bf = themes_By_country_bf, numberOfGroups = groupsOfCountries, themes = themeNames)
     nArticlesByGroup = aggregate(themes_By_country_bf[,"n"], by = list(themes_By_country_bf$group), FUN = sumNum)
    colnames(nArticlesByGroup) = c("ID", "n")
    nArticlesByGroup = nArticlesByGroup[order(nArticlesByGroup$ID),]
     
     par(mfrow=window, las=2, mar = c(4,10,2,1), bg="#2b3e50")
     for(i in 1:groupsOfCountries){
     barplot(leg[i,], col=paletteCybergeo[i], horiz=TRUE, cex.names=0.8, xlab= "Frequency of themes", col.lab="white", col.axis="white")
       axis(1, col = "white", col.axis = "white")
     if(nArticlesByGroup[i, "n"] == 1)  title(paste0(nArticlesByGroup[i, "n"], " article"), col.main = "white")
     if(nArticlesByGroup[i, "n"] > 1)  title(paste0(nArticlesByGroup[i, "n"], " articles"), col.main = "white")
     }
   })
  
   #########
   
  # output$semanticNetwork <- renderForceNetwork({
  #   forceNetwork(Links = edf, Nodes = vdf,
  #                Source = "source", Target = "target",
  #                Value = "value", NodeID = "name",
  #                Group = "community", opacity = 0.8,zoom=TRUE)
  # 
  #  })
  # 
  #  DO NOT use networkD3js, unless initial layout is possible
  
   #########
   
   # data loading
   # output$citationdataloading<-renderText({
   #   if(is.null(citationGlobalVars$loaded)){"Data Loading..."}else{""}
   # })
   
   ## selection datatable
   output$citationcybergeo <- renderDataTable({
     withProgress(expr={},message='Data Loading...')
     citation_cybergeodata[citation_cybergeodata$linknum>0|citation_cybergeodata$kwcount>0,c(1,2,3,7)]
     #DT::datatable(citation_cybergeodata[,c(1,2,3,7)],selection='single')
   })
   
   # strange behavior of rows_selected : due to use of datatable ?
   #  -> must do a setdiff on global var - ultra dirty
   #  seems to be a wrong implementation of rows_selected with single selection -- beurk. [horrible function intrication]
   # OK fuck this shit, allow multiple selection and draw plot only if a single selected
   # as some situations are not detectable.
   citationSelectedCybergeoArticle <- reactive({
     return(input$citationcybergeo_rows_selected)
     # show(sel)
     # if(is.null(citationGlobalVars$prevsel)){
     #   if(length(sel)>0){citationGlobalVars$prevsel=sel;return(sel[1])}else{return(0)}
     # }else{
     #   if(length(sel)==length(citationGlobalVars$prevsel)){return(citationGlobalVars$citationSelected)}
     #   if(length(sel)<length(citationGlobalVars$prevsel)){
     #     # deselect a row : nothing selected
     #      citationGlobalVars$prevsel = sel
     #      return(0)
     #   }else{
     #      selindex = setdiff(sel,citationGlobalVars$prevsel)[1]
     #      citationGlobalVars$prevsel = sel#setdiff(sel,c(citationGlobalVars$citationSelected))
     #      return(selindex)
     #   }
     # }
   })
   
   
   # observer make data update requests
   observe({
     selected = citationSelectedCybergeoArticle()
     selected_hand = which(citation_cybergeodata$id==input$citationselected)
     if(length(selected_hand)>0){selected=selected_hand}
     #show(paste0("selected : ",selected))
     if(length(selected)==1){
       if(selected[1]!=citationGlobalVars$citationSelected){
         #show(paste0("selected different : ",citation_cybergeodata$title[as.numeric(selected)]))
         citationGlobalVars$citationSelected=selected[1]
         selectedschid = citation_cybergeodata$SCHID[as.numeric(selected[1])]
         # make request for edges in sqlitedb
         citationGlobalVars$edges = citationLoadEdges(selectedschid)
       }   
     }
   })
   
   # similar observer for semantic plot
   observe({
     selected = citationSelectedCybergeoArticle()
     selected_hand = which(citation_cybergeodata$id==input$citationsemanticselected)
     if(length(selected_hand)>0){selected=selected_hand}
     if(length(selected)==1){
       if(selected[1]!=citationGlobalVars$citationSemanticSelected){
         citationGlobalVars$citationSemanticSelected=selected[1]
         selectedschid = citation_cybergeodata$SCHID[as.numeric(selected[1])]
         citationGlobalVars$keywords = citationLoadKeywords(selectedschid)
       }   
     }
   })
   
   
   # render citation graph around selected article
   output$citationegoplot = renderPlot({
      citationVisuEgo(citationGlobalVars$edges)
   })
  
   # render wordclouds
   output$citationesemanticplot = renderPlot({
     citationWordclouds(citation_cybergeodata$SCHID[citationGlobalVars$citationSemanticSelected],citationGlobalVars$keywords)
   })
   
   
   # semantic nw viz
   output$citationsemanticnw<-renderSvgPanZoom({
     svgPanZoom('data/semantic.svg',
                zoomScaleSensitivity=1,
                minZoom=2,
                maxZoom=20,
                contain=TRUE
                )
   })

   
   
   
   # Ask a pattern to match in the corpus
   patterns <- reactive({
     if(input$mode == 'one') { input$pattern_input } else { input$patterns_selection }
   })
   
   # Ask for a new pattern to add in the list
   observeEvent(
     input$add_pattern,
     {
       pattern_list <<- c(input$pattern_input, pattern_list)
       updateTextInput(session, "pattern_input", value = "")
       updateCheckboxGroupInput(session, "patterns_selection", choices = pattern_list, selected = c(input$pattern_input, input$patterns_selection))
     }
   )
   
   # Compute the Outputs
   output$chronogram <- renderPlot(chronogram(patterns()))
   output$cloud <- renderPlot(cloud(patterns()))
   output$citations <- renderPrint(titles_matched(patterns()))
   output$phrases <- renderPrint(phrases(patterns()))
   
   
   
   
   
   
  # select level and other variables
  SelectYearRes <- reactive({
    fullGraph <- cyberData$NETKW
    return(fullGraph)
  })
  
  # select level and other variables
  SelectYearCom <- reactive({
    fullGraph <- cyberData$NETKW
    commId <- sort(unique(V(fullGraph)$clus))
    updateSelectInput(session = session, inputId = "commid", choices = commId)
    return(fullGraph)
  })
  
  # select level and other variables
  SelectYearSem <- reactive({
    fullGraph <- cyberData$NETKW
    kwId <- sort(unique(V(fullGraph)$name))
    updateSelectInput(session = session, inputId = "kwid2", choices = kwId)
    return(fullGraph)
  })
  
  
  # create information table for nodes
  InfoTableNodes <- reactive({
    g <- SelectYearRes()
    infoNodes <- data.frame(KEYWORDS = V(g)$name, NB_ARTICLES = V(g)$nbauth, DEGREE = V(g)$degbeg)
    return(infoNodes)
  })
  
  # create information table for edges
  InfoTableEdges <- reactive({
    g <- SelectYearRes()
    infoEdges <- get.data.frame(g)
    tabEdges <- data.frame(KEYWORD1 = infoEdges[ , 1],
                           KEYWORD2 = infoEdges[ , 2],
                           OBSERVED_WEIGHT = infoEdges[ , 3],
                           EXPECTED_WEIGHT = round(infoEdges[ , 4], 2),
                           RESIDUALS = round(infoEdges[ , 5], 2))
    return(tabEdges)
  })
  
  # select community
  SelectComm <- reactive({
    fullGraph <- SelectYearCom()
    commSubgraph <- induced.subgraph(fullGraph, vids=V(fullGraph)[V(fullGraph)$clus == input$commid])
  })
  
  # create semantic field
  SelectSemField <- reactive({
    fullGraph <- SelectYearSem()
    SemSubgraph <- SemanticField(fullGraph, kw = input$kwid2)
  })
  
  
  # outputs ----
  
  # panel "Data summary"
  
  output$textfull <- renderText({
    summarytext <- paste("<strong>Description :</strong> The network has <strong>",
                         vcount(SelectYearRes()), 
                         " vertices</strong> (number of keywords) and <strong>",
                         ecount(SelectYearRes()),
                         " edges</strong> (number of edges between keywords).",
                         sep = "")
  })
  
  output$contentsnodes <- renderDataTable({
    InfoTableNodes()
  })
  
  output$contentsedges <- renderDataTable({
    InfoTableEdges()
  })
  
  
  # panel "Communities"
  
  output$plotcomm <- renderPlot({
    if(input$vsizecom == "uni" && input$esizecom == "rel"){
      vertsize <- 1
      edgesize <- E(SelectComm())$relresid
    } else if(input$vsizecom == "uni" && input$esizecom == "nbl"){
      vertsize <- 1
      edgesize <- E(SelectComm())$obsfreq
    } else if(input$vsizecom == "poi" && input$esizecom == "rel"){
      vertsize <- V(SelectComm())$nbauth
      edgesize <- E(SelectComm())$relresid
    } else if(input$vsizecom == "poi" && input$esizecom == "nbl"){
      vertsize <- V(SelectComm())$nbauth
      edgesize <- E(SelectComm())$obsfreq
    } else if(input$vsizecom == "deg" && input$esizecom == "rel"){
      vertsize <- V(SelectComm())$degbeg
      edgesize <- E(SelectComm())$relresid
    } else if(input$vsizecom == "deg" && input$esizecom == "nbl"){
      vertsize <- V(SelectComm())$degbeg
      edgesize <- E(SelectComm())$obsfreq
    }
    
    VisuComm(SelectComm(), 
             comm = input$commid, 
             vertcol = "#2b3e50", 
             vertsize = vertsize, 
             vfacsize = input$vfacsizecom,
             edgesize = edgesize,
             efacsize = input$efacsizecom, 
             textsize = input$tsizecom)
    
  })
  
  output$downcomm <- downloadHandler(
    filename = "Community.svg",
    content = function(file) {
      if(input$vsizecom == "uni" && input$esizecom == "rel"){
        vertsize <- 30
        edgesize <- E(SelectComm())$relresid
      } else if(input$vsizecom == "uni" && input$esizecom == "nbl"){
        vertsize <- 30
        edgesize <- E(SelectComm())$obsfreq
      } else if(input$vsizecom == "poi" && input$esizecom == "rel"){
        vertsize <- V(SelectComm())$nbauth
        edgesize <- E(SelectComm())$relresid
      } else if(input$vsizecom == "poi" && input$esizecom == "nbl"){
        vertsize <- V(SelectComm())$nbauth
        edgesize <- E(SelectComm())$obsfreq
      } else if(input$vsizecom == "deg" && input$esizecom == "rel"){
        vertsize <- V(SelectComm())$degbeg
        edgesize <- E(SelectComm())$relresid
      } else if(input$vsizecom == "deg" && input$esizecom == "nbl"){
        vertsize <- V(SelectComm())$degbeg
        edgesize <- E(SelectComm())$obsfreq
      }
      
      svg(file, width = 20 / 2.54, height = 20 / 2.54, pointsize = 8)
      VisuComm(SelectComm(),
               comm = input$commid, 
               vertcol = "#2b3e50", 
               vertsize = vertsize, 
               vfacsize = input$vfacsizecom,
               edgesize = edgesize,
               efacsize = input$efacsizecom, 
               textsize = input$tsizecom)
      dev.off()
    })
  
  
  # panel "Semantic area"
  
  output$plotsem <- renderPlot({
    VisuSem(SelectSemField(), kw = input$kwid2, textsizemin = input$tsizesemmin, textsizemax = input$tsizesemmax)
  })
  
  output$downsem <- downloadHandler(
    filename = "Semantic.svg",
    content = function(file) {
      svg(file, width = 20 / 2.54, height = 20 / 2.54, pointsize = 8)
      VisuSem(SelectSemField(), kw = input$kwid2, textsizemin = input$tsizesemmin, textsizemax = input$tsizesemmax)
      dev.off()
    })
  
  
})

