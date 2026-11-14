#' Generate an HTML5 Zero-Footprint Medical Imaging Viewer Scaffold
#'
#' Produces a lightweight HTML5 container configured for Cornerstone3D
#' (DICOMweb WADO-RS) or NiiVue (NIfTI / 3D overlay QA).
#'
#' @param study_uid StudyInstanceUID to display.
#' @param viewer Viewer engine: `"cornerstone3d"` or `"niivue"`.
#' @param dicomweb_url Base DICOMweb endpoint URL.
#'
#' @return Character string containing the HTML5 viewer fragment.
#' @examples
#' html <- server_viewer_html("1.2.840.113619.2.55", viewer = "cornerstone3d")
#' grepl("cornerstone3d", html)
#' @export
server_viewer_html <- function(study_uid = "",
                               viewer = c("cornerstone3d", "niivue"),
                               dicomweb_url = "/dicomweb") {
  viewer <- match.arg(viewer)
  sprintf(
    paste0(
      "<div id='dicomtk-viewer' class='dicomtk-viewer-container' ",
      "data-viewer='%s' data-study-uid='%s' data-dicomweb-url='%s' ",
      "style='width:100%%;height:480px;background:#0b1020;color:#d6e0f0;padding:16px;border-radius:8px;'>",
      "<h4>%s Viewport</h4>",
      "<p>Study UID: <code>%s</code> | DICOMweb: <code>%s</code></p>",
      "<canvas id='dicomtk-viewport-canvas' width='512' height='360'></canvas>",
      "</div>"
    ),
    viewer, study_uid, dicomweb_url,
    if (identical(viewer, "cornerstone3d")) "Cornerstone3D" else "NiiVue",
    study_uid, dicomweb_url
  )
}

#' Build the `shiny` Portal UI for `dicomtk.server`
#'
#' @param ctx A `"dicom_server_context"` object.
#' @return A `shiny` UI tag list.
#' @export
server_shiny_ui <- function(ctx) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg shiny} is required for the web portal UI.")
  }
  shiny::fluidPage(
    shiny::titlePanel("dicomtk.server Clinical Imaging & Honest-Broker Portal"),
    shiny::tabsetPanel(
      shiny::tabPanel("Projects", shiny::tableOutput("tbl_projects")),
      shiny::tabPanel("QA Queue", shiny::tableOutput("tbl_qa")),
      shiny::tabPanel("Viewer", shiny::HTML(server_viewer_html(viewer = "cornerstone3d"))),
      shiny::tabPanel("Audit Integrity", shiny::verbatimTextOutput("txt_audit"))
    )
  )
}

#' Build the `shiny` Server Function for `dicomtk.server`
#'
#' @param ctx A `"dicom_server_context"` object.
#' @return A `shiny` server `function(input, output, session)`.
#' @export
server_shiny_server <- function(ctx) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg shiny} is required for the web portal server.")
  }
  function(input, output, session) {
    output$tbl_projects <- shiny::renderTable(project_list(ctx$projects))
    output$tbl_qa <- shiny::renderTable(qa_list(ctx$qa_queue))
    output$txt_audit <- shiny::renderPrint(audit_verify(ctx$logger))
  }
}
