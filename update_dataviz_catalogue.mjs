import fs from "node:fs";
import path from "node:path";

const repo = process.argv[2];
if (!repo) throw new Error("Usage: node update_dataviz_catalogue.mjs <repository-path>");

const cataloguePath = path.join(repo, "course.json");
const catalogue = JSON.parse(fs.readFileSync(cataloguePath, "utf8"));
const units = catalogue.sections.find(section => section.title === "Course units");
if (!units) throw new Error("Course units section not found.");

const upsert = (items, item) => {
  const index = items.findIndex(existing => existing.id === item.id);
  if (index >= 0) items[index] = item;
  else items.push(item);
};

[
  {
    id: "08",
    title: "Activity 4 · Confounding and categorical variables",
    description: "Design and analyse a study of shoe size, reading scores and an age-related confounder.",
    source: "08_student_activity4_confounders.Rmd",
    html: "08_student_activity4_confounders.html"
  },
  {
    id: "09",
    title: "Homework · Penguins: distributions, groups and hidden associations",
    description: "Use species and sex to examine distributions and associations in penguin measurements.",
    source: "09_homework_penguins_task.Rmd",
    html: "09_homework_penguins_task.html"
  },
  {
    id: "10",
    title: "LOESS: nonparametric trends and span selection",
    description: "Explore local regression, span selection and the reliability of smoothed trends.",
    source: "10_loess_nonparametric_trends.Rmd",
    html: "10_loess_nonparametric_trends.html"
  },
  {
    id: "11",
    title: "From Distances to Maps: Multidimensional Scaling",
    description: "Define and compare distances, then use classical MDS and spectral decomposition to map non-textual multivariate data.",
    source: "11_mds_distances.Rmd",
    html: "11_mds_distances.html"
  },
  {
    id: "12",
    title: "Activity 5 · Mapping mixed customer profiles",
    description: "Design a Gower distance for numeric, ordinal, nominal and binary customer-profile variables, then map it with MDS.",
    source: "12_student_activity5_mixed_distances.Rmd",
    html: "12_student_activity5_mixed_distances.html"
  }
].forEach(item => upsert(units.items, item));

units.items.sort((a, b) => a.id.localeCompare(b.id, undefined, { numeric: true }));

// The former 04-F feedback entry has no source or rendered file in this
// repository. Do not publish a catalogue link that cannot resolve.
units.items = units.items.filter(item => item.id !== "04-F");

// Every course unit has a PDF alongside its Rmd source. Add its link only when
// the generated file is present, so the catalogue never advertises a broken link.
for (const item of units.items) {
  const pdf = item.source.replace(/\.rmd$/i, ".pdf");
  if (fs.existsSync(path.join(repo, pdf))) item.pdf = pdf;
}

let additional = catalogue.sections.find(section => section.title === "Additional materials");
if (!additional) {
  additional = { title: "Additional materials", items: [] };
  catalogue.sections.push(additional);
}

[
  {
    id: "EX-00",
    title: "Graphics showcase",
    description: "A gallery of base-R graphical options and plotting patterns.",
    source: "00_graphics_showcase.Rmd",
    html: "00_graphics_showcase.html"
  },
  {
    id: "EX-02",
    title: "Shiny group-project briefs",
    description: "Six project briefs for interactive visualisation apps, including document maps and word networks.",
    source: "shiny_group_project_briefs.Rmd",
    html: "shiny_group_project_briefs.html"
  }
].forEach(item => upsert(additional.items, item));

additional.items.sort((a, b) => a.id.localeCompare(b.id, undefined, { numeric: true }));

catalogue.datasets = catalogue.datasets.filter(
  dataset => dataset.path !== "data/11_ecological_communities.csv"
);

const upsertDataset = dataset => {
  const index = catalogue.datasets.findIndex(existing => existing.path === dataset.path);
  if (index >= 0) catalogue.datasets[index] = dataset;
  else catalogue.datasets.push(dataset);
};

upsertDataset({
    path: "data/ecological_communities.csv",
    title: "Ecological communities",
    description: "Unit 11: real Dutch dune-meadow plant cover classes (20 sites × 30 species), used to compare Bray–Curtis and Hellinger–Euclidean distance." 
});

upsertDataset({
    path: "data/ecological_communities_metadata.csv",
    title: "Ecological communities metadata",
    description: "Site-level environmental context for the Dutch dune-meadow data: soil horizon, moisture, management, land use and manure level."
});

upsertDataset({
  path: "data/shoe_size_reading.csv",
  title: "Shoe size and reading",
  description: "Activity 4: simulated primary-school measurements for a confounding exercise."
});

upsertDataset({
  path: "data/penguins.csv",
  title: "Penguins",
  description: "Homework: penguin body measurements, species, island and sex."
});

upsertDataset({
  path: "data/customer_profiles.csv",
  title: "Mixed customer profiles",
  description: "Activity 5: synthetic anonymous profiles with numeric, ordinal, nominal and binary variables for Gower distance."
});

fs.writeFileSync(cataloguePath, `${JSON.stringify(catalogue, null, 2)}\n`);
