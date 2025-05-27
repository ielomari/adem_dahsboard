library(shiny)
library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)

# Charger la fonction de connexion
source("../scripts/connect_db.R")

ui <- fluidPage(
  titlePanel("📊 Suivi des ouvertures et clôtures de dossiers (ADEM)"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("residence", "Filtrer par résidence :",
                  choices = NULL, selected = NULL)
    ),
    
    mainPanel(
      plotOutput("plot_flux"),
      br(),
      tableOutput("table_flux")
    )
  )
)

server <- function(input, output, session) {
  con <- connect_db()
  DBI::dbExecute(con, "SET search_path TO student_ibtissam;")
  
  # Charger les résidences pour le menu déroulant
  residences <- DBI::dbGetQuery(con, "SELECT DISTINCT residence FROM demandeurs_flux ORDER BY residence")
  updateSelectInput(session, "residence", choices = residences$residence)
  
  # Données filtrées
  flux_data <- reactive({
    req(input$residence)
    
    DBI::dbGetQuery(con, sprintf("
      SELECT * FROM demandeurs_flux
      WHERE residence = '%s'
      ORDER BY date_ref
    ", input$residence))
  })
  
  # Graphique
  output$plot_flux <- renderPlot({
    df <- flux_data()
    ggplot(df, aes(x = date_ref)) +
      geom_line(aes(y = ouvertures, color = "Ouvertures")) +
      geom_line(aes(y = clotures, color = "Clôtures")) +
      labs(y = "Nombre", color = "Légende") +
      theme_minimal()
  })
  
  # Aperçu de la table
  output$table_flux <- renderTable({
    flux_data() %>% head(10)
  })
  
  # Déconnexion propre
  onSessionEnded(function() {
    DBI::dbDisconnect(con)
  })
}

shinyApp(ui, server)
