# Exocco

 **Exocco** is an Elixir port of [Docco](http://jashkenas.github.com/docco/). 
 The original quick-and-dirty, hundred-line-long, literate-programming-style
 documentation generator. It produces HTML that displays your comments
 alongside your code. Comments are passed through
 [Markdown](http://daringfireball.net/projects/markdown/syntax) while code is
 passed through [Pygments](http://pygments.org/) for syntax highlighting.
 
# Usage
 `exocco` is a self contained elixir script. You can run it from the command line as follow:
 
     exocco lib/foo.ex
 
 ...or

     exocco lib/

 This will generate linked HTML documentation for the named source files (or first level files
 in a directory), saving it into a folder.
 
 To get more information about the available options, run:

     exocco --help

# Building
 
 To build Exocco:

  Install [Elixir](http://elixir-lang.org/)...

  grab the latest Exocco source...
 
     git clone https://github.com/bitchef/exocco.git

 and build the project:
 
     cd exocco
     mix deps.get
     mix escript.build

 **Exocco** is released under the **MIT License**.
