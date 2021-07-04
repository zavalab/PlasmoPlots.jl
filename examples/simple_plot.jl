using Plasmo
using Plots, PlasmoPlots
gr()

graph = OptiGraph()

@optinode(graph,n1)
@variable(n1, y >= 2)
@variable(n1,x >= 0)
@constraint(n1,x + y >= 3)
@objective(n1, Min, y)

@optinode(graph,n2)
@variable(n2, y)
@variable(n2,x >= 0)
@constraint(n2,x + y >= 3)
@objective(n2, Min, y)

@optinode(graph,n3)
@variable(n3, y )
@variable(n3,x >= 0)
@constraint(n3,x + y >= 3)
@objective(n3, Min, y)

@linkconstraint(graph, n1[:x] + n2[:x] + n3[:x] == 3)

plt_graph1 = layout_plot(graph,node_labels = true,markersize = 60,labelsize = 30,
linewidth = 4,layout_options = Dict(:tol => 0.01,:iterations => 2));

plt_matrix1 = matrix_plot(graph,node_labels = true,markersize = 30);
