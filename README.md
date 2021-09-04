# Do Minimum Wages Affect Rents?

In this project we explore the short-run effect of minimum wage policies on the
housing market across metropolitan areas.

## How to use

- Data is stored in Brown's Google Drive [here](https://drive.google.com/drive/u/1/folders/1PRXhH-6Ny_jNGUcS7vjb0A-QzfNEt816).

   - Make a local copy of the Google Drive folder.
   - Create a juncture link to the datastore in the root of the repo. In windows, run `mklink /J "<Root of repo>/drive/" "<Local Google Drive folder>"` from the command line.


## Writing the paper

Tex files with code for the paper and slides live in `./paper_slides/`.
Note that none of these folders is compiled using `make` nor `SCons`.

### Guidelines

  - To enhance GitHub visualization and debugging, we limit lines in Tex files to 
  a maximum of (approximately) 80 characters.
  As a general rule, we break lines when starting a new sentence.
  When appropriate, we also break lines following the structure of a sentence. 
  For example,

  ```Tex
  $$ y_i = a + b x_i + e_i$$
  where
  $a$ and $b$ are parameters,
  $y_i$ is the outcome,
  $x_i$ is the independent variable, and
  $e_i$ is an error term.
  ```
  - An exception to the the line-wrapping rule is allowed when adding figures or 
  tables with long filenames.

  - Footnotes:
    
    - Always write a footnote after a punctuation mark (`.`, `,`, or `;`).
    - Write a `%` sign at the end of a sentence (to prevent extra spacing) and write the footnote in a new line.
    - E.g., 
    ```Tex
    some stuff,%
    \footnote{I am a footnote!}
    and some other stuff.
    ```
  - We write notes, comments or suggestions after a `%` sign. Note that any number of spaces and/or commented lines are allowed within paragraphs. E.g., the below is compiled as part of the same paragraph:
    ```Tex
    This is a bold claim about the identification of this paper.
    % SH: I'm not sure if identification is so clear, maybe we want to
    %   search for supporting papers.
    An the paragraph continues with some other stuff here.
    ```

  - Use [oxford comma](https://i.kym-cdn.com/photos/images/original/000/946/427/5a4.jpg).

  - To cite a specific section, appendix, or figure use caps. E.g.,  `Section \ref{sec:sec_name}` or `Appendix Table \ref{tab:tab_name}`.

  - To cite math or an equation do `\eqref{eq:eq_name}` or `equation \eqref{eq:eq_name}` when appropriate.
      - Equations are part of a paragraph


### Editors 

- For using `VS code`:

  - Install `LaTeX Workshop` extension.
  - Set editor rulers at 80 and 120 characters as in [here](https://stackoverflow.com/a/29972073/15344214).

- For using `TexStudio`:

  - Set TexStudio to break lines for you by going to `Option` > `Configure TexStudio` > `Advanced Editor`. Set `Line Wrapping` to `Hard Line Wrap after Max. Characters`, and `Maximal Characters` to `90`.

