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


type JuliettaWindow <: Gtk.GtkWindowI
  handle::Ptr{Gtk.GObjectI}
  work::Workspace
  term::Terminal
  hist::History
  spinner::Spinner
end

julietta = nothing

function JuliettaWindow()
  if nprocs() == 1
    addprocs(1)
  end
  remotecall_fetch(2, Base.load_juliarc)

  hist = History()      
  work = Workspace()
  G_.border_width(work,5)
  G_.border_width(hist,5)
  vboxL = BoxLayout(:v)
  push!(vboxL,work)
  push!(vboxL,hist)
  setproperty!(vboxL,:expand,work,true)
  setproperty!(vboxL,:expand,hist,true)
  G_.size_request(vboxL, 350,-1)
  
  term = Terminal()
  G_.border_width(term,5)

  hbox = BoxLayout(:h)
  push!(hbox,vboxL)
  push!(hbox,term)
  setproperty!(hbox,:expand,term,true)
  
  btnEdit = ToolButton("gtk-edit")
  btnHelp = ToolButton("gtk-help")
  btnPkg = ToolButton("gtk-preferences") 
  spItem = ToolItem()
  spinner = Spinner()
  G_.size_request(spinner, 23,-1)
  push!(spItem,spinner) 
  
  toolbar = Toolbar()
  push!(toolbar,btnEdit,btnPkg,btnHelp,SeparatorToolItem(),spItem)
  #G_.style(toolbar,ToolbarStyle.BOTH)  
  
  
  vbox = BoxLayout(:v)
  push!(vbox,toolbar)
  push!(vbox,hbox)
  setproperty!(vbox,:expand,hbox,true)
  
  
  win = GtkWindow("Julietta",1024,768)
  push!(win,vbox)
  showall(win)
  
  signal_connect(win,"destroy") do object, args...
   exit()
  end
  
  signal_connect(btnEdit, "clicked") do widget
    SourceViewer()
  end

  signal_connect(btnHelp, "clicked") do widget
    ModuleBrowser()
  end

  signal_connect(btnPkg, "clicked") do widget
    PkgViewer()
  end  
  
  global julietta = JuliettaWindow(win.handle,work,term,hist,spinner)
  Gtk.gc_move_ref(julietta, win)
end

#end #module