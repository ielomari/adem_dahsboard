# app.R
library(shiny)
library(shinydashboard)
library(DBI)
library(RPostgres)
library(ggplot2)
library(plotly)
library(dplyr)
library(shinyjs)

source("../scripts/connect_db.R")

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "ADEM - Chiffres Clés"),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("#loading-content {position:absolute;z-index:10000;background:white;left:0;right:0;top:0;bottom:0;display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:bold;} #main-content {display:none;}"))
    ),
    div(id = "loading-content", "Chargement en cours..."),
    div(id = "main-content",
        selectInput("selected_month", "Choisir une date", choices = NULL),
        fluidRow(
          valueBoxOutput("box_demandeurs"),
          valueBoxOutput("box_mesures"),
          valueBoxOutput("box_chomage"),
          valueBoxOutput("box_indemnite"),
          valueBoxOutput("box_vacants"),
          valueBoxOutput("box_nouveaux")
        ),
        fluidRow(box("Évolution des demandeurs d'emploi", width=12, plotlyOutput("plot_demandeurs"))),
        fluidRow(box("Postes déclarés vs Vacants", width=12, plotlyOutput("plot_offres"))),
        fluidRow(box("Répartition par mesure", width=12, plotlyOutput("plot_mesures"))),
        fluidRow(
          box("Indemnisés - évolution", width=6, plotlyOutput("plot_indemnises")),
          box("Indemnisés par résidence", width=6, plotlyOutput("bar_indemnises_residence"))
        ),
        fluidRow(
          box("Genre", width=6, plotlyOutput("bar_genre")),
          box("Diplôme", width=6, plotlyOutput("bar_diplome"))
        ),
        fluidRow(
          box("Âge", width=6, plotlyOutput("bar_age")),
          box("Durée inscription", width=6, plotlyOutput("bar_duree_inscription"))
        ),
        fluidRow(box("Statut spécifique", width=12, plotlyOutput("bar_statut")))
    )
  )
)

server <- function(input, output, session) {
  con <- connect_db()
  
  fetch_sum <- function(query_template) {
    query <- sprintf(query_template, input$selected_month)
    dbGetQuery(con, query)[[1]]
  }
  
  observe({
    dates <- dbGetQuery(con, "SELECT DISTINCT date_ref FROM student_ibtissam.demandeurs_profils ORDER BY date_ref DESC")$date_ref
    updateSelectInput(session, "selected_month", choices = dates, selected = max(dates))
  })
  
  observeEvent(input$selected_month, {
    shinyjs::hide("loading-content")
    shinyjs::show("main-content")
  })
  
  render_box <- function(id, query, label, icon_name, color) {
    output[[id]] <- renderValueBox({
      req(input$selected_month)
      valueBox(format(fetch_sum(query), big.mark = " "), label, icon = icon(icon_name), color = color)
    })
  }
  
  render_box("box_demandeurs", "SELECT SUM(personnes) FROM student_ibtissam.demandeurs_profils WHERE date_ref = '%s'", "Demandeurs d'emploi", "users", "red")
  render_box("box_mesures", "SELECT SUM(personnes) FROM student_ibtissam.demandeurs_mesures WHERE date_ref = '%s'", "Résidents en mesure", "user-check", "orange")
  render_box("box_chomage", "SELECT SUM(chomage_complet) FROM student_ibtissam.demandeurs_indemnites WHERE date_ref = '%s'", "Chômage complet", "hand-holding-dollar", "blue")
  render_box("box_indemnite", "SELECT SUM(indemnite_pro_attente) FROM student_ibtissam.demandeurs_indemnites WHERE date_ref = '%s'", "Indemnité attente", "money-bill-wave", "purple")
  render_box("box_vacants", "SELECT SUM(stock_postes_vacants) FROM student_ibtissam.offres_details WHERE date_ref = '%s'", "Postes vacants", "briefcase", "green")
  render_box("box_nouveaux", "SELECT SUM(postes_declares) FROM student_ibtissam.offres_series WHERE date_ref = '%s'", "Nouveaux postes", "plus", "aqua")
  
  render_plotly_query <- function(output_id, query_template, aes_mapping, fill=NULL, flip=FALSE, color=NULL, line=FALSE) {
    output[[output_id]] <- renderPlotly({
      req(input$selected_month)
      df <- dbGetQuery(con, sprintf(query_template, input$selected_month))
      p <- ggplot(df, aes_string(x = aes_mapping$x, y = aes_mapping$y))
      if (line) {
        p <- p + geom_line(color = color)
      } else {
        p <- p + geom_col(fill = fill)
        if (flip) p <- p + coord_flip()
      }
      ggplotly(p)
    })
  }
  
  # Graphiques principaux
  output$plot_demandeurs <- renderPlotly({
    df <- dbGetQuery(con, "SELECT date_ref, SUM(personnes) AS total FROM student_ibtissam.demandeurs_profils GROUP BY date_ref ORDER BY date_ref")
    ggplotly(ggplot(df, aes(x = as.Date(date_ref), y = total)) + geom_line(color = "darkred"))
  })
  
  output$plot_offres <- renderPlotly({
    df <- dbGetQuery(con, "SELECT date_ref, SUM(postes_declares) AS declares, SUM(stock_postes_vacants) AS vacants FROM student_ibtissam.offres_details GROUP BY date_ref ORDER BY date_ref")
    ggplotly(ggplot(df, aes(x = as.Date(date_ref))) +
               geom_line(aes(y = declares, color = "Déclarés")) +
               geom_line(aes(y = vacants, color = "Vacants")) +
               scale_color_manual(values = c("Déclarés" = "steelblue", "Vacants" = "forestgreen")))
  })
  
  render_plotly_query("plot_mesures", "SELECT mesure, SUM(personnes) AS total FROM student_ibtissam.demandeurs_mesures WHERE date_ref = '%s' GROUP BY mesure", list(x="reorder(mesure, total)", y="total"), fill="orange", flip=TRUE)
  render_plotly_query("plot_indemnises", "SELECT date_ref, SUM(chomage_complet) AS total FROM student_ibtissam.demandeurs_indemnites GROUP BY date_ref ORDER BY date_ref", list(x="as.Date(date_ref)", y="total"), line=TRUE, color="steelblue")
  render_plotly_query("bar_indemnises_residence", "SELECT residence, SUM(chomage_complet) AS total FROM student_ibtissam.demandeurs_indemnites WHERE date_ref = '%s' GROUP BY residence", list(x="reorder(residence, total)", y="total"), fill="#2c3e50", flip=TRUE)
  render_plotly_query("bar_genre", "SELECT genre, SUM(personnes) AS total FROM student_ibtissam.demandeurs_profils WHERE date_ref = '%s' GROUP BY genre", list(x="total", y="genre"), fill="#c0392b")
  render_plotly_query("bar_diplome", "SELECT niveau_diplome, SUM(personnes) AS total FROM student_ibtissam.demandeurs_profils WHERE date_ref = '%s' GROUP BY niveau_diplome", list(x="reorder(niveau_diplome, total)", y="total"), fill="#6a51a3", flip=TRUE)
  render_plotly_query("bar_age", "SELECT age, SUM(personnes) AS total FROM student_ibtissam.demandeurs_profils WHERE date_ref = '%s' GROUP BY age", list(x="reorder(age, total)", y="total"), fill="#1f77b4", flip=TRUE)
  render_plotly_query("bar_duree_inscription", "SELECT duree_inscription, SUM(personnes) AS total FROM student_ibtissam.demandeurs_profils WHERE date_ref = '%s' GROUP BY duree_inscription", list(x="reorder(duree_inscription, total)", y="total"), fill="#ff7f0e", flip=TRUE)
  render_plotly_query("bar_statut", "SELECT statut_specifique, SUM(personnes) AS total FROM student_ibtissam.demandeurs_profils WHERE date_ref = '%s' GROUP BY statut_specifique", list(x="reorder(statut_specifique, total)", y="total"), fill="#2ca02c", flip=TRUE)
  
  onStop(function() {
    dbDisconnect(con)
  })
}

shinyApp(ui, server)
