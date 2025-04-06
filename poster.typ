// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

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
  num_columns: "2", // Default is already 3

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
  set heading(numbering: none ) // Was: set heading(numbering: "I.A.1.")
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

// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// This file calls the 'poster' function defined in the 'typst-template.typ' file to render your poster to PDF when you press the Render button.
// Make any edits to the template in the typst-template.typ file
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [Can Fractal and Complexity Measures of Electrophysiological Signals Be Used to Study Subjective Experience?], 
  // TODO: use Quarto's normalized metadata.
   authors: [Daniel Borek], 
   departments: [Ghent University, Faculty of Psychology and Educational Sciences, Department of Data-Analysis], 
   size: "33x47", 

  // Institution logo.
   univ_logo: "./images/logoUGent.png", 

  // Institution image.
  
  
  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [Value, Valence, and Consciousness Workshop], 

  // Any URL, like a link to the conference website.
   footer_url: [Brussels April 2025], 

  // Emails of the authors.
   footer_email_ids: [daniel.borek\@ugent.be], 

  // Color of the header.
  
  
  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // Typical medical meeting posters are 60 or 72 in wide x 30 or 36 in tall
  // in the US
  // Or 100 cm wide by 189 cm tall  in Europe.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
   keywords: ("Complexity", "Criticality", "Consciousness"), 

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // University image's scale (in %).
  
  
    // University image's column size (in in).
  
  
  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)

#block(
  fill: rgb("#E0FFFF"),  // Keep your desired pastel background
  stroke: blue + 1pt,    // Keep your desired border
  radius: 8pt,           // INCREASED from ~4pt for more rounded corners
  inset: 15pt,           // INCREASED from ~8pt for more space around text
)[
  Your content goes here. This area should now feel
  a bit roomier, and the corners of the box will
  be more noticeably curved. Adjust the values
  for radius and inset until you are satisfied.
]
- complexity, critialicy and related approaches looking for system dynamics and variability are gaining traction in neurosicence
- Biomarkers based on it are succesful in discrimating states of consciousness, whiile effort was directed toward styding the content
- conscious experience is rich and has high dimensional structure @ji2024SourcesRichnessIneffability, which is set the problem suitable for next set of tool arising from statistical physics and complexity science

= Quantifying information during conscious experience
<quantifying-information-during-conscious-experience>
#figure([
#box(image("images/measures.svg"))
], caption: figure.caption(
separator: "", 
position: bottom, 
[
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-example>


Richness of conscious experience pose a question to the neuroscience

::: \# Brain criticality

Criticality is the singular state of complex systems poised at the brink of a phase transition between order and randomness.

= Power laws and 1/f noise
<power-laws-and-1f-noise>
#cite(<ji2024SourcesRichnessIneffability>, form: "prose")

= Consciousness measures and Complexity
<consciousness-measures-and-complexity>
- Repertoire of states
- Integration and unity
- Effects of psycholics on complexity

Add graph about 1/f aperiodic term

- add tables with differnt measures explained

- add soort of SCHEMES

- START FROM WRITING MESSAGES

- autopoiesis as reference?? self organisation of life

graph of different frameworks - how we could combine it with neurophenomenology?

- flexibility in relation to environment?

- complexity of signal reflects structure of the generators?

- microstates

- complexity of brain signal will reflect inner processes but also envirobmnet

- meditation vs effort

\-richness of experience - Information theory - dynamical systems

This poster presents a perspective on bridging quantitative measures of neural dynamics with phenomenal consciousness. The connection between self-organizing systems and spectral 1/f phenomena predates the recent surge in studies. Currently, these measures are being used to differentiate states of consciousness (e.g., distinguishing between minimally conscious and vegetative states, identifying sleep phases) and are also applied in research on psychedelics (e.g., the "entropic brain" hypothesis, where stimulants increase the complexity and richness of neuronal communication).

= Complexity measures for EEG
<complexity-measures-for-eeg>
#text(size: 22pt)[
  #table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: (left, left, left, left, left),
    fill: (_, row) => if row == 0 { rgb(240, 240, 245) } else { white },
    stroke: (x, y) => if y == 0 { (bottom: 1.5pt) } else { 0.5pt },
    
    [*Method*], [*Domain*], [*Key Characteristics*], [*Strengths*], [*Limitations*],
    
    [*Auto-correlation decay time*], [Time], [Measures how quickly signal decorrelates with itself], [Correlates with knee frequency; relationship with age persists after accounting for exponent], [—],
    
    [*Hurst Exponent*], [Time], [Quantifies long-term memory of time series], [Measures statistical dependence between distant points], [More influenced by oscillations],
    
    [*DFA* (Detrended Fluctuation Analysis)], [Time], [Examines how fluctuations scale with window size], [Removes overall trends first], [—],
    
    [*Fractal Dimension metrics* (Higuchi, Katz, Petrosian)], [Time], [Measure signal complexity and self-similarity], [Katz fractal dimension less affected by oscillations], [—],
    
    [*Lempel-Ziv Complexity*], [Time], [Counts unique patterns in binarized signal], [Less affected by oscillations], [—],
    
    [*Entropy measures* (ApEn, SampEn, PE, WPE)], [Time], [Quantify signal unpredictability], [Sample entropy less affected by oscillations], [Permutation entropy strongly influenced by oscillations],
    
    [*Spectral Parameterization* (SpecParam/FOOOF)], [Frequency], [Models both periodic and aperiodic components], [Handles knees and broad peaks well; directly separates oscillations from background], [More complex modeling approach],
    
    [*IRASA*], [Frequency], [Separates components through resampling], [Directly separates oscillations from background], [Less effective with knees or non-scale-free signals]
  )
]
Increased entropy or fractal dimension often correlates with positive affective states (e.g., psychedelics) and cognitive flexibility, whereas reduced complexity is observed in conditions such as depression. These patterns frequently involve NMDA receptors modulation~ ( excitation-inhibition framework), providing a mechanistic link to various conditions that alter subjective experience, including schizophrenia and ADHD. Additionally, age-related changes in spectral slope correlate with cognitive reserve capacity, suggesting that variations in brain dynamics may \# fundamentally shape phenomenological experience across the lifespan.

= Summary
<summary>
Despite its promise, there is not yet a coherent framework linking everyday subjective experience with these quantitative measures of neural dynamics. This poster synthesizes primary research directions and highlights potential underlying biological mechanisms while also pointing to the imitations.

= Possible studies ideas
<possible-studies-ideas>
- Ideas put figure about increased number of papers(qualitative experinec + aperiodic + complexity)

#bibliography("complexity.bib")

