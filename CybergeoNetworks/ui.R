library(shiny)

shinyUI(fluidPage(theme = "darkBlue.css",
                  # favicon
                  tags$head(tags$link(rel="shortcut icon", href="favicon.png")),
                  
                  tags$head(
                    # specific font
                    tags$style(HTML("
      @import url('//fonts.googleapis.com/css?family=Orbitron|Cabin:400,700');
    "))
                ),
                  headerPanel(
                    "CybergeoNetworks"
                    #             
                  ),
                  titlePanel(h4("20 years of Cybergeo, European Journal of Geography")),
                  
                  navlistPanel(
                    #"Looking back",
                    tabPanel("The Project",
                             fluidRow(
                               
                               column(9, h1("Cybergeo | 1996-2016", 
                                            style = "font-family: 'Orbitron', sans-serif;
                                             font-weight: 500; line-height: 1.1; 
                                             color: #ffffff;"),
                                      tags$p(class="text-justify",
                                             "Cybergeo turns 20: it???s time to look back for reflection and to anticipate future evolution!", br())) ,
                               column(3, img(src = "favicon.png",class="img-responsive")),
                               column(12,h4("The editorial policy"), 
                                      tags$p(class="text-justify", "First entirely electronic journal for social sciences in the world, peer reviewed, European, open (free of charge for authors and readers), with a focus on geography and widely open to the diversity of research agendas and methodologies in all countries.
                                      Cybergeo is a success story with now more than one million papers downloaded every year."), br(), 
                                      h4("An app to look back"), 
                                      tags$p(class="text-justify", "This app builds on 20 years of publication in Cybergeo.
                                     You can play with data, drawing geographical networks of authoring, 
                                      studying and citing through countries, analyzing semantic networks per key words and articles content, 
                                      you can review twenty years of epistemological and thematic trends in a variety of fields of scientific interest. 
                                        The networks tell who studies what, where and how. Data are regularly updated."         
                                      )))
                    ),
                    "-----",
                    tabPanel("Overview",
                             fluidRow(h2("Global Stats"),
                                      column(6, sliderInput("dateRange", label = "Time Range",
                                                            min = 1996, max = 2015, value = c(1996,2015), step = 1), animate=T),
                                      column(6, selectInput("whatMapped", label = "Indicator to map",
                                                            choices=c("Authoring countries" = "A", 
                                                                      "Countries Studied"= "S",  
                                                                      "Countries Studies by Locals"= "L"), multiple=F)),
                                      column(12, plotOutput("cybMap")),
                                      column(12, dataTableOutput('statArticles')),
                                      div(dataTableOutput("tableName"), style = "font-size:120%")
                             )),
                    
                    
                    
                    tabPanel("Citation network",
                             # fluidRow(h2("Exploring the citation network"),
                             #          #h4("...",br())
                             #          forceNetworkOutput("citationNetwork")
                             # )
                             
                             tabsetPanel(
                               tabPanel("Citation Network",
                                        # select article to visualize
                                        fluidRow(
                                          h4("Data Selection"),
                                          tags$p(class="text-justify","Search and select a cybergeo paper in the table."),
                                          htmlOutput("citationdataloading"),
                                          dataTableOutput("citationcybergeo")
                                        ),
                                        # citation ego network
                                        fluidRow(
                                          h4("Citation network neighborhood"),
                                          tags$p(class="text-justify","This graph shows the citation neighborhood of the selected paper"),
                                          selectInput(inputId = "citationselected", 
                                                      label = "Select a publication by id", 
                                                      choices = c("",sort(citation_cybergeodata$id[citation_cybergeodata$linknum>0],decreasing = TRUE)),
                                                      selected = "",
                                                      multiple = FALSE),
                                          column(12,plotOutput("citationegoplot", width = "100%", height = "800px"))
                                        ),
                                        # word clouds of semantic content
                                        fluidRow(
                                          h4("Semantic content"),
                                          tags$p(class="text-justify","This graph shows the semantic content (color legend in user guide) of the paper (left) and its neighborhood (right)."),
                                          selectInput(inputId = "citationsemanticselected", 
                                                      label = "Select a publication by id", 
                                                      choices = c("",sort(citation_cybergeodata$id[citation_cybergeodata$kwcount>0],decreasing = TRUE)),
                                                      selected = "",
                                                      multiple = FALSE),
                                          column(12,plotOutput("citationesemanticplot", width = "100%", height = "800px"))
                                        )
                               ),
                               # svg viusalization of the full semantic network
                               tabPanel("Semantic Network",
                                        h4("Full Semantic Network"),
                                        column(12,svgPanZoomOutput(outputId = "citationsemanticnw",width = "100%", height = "100%"))
                               ),
                               # user guide
                               tabPanel("User guide",
                                        # describe data provenance and signification of measures      
                                        includeMarkdown("doc/CitationNetwork.md")
                               )
                             )
                    ),
                    
                    
                    
                    
                    tabPanel("Full-text Semantic network",
                             fluidPage(
                               column(
                                 3,
                                 # Select an option in order to compute the interface (one or more patterns) and the outputs
                                 selectInput("mode", "Mode", c(
                                   "Single Pattern Analysis" = "one", 
                                   "Multiple Pattern Analysis" = "multi",
                                   "Parameterisation" = "param"
                                 )
                                 ),
                                 conditionalPanel(
                                   "input.mode == 'multi' | input.mode == 'one'",
                                   textInput("pattern_input", "Pattern")
                                 ),
                                 conditionalPanel(
                                   "input.mode == 'multi'",
                                   actionButton("add_pattern", "Add to Selection"),
                                   p(),
                                   checkboxGroupInput("patterns_selection", "Pattern Selection", pattern_list)
                                 )
                               ),
                               column(
                                 9,
                                 # All the outputs panel
                                 tabsetPanel(
                                   # show a chronogram of the number of match per year
                                   tabPanel("Chronogram",
                                            plotOutput("chronogram", height = "700px")
                                   ),
                                   # show a wordcloud of the matched items
                                   tabPanel(
                                     "Word Cloud",
                                     plotOutput("cloud", height = "700px")
                                   ),
                                   # show the sentences including a term that matches a pattern
                                   tabPanel("Sentences", verbatimTextOutput("phrases")),
                                   # show the articles including a term that matches a pattern
                                   tabPanel("Citations", verbatimTextOutput("citations"))
                                 )))),
                    
                    
                    
                    
                    tabPanel("Keyword network",
                             
                             tabsetPanel(
                               
                               tabPanel("Data summary",
                                        fluidRow(
                                          htmlOutput("textfull"),
                                          tags$hr(),
                                          dataTableOutput("contentsnodes"),
                                          dataTableOutput("contentsedges")
                                        )),
                               
                               tabPanel("Communities",
                                        fluidRow(
                                          column(8, selectInput(inputId = "commid", 
                                                                label = "Choose a community", 
                                                                choices = "",
                                                                selected = "",
                                                                multiple = FALSE))),
                                        fluidRow(
                                          column(12, 
                                                 fluidRow(
                                                   column(3, wellPanel(
                                                     tags$strong("Graphic options"),
                                                     radioButtons("vsizecom", "Nodes proportional to:",
                                                                  list("Uniforme" = "uni",
                                                                       "Number of articles" = "poi",
                                                                       "Nodes degree" = "deg")),
                                                     radioButtons("esizecom", "Edges proportional to:",
                                                                  list("Observed weight" = "nbl",
                                                                       "Residuals" = "rel")),
                                                     sliderInput(inputId = "vfacsizecom", 
                                                                 label = "Nodes size", 
                                                                 min = 0, 
                                                                 max = 1, 
                                                                 value = 0.5, 
                                                                 step = 0.05),
                                                     sliderInput(inputId = "efacsizecom", 
                                                                 label = "Edges size", 
                                                                 min = 0, 
                                                                 max = 2, 
                                                                 value = 1, 
                                                                 step = 0.1),
                                                     sliderInput(inputId = "tsizecom",
                                                                 label = "Font size", 
                                                                 min = 1, 
                                                                 max = 15, 
                                                                 value = 10, 
                                                                 step = 1),
                                                     downloadButton("downcomm", "Download plot"))),
                                                   
                                                   column(9, plotOutput("plotcomm", width = "100%", height = "800px")))))
                               ),
                               
                               
                               tabPanel("Semantic area",
                                        fluidRow(
                                          column(8, selectInput(inputId = "kwid2", 
                                                                label = "Choose a keyword", 
                                                                choices = "", 
                                                                selected = "", 
                                                                multiple = FALSE))),
                                        fluidRow(
                                          column(12, 
                                                 fluidRow(
                                                   column(3, wellPanel(
                                                     tags$strong("Graphic options"),
                                                     sliderInput(inputId = "tsizesemmin", 
                                                                 label = "Font size (min)", 
                                                                 min = 1, 
                                                                 max = 10, 
                                                                 value = 4, 
                                                                 step = 0.5),
                                                     sliderInput(inputId = "tsizesemmax", 
                                                                 label = "Font size (max)", 
                                                                 min = 1, 
                                                                 max = 10, 
                                                                 value = 6, 
                                                                 step = 0.5),
                                                     downloadButton("downsem", "Download plot"))),
                                                   
                                                   column(9, plotOutput("plotsem", width = "100%", height = "800px")))))
                               ),
                               
                               
                               
                               
                               
                               
                               tabPanel("User guide",
                                        withMathJax(), 
                                        includeMarkdown("doc/README_HC.md"))
                             )
                    ),
                    
                    
                    tabPanel("Geo-semantic Networks",
                             
                             tabsetPanel(
                               
                               tabPanel("Geo-semantic Networks",
                                        fluidRow(##h2("Geo-semantic Networks"),
                                          
                                          column(4, selectInput("semanticMethod", label = "Semantic Method",
                                                                choices = c("Citations", "Keywords", "Semantic"), multiple = F)),
                                          column(4, selectInput("aggregationMethod", label = "Set of Countries",choices = c("Authoring", "Studied"), 
                                                                selected = "Studied", multiple = F)),
                                          column(4, sliderInput("nClassifGroups", label = "Number of Clusters",
                                                                min = 1, max = 8, value = 4, step = 1), animate=T),
                                          column(12, plotOutput("termsXCountriesMap")),
                                          column(12, plotOutput("termsXCountriesLegend"))
                                        )
                               ),
                               tabPanel("User guide",
                                        includeMarkdown("doc/GeoSemanticNetworks.md")
                               )
                             )
                    ),
                    ############## 
                    
                    
                    "-----",
                    tabPanel("About",
                             fluidRow(
                               
                               column(9, h2("About Cybergeo"),
                                      a("cybergeo.revues.org/",href="http://cybergeo.revues.org/"),br()),
                               column(3, img(src = "favicon.png",class="img-responsive"))
                             )
                    )
                    
                  )))
