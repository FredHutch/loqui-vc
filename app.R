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
  
  titlePanel("Loqui for Voice Cloning (Prototype)"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("audio_file", "Choose a Waveform (WAV) Audio File",
                accept = c("audio/wav")
      ),
      textInput("gs_url", 
                label = "Google Slides URL (Enable Link Sharing)",
                placeholder = "Paste a Google Slides URL"),
      actionButton("generate", "Generate")
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
      ari::ari_spin_vc(image_path, pptx_notes_vector, output = "www/output.mp4", 
                       tts_engine_args = list(speaker_wav = audio_file_path,
                                              python_version = python_path))
    }

    # Show video when "Generate" is clicked
    output$video_ui <- renderUI({
      tags$video(src = "i/output.mp4", 
                 type = "video/mp4",
                 height ="480px", 
                 width="854px",
                 autoplay = TRUE,
                 controls = TRUE)
    })
    
    # Show download button when Generate is clicked
    output$download_video <- downloadHandler(
      filename = function() {
        "output.mp4"
      },
      content = function(file) {
        file.copy("www/output.mp4", file)
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