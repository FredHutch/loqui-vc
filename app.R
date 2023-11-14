library(shiny)
library(reticulate)

# UI definition
ui <- fluidPage(
  titlePanel("Loqui for Voice Cloning (Prototype)"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("audio_file", "Choose a WAV file",
                accept = c("audio/wav")
      ),
      textAreaInput("text_input", "Enter Text:", value = "", rows = 4),
      actionButton("generate", "Generate")
    ),
    
    mainPanel(
      uiOutput("audio_ui"),
      br(),
      downloadButton("downloadOutput", "Download Output Audio")
    )
  )
)

# Server logic
server <- function(input, output) {
  
  observeEvent(input$generate, {
    if (!is.null(input$audio_file) && input$text_input != "") {
      
      inFile <- input$audio_file$datapath
      
      # Reticulate Python code
      
      # When deploying...
      # python_path <- Sys.getenv("PATH_TO_PYTHON", "/opt/homebrew/...")
      # reticulate::use_python(python_path)
      
      reticulate::use_python("/opt/homebrew/Caskroom/miniforge/base/bin/python")
      
      TTS_api <- reticulate::import("TTS.api")
      tts <- TTS_api$TTS("tts_models/multilingual/multi-dataset/xtts_v1.1", gpu = FALSE)
      
      tts$tts_to_file(text = input$text_input, 
                      max_new_tokens = 600,
                      file_path = "www/output.wav", 
                      speaker_wav = inFile, 
                      language = "en")
    }
    
    # Show audio when Generate is clicked
    output$audio_ui <- renderUI({
      tags$audio(src = "output.wav", 
                 type = "audio/wav",
                 autoplay = NA, 
                 controls = NA)
    })
  })
  
  # Show download button when Generate is clicked
  output$downloadOutput <- downloadHandler(
    filename = function() {
      "output.wav"
    },
    content = function(file) {
      file.copy("www/output.wav", file)
    },
    contentType = "audio/wav"
  )
}

# Create Shiny app
shinyApp(ui = ui, server = server)
