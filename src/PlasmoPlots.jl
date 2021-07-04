module PlasmoPlots

using Statistics
using Plasmo
using Plots
using NetworkLayout
using GeometryBasics:Point2f0,Point
using Colors
using LightGraphs

export plot, spy, layout_plot, matrix_plot

include("layout_plot.jl")

include("matrix_plot.jl")

end
