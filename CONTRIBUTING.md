# Instructor guide

This file contains course maintenance and publishing instructions for the instructor. `README.md` and `index.html` are intended for students and contain only information about accessing materials and completing activities.

The student catalogue is generated from `course.json`. Existing materials retain their filenames and paths to preserve references to data and images. The README and HTML page share the same catalogue.

## Adding or updating a unit

1. Copy [templates/unit.Rmd](templates/unit.Rmd) to the repository root, for example as `05_unit_name.Rmd`. Use a stable number: do not renumber units already distributed simply to change their order.
2. Fill in learning objectives, prerequisites, explanations, activities, and references. Store datasets in `data/` and images in `images/`, using descriptive names.
3. Generate HTML and PDF with R Markdown and inspect them visually. Self-contained HTML files (`self_contained: true`) are convenient for individual downloads. If an HTML file requires external assets, include them in the repository and tell students to download the ZIP.
4. Add an entry to [course.json](course.json): a unique `id`, `title`, `description`, `source`, and the available `html`/`pdf` paths. Omit a format if it is not yet available. Array order determines catalogue order; you can also add new sections.
5. From the repository root, run `node scripts/build-course.mjs`, then `node scripts/build-course.mjs --check`. This requires Node.js 20 or later, with no additional packages. The check validates listed files, IDs, and generated catalogues; it does not run R analyses.
6. Commit source files, updated outputs, required datasets, `course.json`, `README.md`, and `index.html`. The GitHub workflow checks the catalogue on every push and pull request.

Do not edit README tables or `index.html` cards directly: regeneration overwrites them. Edit [scripts/build-course.mjs](scripts/build-course.mjs) to change shared student instructions or the layout. Keep instructor instructions in this guide rather than adding them to student pages.

## Rendering with R

Open `didactic_materials.Rproj`, install the packages required by the document, and work from the project root. For a new unit based on the template:

```r
rmarkdown::render("05_unit_name.Rmd", output_format = "all")
```

PDF output also requires a LaTeX distribution, such as TinyTeX. Some current source files declare only HTML even though a PDF exists: to update that PDF, explicitly configure `pdf_document` and check content compatibility. Do not assume that a PDF is up to date after rendering only the HTML.

For the lab in `extra/`, dataset paths are relative to the repository root:

```r
rmarkdown::render("extra/lesson_2026_09_30.Rmd", output_format = "all",
                  knit_root_dir = normalizePath("."))
```

Before publishing, open the outputs and check plots, images, links, formulas, and consistency between HTML and PDF. Check links to example reports within documents too: the catalogue check does not inspect links inside lessons.

## Publishing on GitHub

The configured repository is `livioivil/DataViz`, on branch `main`. README download links become available after the files are first pushed to that branch. If the repository or branch changes, update the corresponding fields in `course.json` and regenerate the catalogue.

To let students read lessons directly online, enable GitHub Pages in the repository settings, using branch `main` and the root folder `/`. `index.html` will be the home page. The expected address for this configuration is `https://livioivil.github.io/DataViz/`; verify the address and publication status in the settings before sharing it with students. Pages must be enabled on GitHub: local files alone do not activate the site.

The site serves HTML and PDF files already rendered locally and does not require R on the server. The `.nojekyll` file skips Jekyll processing. The included validation workflow does not publish a site. For configuration details, see the [official GitHub Pages documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

## Course conventions

- Keep assignments, feedback, and worked examples in separate catalogue sections. All files in a public repository remain accessible: to release a solution later, add it only when you intend to distribute it.
- For each activity, specify the question, datasets, expected deliverable, and review criteria. Add the schedule and assessment criteria once defined.
- For each new dataset, document its origin, unit of observation, variables, and whether it is simulated or real, if known.
- Do not upload individual submissions or students' personal data to the course repository.
- Use descriptive commits. For completed course editions, tags and releases can help students retrieve the version they used.
- Choose a licence for materials you own and preserve attribution for third-party resources. No licence has been assigned automatically to the existing materials.
