# Issue with module in eval in workspace
#module Julietta

import Base.push!

#export PkgViewer, VariableViewer, ModuleBrowser, SourceViewer, JuliettaWindow

using Gtk
using Gtk.ShortNames


include("pkg.jl")
include("history.jl")
include("workspace.jl")
include("modulebrowser.jl")
include("editor.jl")
include("terminal.jl")
include("filebrowser.jl")

type JuliettaWindow <: Gtk.GtkWindowI
  handle::Ptr{Gtk.GObjectI}
  work::Workspace
  term::Terminal
  hist::History
  browser::FileBrowser
  spinner::Spinner
  editor
end

# This is the global Julietta instance
julietta = nothing

function JuliettaWindow()
  if nprocs() == 1
    addprocs(1)
  end
  remotecall_fetch(2, Base.load_juliarc)

  hist = History()      
  work = Workspace()
  browser = FileBrowser()
  #G_.border_width(work,5)
  #G_.border_width(hist,5)
  panedL1 = Paned(:v)
  panedL1[1] = work
  panedL1[2] = hist
  G_.position(panedL1,150)
  panedL2 = Paned(:v)
  panedL2[1] = browser
  panedL2[2] = panedL1
  G_.position(panedL2,250)  
  
  #G_.size_request(panedL2, 350,-1)
  
  term = Terminal()
  #G_.border_width(term,5)
  #setproperty!(term,:margin, 5)

  hbox = Paned(:h)
  hbox[1] = panedL2
  hbox[2] = term
  G_.position(hbox,350)
  #setproperty!(hbox,"left-margin", 5)
  #setproperty!(hbox,"upper-margin", 5)
  #setproperty!(hbox,"lower-margin", 5)
  
  btnEdit = ToolButton("gtk-edit")
  btnHelp = ToolButton("gtk-help")
  btnPkg = ToolButton("gtk-preferences") 
  spItem = ToolItem()
  spinner = Spinner()
  G_.size_request(spinner, 23,-1)
  push!(spItem,spinner)
  spSep = SeparatorToolItem()

  setproperty!(spSep,:draw,false)
  setproperty!(spItem,:margin, 5)
  
  toolbar = Toolbar()
  push!(toolbar,btnEdit,btnPkg,btnHelp)
  push!(toolbar,spSep,spItem)
  G_.expand(spSep,true)
  G_.style(toolbar,ToolbarStyle.ICONS) #BOTH  
  
  
  vbox = BoxLayout(:v)
  push!(vbox,toolbar)
  push!(vbox,hbox)
  setproperty!(vbox,:expand,hbox,true)
  
  
  win = GtkWindow("Julietta",1024,768)
  push!(win,vbox)
  showall(win)
  
  global julietta = JuliettaWindow(win.handle,work,term,hist,browser,spinner,nothing)  
  
  signal_connect(win,"destroy") do object, args...
   exit()
  end
  
  signal_connect(btnEdit, "clicked") do widget
    if julietta != nothing
      if julietta.editor == nothing
        julietta.editor = SourceViewer()
        
        signal_connect(julietta.editor,"delete-event") do args...
          destroy(julietta.editor)
          julietta.editor = nothing
        end  
        
      end

      present(julietta.editor)
    end
  end

  signal_connect(btnHelp, "clicked") do widget
    ModuleBrowser()
  end

  signal_connect(btnPkg, "clicked") do widget
    PkgViewer()
  end  
  

  Gtk.gc_move_ref(julietta, win)
end

#end #module