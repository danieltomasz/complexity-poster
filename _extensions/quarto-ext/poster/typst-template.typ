#let poster(
  // The poster's size (e.g., "36x24", "48x36", "33x47"). // <--- Updated comment example
  size: "'36x24' or '48x36''", // This default description doesn't strictly matter when overridden by QMD

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // You might need to tweak these for different aspect ratios like 33x47.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3", // Default is already 3

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  // Might need adjustment for 33in width
  univ_logo_column_size: "4", // Example adjustment: Reduced from 10 for narrower poster

  // Title and authors' column size (in in).
  // Might need adjustment for 33in width
  title_column_size: "18", // Example adjustment: Reduced from 20

  // Poster title's font size (in pt).
  // Might need adjustment for new size
  title_font_size: "55", // Example adjustment: Slightly smaller

  // Authors' font size (in pt).
  // Might need adjustment for new size
  authors_font_size: "36", // Example adjustment: Slightly smaller

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "36", // Example adjustment: Slightly smaller

  // Footer's text font size (in pt).
  footer_text_font_size: "36", // Example adjustment: Slightly smaller

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "Open Sans", size: 32pt) // Base body font size - might need adjustment too
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  set page(
    width: width,
    height: height,
    margin: (top: 1in, left: 1.5in, right: 1.5in, bottom: 1.5in), // Example adjustment: Slightly reduced side margins
    footer: [
      #set align(center)
      #set text(32pt) // Base footer size, might need tweaking
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 15pt, // Example adjustment: Slightly smaller inset
        radius: 10pt,
        [
          #text(font: "Courier", size: footer_url_font_size, footer_url)
          #h(1fr)
          #text(size: footer_text_font_size, smallcaps(footer_text))
          #h(1fr)
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 30pt, body-indent: 9pt)
  set list(indent: 30pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    let levels = counter(heading).at(loc)
    let deepest = if levels != () { levels.last() } else { 1 }

    set text(40pt, weight: "regular") // Example adjustment: Slightly smaller base heading size
    if it.level == 1 [
      #set align(left)
      #set text({ 44pt }) // Example adjustment: Smaller Level 1 heading
      #show: smallcaps
      #set text(weight: "bold") // Make it bold
      #v(1.5em, weak: true)     // Space before heading (adjust 1.5em)
      //#show: smallcaps
      #v(40pt, weak: true) // Example adjustment: Reduced spacing
      #if it.numbering != none {
        numbering("1.", deepest)
        h(0.5em, weak: true)    // Space after number (adjust 0.5em)
      }
      #it.body
      #v(30pt, weak: true) // Example adjustment: Reduced spacing
      #line(length: 100%)
    ] else if it.level == 2 [
      #set text(style: "italic")
      #v(28pt, weak: true) // Example adjustment: Reduced spacing
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(8pt, weak: true) // Example adjustment: Reduced spacing
    ] else [
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Arranging the logo, title, authors, and department in the header.
  align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size),
      column-gutter: 0pt,
      row-gutter: 40pt, // Example adjustment: Reduced spacing
      //image(univ_logo, width: univ_logo_scale),
      image(univ_logo,  height: 3.0in),
      text(title_font_size, title + "\n") +
      text(authors_font_size, emph(authors) +
           "  (" + departments + ") "),
    )
  )

  // Start three column mode and configure paragraph properties.
  // Use the num_columns parameter. Adjust gutter if needed.
  show: columns.with(num_columns, gutter: 48pt) // Example adjustment: Reduced gutter for narrower columns
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(28pt, weight: 400) // Example adjustment: Smaller keyword size
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}
#show bibliography: set text(size: 20pt) // Adjust 26pt as needed
