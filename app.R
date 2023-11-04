library(shiny)
library(reticulate)

# UI definition
ui <- fluidPage(
  titlePanel("Loqui for Voice Cloning"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("audioFile", "Choose a WAV file",
                accept = c("audio/wav")
      ),
      textAreaInput("textInput", "Enter Text:", value = "", rows = 4),
      actionButton("generateButton", "Generate")
    ),
    
    mainPanel(
      downloadButton("downloadOutput", "Download Output Audio")
    )
  )
)

# Server logic
server <- function(input, output) {
  
  observeEvent(input$generateButton, {
    if (!is.null(input$audioFile) && input$textInput != "") {
      
      inFile <- input$audioFile$datapath
      
      # Reticulate Python code
      
      # When deploying...
      # python_path <- Sys.getenv("PATH_TO_PYTHON", "/opt/homebrew/...")
      # reticulate::use_python(python_path)
      
      reticulate::use_python("/opt/homebrew/Caskroom/miniforge/base/bin/python")
      
      TTS_api <- reticulate::import("TTS.api")
      tts <- TTS_api$TTS("tts_models/multilingual/multi-dataset/xtts_v1.1", gpu = FALSE)
      
      tts$tts_to_file(text = input$textInput, 
                      max_new_tokens = 600,
                      file_path = "output.wav", 
                      speaker_wav = inFile, 
                      language = "en")
    }
  })
  
  output$downloadOutput <- downloadHandler(
    filename = function() {
      "output.wav"
    },
    content = function(file) {
      file.copy("output.wav", file)
    },
    contentType = "audio/wav"
  )
  
}

# Create Shiny app
shinyApp(ui = ui, server = server)
