library(shiny)
library(reticulate)
# Increase maximum file upload size to 10 MB
options(shiny.maxRequestSize = 10 * 1024^2)

# UI definition
ui <- fluidPage(
  # Hutch theme CSS
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", 
              href = "i/hutch_theme.css")
  ),
  # Favicon
  tags$head(tags$link(rel="shortcut icon", href="i/img/favicon.ico")),
  
  titlePanel(tagList(
    "Loqui for Voice Cloning",
    span(
      actionButton("help", 
                   label = "Help",
                   icon = icon("circle-exclamation"),
                   width = "77px",
                   onclick ="window.open(`https://github.com/FredHutch/loqui-vc/issues/new`, '_blank')"),
      actionButton("github",
                   label = "Code",
                   icon = icon("github"),
                   width = "77px",
                   onclick ="window.open(`https://github.com/FredHutch/loqui-vc`, '_blank')"),
      style = "position:absolute;right:2em;"
    )
  ),
  windowTitle = "Voice Cloning"),
  hr(),
  sidebarLayout(
    sidebarPanel(
      fileInput("audio_file", "Choose a Waveform (WAV) Audio File",
                accept = c("audio/wav")
      ),
      textInput("gs_url", 
                label = "Google Slides URL (Enable Link Sharing)",
                placeholder = "Paste a Google Slides URL"),
      actionButton("generate", "Generate"),
      br(),
      br(),
            h5("Built with",
         img(src = "https://www.rstudio.com/wp-content/uploads/2014/04/shiny.png", height = "30px"),
         "by",
         img(src = "i/img/posit.jpeg", height = "30px")
      ),
      tags$img(src = "i/img/logo.png", width = "90%")
    ),
    mainPanel(
      uiOutput("video_ui"),
      br(),
      downloadButton("download_video", "Download Video")
    )
  )
)

# Server logic
server <- function(input, output) {
  # create unique video name
  video_name <- eventReactive(input$generate, {
    current_time <- Sys.time()
    current_time <- format(current_time, "%Y-%m-%d-%H-%M-%S")
    unique_file_name <- paste0("www/video-", current_time, ".mp4")
    
    unique_file_name
  })
  
  observeEvent(input$generate, {
    if (!is.null(input$audio_file) && input$gs_url != "") {
      # WAV Audio file of speaker
      audio_file_path <- input$audio_file$datapath
      # URL to Google Slides
      gs_url <- input$gs_url
      # Python version
      python_path <- "/opt/homebrew/Caskroom/miniforge/base/bin/python"
      
      # download google slides as pptx
      pptx_path <- gsplyr::download(gs_url, type = "pptx")
      # extract notes from pttx
      pptx_notes_vector <- ptplyr::extract_notes(pptx_path)
      
      # download google slides as pdf
      pdf_path <- gsplyr::download(gs_url, type = "pdf")
      # convert pdf to png
      image_path <- ptplyr::convert_pdf_png(pdf_path)
      
      # Run ari_spin_vc()
      ari::ari_spin_vc(image_path, pptx_notes_vector, output = video_name(), 
                       tts_engine_args = list(speaker_wav = audio_file_path,
                                              python_version = python_path))
    }

    # Show video when "Generate" is clicked
    output$video_ui <- renderUI({
      
      video_name_processed <- gsub("www/", "i/", video_name())
      
      tags$video(src = video_name_processed, 
                 type = "video/mp4",
                 height ="480px", 
                 width="854px",
                 autoplay = TRUE,
                 controls = TRUE)
    })
    
    # Show download button when Generate is clicked
    output$download_video <- downloadHandler(
      filename = function() {
        gsub("www/", "", video_name())
      },
      content = function(file) {
        file.copy(video_name(), file)
      },
      contentType = "video/mp4"
    )
  })
}

# Code for Deployment to Hutch servers
addResourcePath("/i", file.path(getwd(), "www"))
options <- list()
if (!interactive()) {
  options$port = 3838
  options$launch.browser = FALSE
  options$host = "0.0.0.0"
  
}

# Create Shiny app
shinyApp(ui = ui, server = server)